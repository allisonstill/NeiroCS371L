//
//  DescribeLLMModels.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/16/25.
//

import Foundation

// response from Gemini LLM
struct DescribeLLMResponse: Codable {
    let mode: String // are we creating a new playlist or updating
    let emoji: String
    let playlistLength: String
    let moodChange: String? //for if we want to update playlist mood
    let reason: String?
}

// Errors that might occur while attempting to use Gemini LLM
enum DescribeLLMError: Error {
    case emptyResponse
    case invalidJSON
    case apiError(String)
}


// fetch API key
enum GeminiAPIKey {
    static var apiKey: String {
        // get API key from Info.plist
        guard let key = Bundle.main.object(forInfoDictionaryKey: "GEMINI_API_KEY") as? String, !key.isEmpty else {
            fatalError("We are not able to access GEMINI_API_KEY from Info.plist.")
        }
        return key
    }
}

// Handle structure of response from Gemini -> text within Part is the generated text
private struct GeminiResponse: Decodable {
    struct Candidate: Decodable { // array of candidate completions
        struct Content: Decodable { // 'content' holds text
            struct Part: Decodable { // section of text
                let text: String? // generated text
            }
            let parts: [Part]
        }
        let content: Content
    }
    let candidates: [Candidate]?
    let promptFeedback: PromptFeedback?
    
    // only if Gemini blocks request
    struct PromptFeedback: Decodable {
        let blockReason: String?
    }
}

// Build prompt to LLM, send request, parse output, and convert to DescribeLLMResponse
final class DescribeLLMModels {
    static let shared = DescribeLLMModels()
    private init() {}
    
    // send description to LLM (Gemini) and get DescribeLLMResponse
    func getDescription(text: String, currentEmoji: String?, currentLength: String?) async throws -> DescribeLLMResponse {
        
        let apiKey = GeminiAPIKey.apiKey
        
        // API endpoint for 2.5
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent") else {
            throw DescribeLLMError.apiError("Gemini URL is invalid.")
        }
        
        // Prompt that goes into Gemini - we might want to edit this in the future for added emojis
        let modelInput = """
        You are helping an iOS playlist generation app, called Neiro. Users may either create a playlist or modify an existing playlist. Users will use regular, ordinary English to describe the type of playlist they want, and you will convert this user-provided description into exactly one emoji and playlist length. The possible (and only) emojis are as follows: ["😀","😎","🥲","😭",
            "🤪","🤩","😴","😐", "😌","🙂","🙃","😕", "🔥","❤️","⚡️"]. The only possible playlist lengths are as follows: "short" - 4 songs is about 10 mins long, "medium" - 10 songs is abt 30 mins long, "long" - 20 songs is abt 60 minutes long, "extraLong" - 40 songs is about 120 minutes long.

        Constraints: You must only pick one emoji based on the user's mood. You must only select one playlistLength based on the user's description. Return exactly 1 JSON object in the format as follows:

        JSON: {
            "mode": "create" | "update",
            "emoji": "...",
            "playlistLength": "...",
            "moodChange": "...",
            "reason: "..."
        }
"""
        
        // build user request based on emoji + length to get full prompt
        var userRequest = "User request: \(text)"
        if let currentEmoji {
            userRequest += "\nCurrent Playlist Emoji: \(currentEmoji)"
        }
        if let currentLength {
            userRequest += "\nCurrent Playlist Length: \(currentLength)"
        }
        
        let fullUserPrompt = modelInput + "\n\n" + userRequest
        
        //build json body
        let jsonBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": fullUserPrompt
                        ]
                    ]
                ]
            ]
        ]
        
        // convert dictionary to JSON
        let jsonData = try JSONSerialization.data(withJSONObject: jsonBody)
        
        // build and post request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //according to docs, need apiKey here, part of request
        request.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        // throw error if we get an unexpected status code
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode){
            let text = String(data: data, encoding: .utf8) ?? "No data"
            print("Gemini HTTP error \(http.statusCode): \(text)")
            throw DescribeLLMError.apiError("HTTP Status Code: \(http.statusCode)")
        }
        
        let gemini = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        // error handle gemini blocking the request
        if let blockReason = gemini.promptFeedback?.blockReason {
            throw DescribeLLMError.apiError("Request blocked: \(blockReason)")
        }
        
        // get JSON text from 1st candidate
        guard let textResponse = gemini.candidates?.first?.content.parts.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw DescribeLLMError.emptyResponse
        }
        
        // clean the response so that it removes unwanted JSON formatting
        let cleanResponse = textResponse.replacingOccurrences(of: "```json", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let newData = cleanResponse.data(using: .utf8) else {
            throw DescribeLLMError.invalidJSON
        }
        
        // decode into DescribeLLMResponse
        return try JSONDecoder().decode(DescribeLLMResponse.self, from: newData)
    }
}

extension DescribeLLMError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Gemini returned an empty or missing response"
        case .invalidJSON:
            return "Gemini returned invalid JSON"
        case .apiError(let message):
            return "Gemini returned an error: \(message)"
        }
    }
}
