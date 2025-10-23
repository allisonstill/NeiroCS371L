//
//  SignUpViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 10/16/25.
//

import UIKit
import FirebaseAuth

class SignUpViewController: UIViewController, UITextFieldDelegate {
    
    private let titleLabel = UILabel()
    private let titleBackdrop = UIView()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let verifyPasswordField = UITextField()
    private let connectSpotifyButton = UIButton(type: .system)
    private let signUpButton = UIButton(type: .system)
    private let haveAccountLabel = UILabel()
    private let switchLoginButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        emailField.autocapitalizationType = .none
        passwordField.delegate = self
        passwordField.autocapitalizationType = .none
        verifyPasswordField.delegate = self
        verifyPasswordField.autocapitalizationType = .none

        // Hide passwords
        passwordField.isSecureTextEntry = true
        verifyPasswordField.isSecureTextEntry = true
        
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupScreen()
    }
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
        
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    private func setupScreen() {
        titleBackdrop.backgroundColor = ThemeColor.Color.titleOutline.withAlphaComponent(0.2)
        titleBackdrop.layer.cornerRadius = 24
        view.addSubview(titleBackdrop)
        
        titleLabel.text = "Create an\nAccount"
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = ThemeColor.Font.titleFont()
        titleLabel.textColor = ThemeColor.Color.titleColor
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        createTextField(emailField, placeholder: "email")
        createTextField(passwordField, placeholder: "password")
        createTextField(verifyPasswordField, placeholder: "verify password")
        
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
        
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.backgroundColor = ThemeColor.Color.titleOutline
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.layer.cornerRadius = 16
        signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        view.addSubview(signUpButton)
        
        haveAccountLabel.text = "Already have an Account?"
        haveAccountLabel.font = ThemeColor.Font.bodyAuthFont()
        haveAccountLabel.textColor = ThemeColor.Color.textColor
        haveAccountLabel.textAlignment = .center
        view.addSubview(haveAccountLabel)
        
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
        let titleTop = view.safeAreaInsets.top + 70
        let spaceTitleFields: CGFloat = 40
        let spaceFields: CGFloat = 18
        let spaceFieldsSpotify: CGFloat = 26
        let spaceSpotifySignUp: CGFloat = 28
        let spaceAccountButton: CGFloat = 14
        let bottomPadding: CGFloat = max(28, view.safeAreaInsets.bottom + 10)
        
        titleLabel.sizeToFit()
        let titleWidth = titleLabel.bounds.width + 56
        let titleHeight = titleLabel.bounds.height + 36
        titleBackdrop.frame = CGRect(x: (width - titleWidth) / 2, y: titleTop, width: titleWidth, height: titleHeight)
        titleLabel.center = CGPoint(x: centerHorizontal, y: titleBackdrop.frame.midY)

        let emailY = titleBackdrop.frame.maxY + spaceTitleFields
        emailField.frame = CGRect(x: fieldHorizontal, y: emailY, width: fieldWidth, height: fieldHeight)
        let passY = emailField.frame.maxY + spaceFields
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
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let verifyPassword = verifyPasswordField.text, !verifyPassword.isEmpty else {
            print("Not all inputs are complete.")
            return
        }
        guard password == verifyPassword else {
            print("Passwords do not match.")
            return
        }
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            if let error = error {
                print("Signup error: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let delegate = scene.delegate as? SceneDelegate {
                    delegate.showMainApp(animated: true)
                } else {
                    self.present(FloatingBarDemoViewController(), animated: true)
                }
            }
        }
    }
}
