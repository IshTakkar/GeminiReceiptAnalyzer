import SwiftUI
import PhotosUI
import AVFoundation
import GoogleGenerativeAI

struct ContentView: View {
    @State private var avatarItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var userInput: String = ""
    @State private var outputText: String = ""
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var cameraError: CameraError?

    var body: some View {
        ZStack {
            BlurView(style: .systemMaterial)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                if let image = avatarImage {
                    TextField("Enter your question here...", text: $userInput)
                        .padding()
                        .frame(height: 50)
                        .background(BlurView(style: .systemMaterial))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        .foregroundColor(.primary)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 300, height: 300)
                        .shadow(radius: 10)
                        .padding()
                    
                    HStack {
                        Button("Choose another receipt") {
                            showPhotoPicker = true
                        }
                        .font(.headline)
                        .padding(.vertical, 10)
                        .background(BlurView(style: .systemMaterial))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                        
                        Button("Take a photo") {
                            checkCameraAuthorization()
                        }
                        .font(.headline)
                        .padding(.vertical, 10)
                        .background(BlurView(style: .systemMaterial))
                        .cornerRadius(10)
                        .padding(.horizontal, 20)
                    }
                    
                    Button(action: {
                        let model = GenerativeModel(name: "gemini-1.5-pro", apiKey: APIKey.default)
                        let inputPrompt = "You are an expert in understanding invoices. We will upload an image as an invoice and you will have to answer any questions based on the uploaded invoice image."
                        let combinedPrompt = "\(inputPrompt) Question: \(userInput)"
                        
                        Task {
                            do {
                                let response = try await model.generateContent(combinedPrompt, image)
                                if let text = response.text {
                                    outputText = text
                                }
                            } catch {
                                print("Error generating content: \(error)")
                            }
                        }
                    }) {
                        Text("Submit")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(buttonColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                    .disabled(userInput.isEmpty || avatarImage == nil)
                    
                    if !outputText.isEmpty {
                        Text(outputText)
                            .padding()
                            .background(BlurView(style: .systemMaterial))
                            .cornerRadius(10)
                            .padding(.horizontal, 20)
                    }
                    
                } else {
                    PhotosPicker(
                        "Select Image",
                        selection: $avatarItem,
                        matching: .images
                    )
                    .font(.headline)
                    .padding(.vertical, 10)
                    .background(BlurView(style: .systemMaterial))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                    
                    Button("Take a photo") {
                        checkCameraAuthorization()
                    }
                    .font(.headline)
                    .padding(.vertical, 10)
                    .background(BlurView(style: .systemMaterial))
                    .cornerRadius(10)
                    .padding(.horizontal, 20)
                }
            }
            .onChange(of: avatarItem) {
                Task {
                    if let data = try? await avatarItem?.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        avatarImage = uiImage
                    } else {
                        print("Failed to load image")
                    }
                }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotosPicker("Select Image", selection: $avatarItem, matching: .images)
            }
            .sheet(isPresented: $showCamera) {
                CameraView(isPresented: $showCamera, image: $avatarImage)
            }
            .alert(item: $cameraError) { error in
                Alert(title: Text("Camera Error"), message: Text(error.message), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    var buttonColor: Color {
            return (userInput.isEmpty && avatarImage == nil) ? .accentColor : .gray
        }

    private func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            showCamera = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        showCamera = true
                    } else {
                        cameraError = CameraError(message: "Camera access was denied.")
                    }
                }
            }
        case .denied, .restricted:
            cameraError = CameraError(message: "Camera access is restricted or denied.")
        @unknown default:
            cameraError = CameraError(message: "Unknown camera authorization status.")
        }
    }
}

struct CameraError: Identifiable {
    var id: String { message }
    let message: String
}

struct CameraView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    @Binding var image: UIImage?

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView

        init(_ parent: CameraView) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.isPresented = false
        }
    }
}

struct BlurView: UIViewRepresentable {
    var style: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: style))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

 #Preview {
     ContentView()
 }
