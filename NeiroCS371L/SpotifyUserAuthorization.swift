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
    private let scope = "user-read-email user-read-private playlist-modify-public user-read-email playlist-modify-private user-modify-playback-state user-read-playback-state"
    
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
    private let lastSpotifyUserIDKey = "spotify_last_user_id"
    
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
            
            //get user info from firebase
            let firebaseUser = Auth.auth().currentUser
            let firebaseEmail = firebaseUser?.email
            
            //logged-in email and new spotify email don't match
            if let appEmail = firebaseEmail, let spotifyEmail = email, appEmail.lowercased() != spotifyEmail.lowercased() {
                DispatchQueue.main.async {
                    self.presentSpotifyAccountAlert(neiroEmail: appEmail, spotifyEmail: spotifyEmail, displayName: displayName, spotifyID: spotifyID, email: email, completion: completion)
                }
                return
            }
            
            //store user info
            UserDefaults.standard.set(displayName, forKey: self.userNameKey)
            UserDefaults.standard.set(spotifyID, forKey: self.spotifyUserIDKey)
            UserDefaults.standard.set(spotifyID, forKey: self.lastSpotifyUserIDKey)
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
        print("Attempting to create Firebase account for \(email)")
        
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
                    DispatchQueue.main.async {
                        self.showGeneralAuthError(error: error)
                    }
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
    
    //alert to ask user what to do if spotify account wasn't the same as the logged in neiro account
    private func presentSpotifyAccountAlert(neiroEmail: String, spotifyEmail: String, displayName: String, spotifyID: String, email: String?, completion: @escaping (Bool) -> Void) {
        
        //use new account if alert isn't working
        guard let topVC = UIApplication.shared.windows.first?.rootViewController else {
            UserDefaults.standard.set(displayName, forKey: self.userNameKey)
            UserDefaults.standard.set(spotifyID, forKey: self.spotifyUserIDKey)
            UserDefaults.standard.set(spotifyID, forKey: self.spotifyUserIDKey)
            
            if let email = email {
                UserDefaults.standard.set(email, forKey: self.spotifyEmailKey)
            }
            
            if self.isSignupFlow {
                self.createFirebaseAccount(spotifyID: spotifyID, email: email, displayName: displayName, completion: completion)
            } else {
                completion(true)
            }
            return
        }
        
        //message alerting user of the error
        let message = "You were previously logged into Neiro as \(neiroEmail), but you connected to spotify as \(spotifyEmail). Would you like to link this Spotify account to this Neiro user?"
        
        let alert = UIAlertController(title: "Link Spotify Account?", message: message, preferredStyle: .alert)
        
        //cancel, we don't want to connect to spotify now
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
            self.disconnect()
            completion(false)
        })
        
        //continue, continue to Spotify account, rewrite old data
        alert.addAction(UIAlertAction(title: "Continue", style: .destructive) { _ in
            
            //save all new info to userdefaults
            UserDefaults.standard.set(displayName, forKey: self.userNameKey)
            UserDefaults.standard.set(spotifyID, forKey: self.spotifyUserIDKey)
            UserDefaults.standard.set(spotifyID, forKey: self.lastSpotifyUserIDKey)

            if let email = email {
                UserDefaults.standard.set(email, forKey: self.spotifyEmailKey)
            }
            
            //create new firebase account if we are signing up (shouldn't be a main concern)
            if self.isSignupFlow {
                self.createFirebaseAccount(spotifyID: spotifyID, email: email, displayName: displayName, completion: completion)
            } else {
                completion(true)
            }
        })
        topVC.present(alert, animated: true)
    }
    
    private func notifyPasswordIssue(email: String) {
        guard let topVC = UIApplication.shared.windows.first?.rootViewController else { return }
        
        let alert = UIAlertController(title: "Account Already Exists", message: "An account with this email already exists. Please log in to Neiro with this email, try a different account, or reset your password.", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Send Password Reset Email", style: .default) { _ in
            self.sendPasswordResetEmail(email: email, presentingVC: topVC)
        })
        
        alert.addAction(UIAlertAction(title: "Use Different Account", style: .default) { _ in
            DispatchQueue.main.async {
                self.showDifferentAccountInfo(presentingVC: topVC)
            }
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style:.cancel))

        topVC.present(alert, animated: true)
    }
    
    private func sendPasswordResetEmail(email: String, presentingVC: UIViewController) {
        let loadingAlert = UIAlertController(title: "Sending email...", message: "Please wait for just a moment", preferredStyle: .alert)
        presentingVC.present(loadingAlert, animated: true)
        
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true)
                if let error = error {
                    print("Password reset failed! \(error.localizedDescription)")
                    let errorAlert = UIAlertController(title: "Password Reset Failed", message: "We couldn't send the password reset email. Please try again later.", preferredStyle: .alert)
                    errorAlert.addAction(UIAlertAction(title: "Retry", style: .default) { _ in
                        self.sendPasswordResetEmail(email: email, presentingVC: presentingVC)
                    })
                    errorAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                    presentingVC.present(errorAlert, animated: true)
                } else {
                    print("Password reset email sent!")
                    let successAlert = UIAlertController(title: "Please Check your Email", message: "We have sent a password reset email to your inbox.", preferredStyle: .alert)
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    presentingVC.present(successAlert, animated: true)
                    
                }
            }
        }
    }
    
    private func showDifferentAccountInfo(presentingVC: UIViewController) {
        let infoAlert = UIAlertController(title: "Use a Different Spotify Account", message: "Please attempt to log in to a different spotify account.", preferredStyle: .alert)
        infoAlert.addAction(UIAlertAction(title: "OK", style: .default))
        presentingVC.present(infoAlert, animated: true)
    }
    
    
    private func showGeneralAuthError(error: Error) {
        guard let topVC = UIApplication.shared.windows.first?.rootViewController else { return }
        let alert = UIAlertController(title: "Authentication Error", message: "We encountered an issue signing you in: \(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
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
