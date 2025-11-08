//
//  SpotifyUserAuthorization.swift
//  NeiroCS371L
//
//  Created by Allison Still on 10/23/25.
//

import Foundation
import UIKit
import SafariServices
import FirebaseAuth

class SpotifyUserAuthorization {
    
    //singleton
    static let shared = SpotifyUserAuthorization()
    private init() {}
    
    private let clientID = "07271e8ef7c546809d97abfe7b3143e6"
    private let redirectURI = "neiro://spotify-callback"
    private let scope = "user-read-email user-read-private playlist-modify-public playlist-modify-private"
    
    private var verifier: String?
    private var safariVC: SFSafariViewController?
    private var isSignupFlow = false
    
    private let accessTokenKey = "spotify_access_token"
    private let refreshTokenKey = "spotify_refresh_token"
    private let expirationDateKey = "spotify_token_expiration"
    private let userNameKey = "spotify_user_display_name"
    private let spotifyUserIDKey = "spotify_user_id"
    private let spotifyEmailKey = "spotify_user_email"
    private let firebasePasswordKey = "spotify_firebase_password"
    
    // is the Spotify account connected
    var isConnected: Bool {
        guard let token = UserDefaults.standard.string(forKey: accessTokenKey),
              let expiration = UserDefaults.standard.object(forKey: expirationDateKey) as? Date else {
            return false
        }
        return !token.isEmpty && Date() < expiration
    }
    
    var accessToken: String? {
        guard isConnected else {return nil}
        return UserDefaults.standard.string(forKey: accessTokenKey)
    }
    
    var userDisplayName: String? {
        UserDefaults.standard.string(forKey: userNameKey)
    }
    
    var spotifyUserID: String? {
        UserDefaults.standard.string(forKey: spotifyUserIDKey)
    }
    
    var spotifyEmail: String? {
        UserDefaults.standard.string(forKey: spotifyEmailKey)
    }
    
