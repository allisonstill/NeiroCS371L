//
//  SignUpViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 10/16/25.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let titleBackdrop = UIView()
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let verifyPasswordField = UITextField()
    private let connectSpotifyButton = UIButton(type: .system)
    private let signUpButton = UIButton(type: .system)
    private let haveAccountLabel = UILabel()
    private let switchLoginButton = UIButton(type: .system)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        Auth.auth().addStateDidChangeListener() { (auth, user) in

            if user != nil {
                
                //TODO: need to add segue/modal transition to another screen wheen added
                
                
                self.usernameField.text = ""
                self.passwordField.text = ""
                self.verifyPasswordField.text = ""
            }
        }
        
        
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupScreen()
    }
    
    private func setupScreen() {
        
        //title backdrop
        titleBackdrop.backgroundColor = ThemeColor.Color.titleOutline.withAlphaComponent(0.2)
        titleBackdrop.layer.cornerRadius = 24
        view.addSubview(titleBackdrop)
        
        //title label: Login
        titleLabel.text = "Create an\nAccount"
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = ThemeColor.Font.titleFont()
        titleLabel.textColor = ThemeColor.Color.titleColor
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
       
        //creating textfields
        createTextField(usernameField, placeholder: "username")
        createTextField(passwordField, placeholder: "password")
        createTextField(verifyPasswordField, placeholder: "verify password")
        
        
        
        //connect spotify account button
        var spotifyConfig = UIButton.Configuration.filled()
        spotifyConfig.title = "Connect Spotify Account"
        spotifyConfig.baseBackgroundColor = ThemeColor.Color.titleOutline
        spotifyConfig.baseForegroundColor = .white
        spotifyConfig.cornerStyle = .medium
        spotifyConfig.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18)
        if let img = UIImage(named: "spotify_logo") {
            
            let targetSize = CGSize(width: 28, height: 28)
            let resizedImage = img.resize(to: targetSize)
            spotifyConfig.image = resizedImage
            spotifyConfig.imagePlacement = .trailing
            spotifyConfig.imagePadding = 14
        }
        
        connectSpotifyButton.configuration = spotifyConfig
        
        view.addSubview(connectSpotifyButton)
        
        
        // login button
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.backgroundColor = ThemeColor.Color.titleOutline
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.layer.cornerRadius = 16
        signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        view.addSubview(signUpButton)
        
        //New to Neiro? label
        haveAccountLabel.text = "Already have an Account?"
        haveAccountLabel.font = ThemeColor.Font.bodyAuthFont()
        haveAccountLabel.textColor = ThemeColor.Color.textColor
        haveAccountLabel.textAlignment = .center
        view.addSubview(haveAccountLabel)
        
        //sign up button
        switchLoginButton.setTitle("Login", for: .normal)
        switchLoginButton.backgroundColor = ThemeColor.Color.titleOutline
        switchLoginButton.setTitleColor(.white, for: .normal)
        switchLoginButton.layer.cornerRadius = 16
        switchLoginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        view.addSubview(switchLoginButton)
    }
    
    private func createTextField(_ field: UITextField, placeholder: String) {
        
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 14)
        field.backgroundColor = .white
        field.layer.cornerRadius = 6.0
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 34))
        field.leftViewMode = .always
        view.addSubview(field)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let safeBoxTop = view.safeAreaInsets.top
        let safeBoxBottom = view.safeAreaInsets.bottom
        let width = view.bounds.width
        let centerHorizontal = width / 2.0
        
        let side: CGFloat = 28
        let fieldWidth = max(260, width - side * 2)
        let fieldHeight: CGFloat = 34
        let fieldHorizontal = (width - fieldWidth) / 2.0
        
        let spotifyWidth: CGFloat = min(340, width - side * 2)
        let spotifyHeight: CGFloat = 56
        let buttonWidth: CGFloat = 220
        let buttonHeight: CGFloat = 48
        //let buttonHorizontal = (width - buttonWidth) / 2
        
        let titleTop = safeBoxTop + 70
        let titlePaddingX: CGFloat = 28
        let titlePaddingY: CGFloat = 18
        
        let spaceTitleFields: CGFloat = 40
        let spaceFields: CGFloat = 18
        let spaceFieldsSpotify: CGFloat = 26
        let spaceSpotifySignUp: CGFloat = 28
        //let spaceBottomButton: CGFloat = 36
        let spaceAccountButton: CGFloat = 14
        let bottomPadding: CGFloat = max(28, safeBoxBottom + 10)
            
        
        titleLabel.sizeToFit()
        let titleWidth = titleLabel.bounds.width + titlePaddingX * 2
        let titleHeight = titleLabel.bounds.height + titlePaddingY * 2
        titleBackdrop.frame = CGRect(x: (width - titleWidth) / 2, y: titleTop, width: titleWidth, height: titleHeight)
        titleLabel.center = CGPoint(x: centerHorizontal, y: titleBackdrop.frame.midY)

        let userY = titleBackdrop.frame.maxY + spaceTitleFields
        usernameField.frame = CGRect(x: fieldHorizontal, y: userY, width: fieldWidth, height: fieldHeight)
        
        let passY = usernameField.frame.maxY + spaceFields
        passwordField.frame = CGRect(x: fieldHorizontal, y: passY, width: fieldWidth, height: fieldHeight)
        
        let verifyPassY = passwordField.frame.maxY + spaceFields
        verifyPasswordField.frame = CGRect(x: fieldHorizontal, y: verifyPassY, width: fieldWidth, height: fieldHeight)
        
        let spotifyX = (width - spotifyWidth) / 2
        let spotifyY = verifyPasswordField.frame.maxY + spaceFieldsSpotify
        connectSpotifyButton.frame = CGRect(x: spotifyX, y: spotifyY, width: spotifyWidth, height: spotifyHeight)
        
        let signUpY = connectSpotifyButton.frame.maxY + spaceSpotifySignUp
        signUpButton.frame = CGRect(x: (width - buttonWidth) / 2, y: signUpY, width: buttonWidth, height: buttonHeight)
        
        
        haveAccountLabel.sizeToFit()
        
        let loginY = view.bounds.height - bottomPadding - buttonHeight
        let haveAccountY = loginY - spaceAccountButton - haveAccountLabel.bounds.height
        
        
        haveAccountLabel.center = CGPoint(x: centerHorizontal, y: haveAccountY + haveAccountLabel.bounds.height/2)
        
        switchLoginButton.frame = CGRect(x: (width - buttonWidth) / 2, y: loginY, width: buttonWidth, height: buttonHeight)
        
    }
    
    @objc private func handleLogin() {
        let loginVC = LoginViewController()
        loginVC.modalPresentationStyle = .fullScreen
        present(loginVC, animated: true)
    }
    
    @objc private func handleSignUp() {
        guard let username = usernameField.text, !username.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let verifyPassword = verifyPasswordField.text, !verifyPassword.isEmpty else {
            print("Not all inputs are complete.")
            return
        }
        
        guard password == verifyPassword else {
            print("Passwords do not match.")
            return
        }
        Auth.auth().createUser(withEmail: username, password: password) { (authRest, error) in
            if let error = error as NSError? {
                print("\(error.localizedDescription)")
                return
            }
        }
    }

}
