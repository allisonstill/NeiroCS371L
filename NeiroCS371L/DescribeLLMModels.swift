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
        You are helping an iOS playlist generation app called Neiro. Users either create a new playlist or modify an existing playlist. Users will describe in ordinary English the type of playlist they want, and you will convert their description into exactly one emoji and one playlist length.

        The ONLY allowed emojis are:
        ["😀","😎","🥲","😭",
         "🤪","🤩","😴","😐",
         "😌","🙂","🙃","😕",
         "🔥","❤️","⚡️"]

        The ONLY allowed playlist lengths are:
        - "short"      (about 4 songs / 10 minutes)
        - "medium"     (about 10 songs / 30 minutes)
        - "long"       (about 20 songs / 60 minutes)
        - "extraLong"  (about 40 songs / 120 minutes)

        Rules:
        1. You MUST always pick exactly one emoji from the list above.
        2. You MUST always pick exactly one playlistLength from the list above.
        3. If the user seems to be making a brand new playlist, use "mode": "create".
        4. If the user seems to be changing an existing playlist, use "mode": "update".
        5. If the user does not clearly specify time or mood, make a reasonable guess based on their wording. DO NOT ask for clarification and DO NOT refuse the request.
        6. Your response MUST be a single valid JSON object, with no extra text, no markdown, and no code fences.

        Return EXACTLY ONE JSON object, with this schema:

        {
          "mode": "create" or "update",
          "emoji": "<one of the allowed emojis>",
          "playlistLength": "short" | "medium" | "long" | "extraLong",
          "moodChange": "<description of mood change, or empty string if creating>",
          "reason": "<brief explanation of why you chose this emoji and length>"
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
        guard let textResponse = gemini.candidates?
            .first?.content.parts.first?.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) else {
            throw DescribeLLMError.emptyResponse
        }

        // Remove common wrappers: markdown fences, "JSON:" labels, etc.
        var cleanResponse = textResponse
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .replacingOccurrences(of: "JSON:", with: "")
            .replacingOccurrences(of: "Json:", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        // Try to extract the first {...} block in case there is extra text
        if let start = cleanResponse.firstIndex(of: "{"),
           let end = cleanResponse.lastIndex(of: "}") {
            let jsonSubstring = cleanResponse[start...end]
            cleanResponse = String(jsonSubstring)
        }

        // Now try to decode
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