    //start Spotify OAuth!
    func startLogin(presentingVC: UIViewController, forSignup: Bool = false, completion: @escaping (SFSafariViewController?) -> Void) {
        
        self.isSignupFlow = forSignup
        
        //get PKCE security codes
        let verifier = SpotifyPKCE.generateCodeVerifier()
        let challenge = SpotifyPKCE.generateCodeChallenge(from: verifier)
        self.verifier = verifier
        
        //build spotify auth URL
        var components = URLComponents(string: "https://accounts.spotify.com/authorize")!
        
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scope),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "code_challenge", value: challenge)
        ]
        
        guard let spotifyAuthURL = components.url else {
            print("Couldn't generate Spotify URL.")
            completion(nil)
            return
        }
        
        //present Safari
        let safari = SFSafariViewController(url: spotifyAuthURL)
        self.safariVC = safari
        
        presentingVC.present(safari, animated: true) {
            print("Presenting Spotify login now!")
            completion(safari)
        }
    }
    
    //handle callback from Spotify
    func handleCallback(url: URL, completion: @escaping (Bool) -> Void) {
        
        // get auth code from URL
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            print("Error parsing URL. No auth code in callback URL")
            completion(false)
            return
        }
        
        //dismiss safari
        safariVC?.dismiss(animated: true)
        safariVC = nil
        
        //exchange code for access token
        exchangeCodeForToken(authCode: code, completion: completion)
    }
    
    
    //exchange auth code for access/refresh tokens
    private func exchangeCodeForToken(authCode: String, completion: @escaping (Bool) -> Void) {
        
        guard let verifier = verifier else {
            print("missing verifier")
            completion(false)
            return
        }
        
        let tokenURL = URL(string: "https://accounts.spotify.com/api/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        //build request body
        let bodyParams = ["grant_type": "authorization_code",
                          "code": authCode,
                          "redirect_uri": redirectURI,
                          "client_id": clientID,
                          "code_verifier": verifier
        ]
        
        let body = bodyParams.map{
            "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }.joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        
        //make request
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error {
                print("error exchanging code for token: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any], let accessToken = json["access_token"] as? String else {
                
                print("Invalid token response")
                completion(false)
                return
            }
            
            //store tokens
            let refreshToken = json["refresh_token"] as? String
            let expiresIn = json["expires_in"] as? Double ?? 3600
            self.storeTokens(accessToken: accessToken, refreshToken: refreshToken, expiresIn: expiresIn)
            
            print("Got access token!")
            
            
            //get user profile
            self.fetchSpotifyProfile(accessToken: accessToken, completion: completion)
        }.resume()
    }
    
    //get user profile data from Spotify API
    private func fetchSpotifyProfile(accessToken: String, completion: @escaping (Bool) -> Void) {
        
        let profileURL = URL(string: "https://api.spotify.com/v1/me")!
        var request = URLRequest(url: profileURL)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Cannot fetch profile: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = data, let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
                print("Bad profile response")
                completion(false)
                return
            }
            
            //parse profile data
            let displayName = json["display_name"] as? String ?? "Spotify User"
            let spotifyID = json["id"] as? String ?? UUID().uuidString
            let email = json["email"] as? String
            
            //store user info
            UserDefaults.standard.set(displayName, forKey: self.userNameKey)
            UserDefaults.standard.set(spotifyID, forKey: self.spotifyUserIDKey)
            if let email = email {
                UserDefaults.standard.set(email, forKey: self.spotifyEmailKey)
            }
            
            print("Spotify User: \(displayName)")
            
            // if we are signing up, create a firebase account as well
            if self.isSignupFlow {
                self.createFirebaseAccount(spotifyID: spotifyID, email: email, displayName: displayName, completion: completion)
            } else {
                completion(true)
            }
            
        }.resume()
    }
    
    //create firebase account (or sign in)
    private func createFirebaseAccount(spotifyID: String, email: String?, displayName: String, completion: @escaping (Bool) -> Void) {
        
        if let storedPassword = UserDefaults.standard.string(forKey: firebasePasswordKey), let email = email {
            
            //try signing in
            Auth.auth().signIn(withEmail: email, password: storedPassword) {
                result, error in
                if error == nil {
                    print("Signed in to existing Firebase acct!")
                    completion(true)
                } else {
                    //create new firebase account - password changed?
                    self.createNewFirebaseAccount(email: email, spotifyID: spotifyID, displayName: displayName, completion: completion)
                }
            }
            return
        }
        
        // create new account
        if let email = email {
            createNewFirebaseAccount(email: email, spotifyID: spotifyID, displayName: displayName, completion: completion)
        } else {
            
            //no email from Spotify - anonymous/general sign in
            print("No email from spotify, use anonymous sign in")
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("Anonymous sign in failed: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Successfully signed in anonymously on Firebase")
                    completion(true)
                }
            }
        }
    }
    
    //helper to create new firebase account
    private func createNewFirebaseAccount(email: String, spotifyID: String, displayName: String, completion: @escaping (Bool) -> Void) {
        
        let password = generateSecurePassword()
        
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            
            if let error = error as NSError? {
                
                //email already in use
                if error.code == AuthErrorCode.emailAlreadyInUse.rawValue{
                    print("Account/email in use, signing in as this user!")
                    
                    if let storedPassword = UserDefaults.standard.string(forKey: self.firebasePasswordKey) {
                        
                        Auth.auth().signIn(withEmail: email, password: storedPassword) { _, signInError in
                            
                            if signInError == nil {
                                print("Signed into existing account with stored password!")
                                completion(true)
                            } else {
                                print("sign in failed with stored password: \(signInError?.localizedDescription ?? "unknown")")
                                DispatchQueue.main.async {
                                    self.notifyPasswordIssue(email: email)
                                }
                                completion(false)
                            }
                        }
                    } else {
                        print("No stored password found.")
                        DispatchQueue.main.async {
                            self.notifyPasswordIssue(email: email)
                        }
                        completion(false)
                    }
                    
                } else {
                    print("Firebase account creation didn't work: \(error.localizedDescription)")
                    completion(false)
                }
            } else {
                //success! - store password
                UserDefaults.standard.set(password, forKey: self.firebasePasswordKey)
                print("Created Firebase account for : \(email)")
                completion(true)
            }
        }
    }
    
    private func notifyPasswordIssue(email: String) {
        guard let topVC = UIApplication.shared.windows.first?.rootViewController else { return }
        
        let alert = UIAlertController(title: "Account Already Exists", message: "An account with this email already exists. Please use original password.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            Auth.auth().sendPasswordReset(withEmail: email) { error in
                if let error = error {
                    print("Pasword reset failed: \(error.localizedDescription)")
                } else {
                    print("Password reset email sent!")
                }
            }
        })
        topVC.present(alert, animated: true)
    }
    
    //disconnect and log out/clear data
    func disconnect() {
        UserDefaults.standard.removeObject(forKey: accessTokenKey)
        UserDefaults.standard.removeObject(forKey: refreshTokenKey)
        UserDefaults.standard.removeObject(forKey: expirationDateKey)
        UserDefaults.standard.removeObject(forKey: userNameKey)
        UserDefaults.standard.removeObject(forKey: spotifyUserIDKey)
        UserDefaults.standard.removeObject(forKey: spotifyEmailKey)
        UserDefaults.standard.removeObject(forKey: firebasePasswordKey)
        
        print("Disconnected and data cleared from Spotify!")
    }
    
    
    //helper function to store tokens
    private func storeTokens(accessToken: String, refreshToken: String?, expiresIn: Double) {
        
        let expiration = Date().addingTimeInterval(expiresIn)
        UserDefaults.standard.set(accessToken, forKey: accessTokenKey)
        UserDefaults.standard.set(refreshToken, forKey: refreshTokenKey)
        UserDefaults.standard.set(expiration, forKey: expirationDateKey)
        
    }
    
    //helper to generate secure password for new firebase user
    private func generateSecurePassword() -> String {
        let length = 20
        let chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()"
        return String((0..<length).compactMap {_ in chars.randomElement() })
    }
}
