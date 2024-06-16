//
//  ContentView.swift
//  GeminiReceiptAnalyzer
//
//  Created by Ish Takkar on 6/16/24.
//

import SwiftUI
import GoogleGenerativeAI

struct ContentView: View {
    let model = GenerativeModel(name: "gemini-pro-vision", apiKey: APIKey.default)
    
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Hello, world!")
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
