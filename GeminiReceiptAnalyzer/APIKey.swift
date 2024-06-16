//
//  APIKey.swift
//  GeminiReceiptAnalyzer
//
//  Created by Ish Takkar on 6/16/24.
//

import Foundation

enum APIKey {
    /// Fetch the API key from `GenerativeAI-Info.plist`
    
    static var `default`: String {
        guard let filePath = Bundle.main.path(forResource: "GenerativeAI-Info", ofType: "plist")
        else {
            fatalError("Couldn't find file 'GenerativeAI-Info.plist' containing the API Key.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        guard let value = plist?.object(forKey: "API_KEY") as? String else {
            fatalError("Couldn't find key 'API_KEY' in 'GenerativeAI-Info.plist'.")
        }
        if value.starts(with: "_") || value.isEmpty {
            fatalError("API_KEY not valid!")
        }
        return value
    }
}
