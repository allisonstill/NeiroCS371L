//
//  SpotifyPKCE.swift
//  NeiroCS371L
//
//  Created by Allison Still on 10/24/25.
//

//Proof Key for Code Exchange = PKCE

import Foundation
import CommonCrypto

struct SpotifyPKCE {
    
    //create 128-char string for PKCE (secret)
    static func generateCodeVerifier() -> String {
        var buffer = [UInt8](repeating: 0, count: 96)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        return Data(buffer)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
    
    //create code challenge (SHA256 hash of code verifier ^^
    //this will be sent to Spotify for user auth
    static func generateCodeChallenge(from verifier: String) -> String {
        guard let data = verifier.data(using: .utf8) else {
            return ""
        }
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(data.count), &hash)
        }
        
        return Data(hash)
            .base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
            .trimmingCharacters(in: .whitespaces)
    }
}
