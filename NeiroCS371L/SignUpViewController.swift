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
    private let orDivider = UIView()
    private let orLabel = UILabel()
    private let haveAccountLabel = UILabel()
    private let switchLoginButton = UIButton(type: .system)
    
    //spotify observers
    private var spotifySuccessObserver: NSObjectProtocol?
    private var spotifyFailObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        emailField.delegate = self
        passwordField.delegate = self
        verifyPasswordField.delegate = self
        setupUI()
        setupSpotifyObservers()
    }
    
    deinit {
        //clean up observers
        if let observer = spotifySuccessObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = spotifyFailObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    private func setupUI() {
        //title backdrop
        titleBackdrop.backgroundColor = ThemeColor.Color.titleOutline.withAlphaComponent(0.2)
        titleBackdrop.layer.cornerRadius = 24
        view.addSubview(titleBackdrop)
        
        //title
        titleLabel.text = "Create an\nAccount"
        titleLabel.numberOfLines = 2
        titleLabel.lineBreakMode = .byWordWrapping
        titleLabel.font = ThemeColor.Font.titleFont()
        titleLabel.textColor = ThemeColor.Color.titleColor
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
        //email field
        createTextField(emailField, placeholder: "Email", isSecure: false)
        
        //password field
        createTextField(passwordField, placeholder: "Password", isSecure: true)
        
        //verify password field
        createTextField(verifyPasswordField, placeholder: "Verify Password", isSecure: true)
        
        //signUp button
        signUpButton.setTitle("Sign Up", for: .normal)
        signUpButton.backgroundColor = ThemeColor.Color.titleOutline
        signUpButton.setTitleColor(.white, for: .normal)
        signUpButton.layer.cornerRadius = 16
        signUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        view.addSubview(signUpButton)
        
        //or label/divider
        setupOrDivider()

        setupSpotifyButton()
        
        //have account? label
        haveAccountLabel.text = "Already have an Account?"
        haveAccountLabel.font = ThemeColor.Font.bodyAuthFont()
        haveAccountLabel.textColor = ThemeColor.Color.textColor
        haveAccountLabel.textAlignment = .center
        view.addSubview(haveAccountLabel)
        
        //switch to login screen button
        switchLoginButton.setTitle("Login", for: .normal)
        switchLoginButton.backgroundColor = ThemeColor.Color.titleOutline
        switchLoginButton.setTitleColor(.white, for: .normal)
        switchLoginButton.layer.cornerRadius = 16
        switchLoginButton.addTarget(self, action: #selector(handleSwitchToLogin), for: .touchUpInside)
        view.addSubview(switchLoginButton)
        
        setupConstraints()

    }
    
    private func createTextField(_ field: UITextField, placeholder: String, isSecure: Bool) {
        field.placeholder = placeholder
        field.backgroundColor = UIColor.systemGray6
        field.layer.borderWidth = 1.5
        field.layer.borderColor = ThemeColor.Color.titleOutline.cgColor
        field.layer.cornerRadius = 10
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.isSecureTextEntry = isSecure
        
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 50))
        field.leftView = paddingView
        field.leftViewMode = .always
        view.addSubview(field)
    }
    
    private func setupOrDivider() {
        //horizontal line
        //"or" in the middle separating regular sign up with spotify sign up
        orDivider.backgroundColor = ThemeColor.Color.titleOutline
        view.addSubview(orDivider)
        
        orLabel.text = "Or"
        orLabel.font = ThemeColor.Font.bodyAuthFont()
        orLabel.textColor = ThemeColor.Color.textColor
        orLabel.textAlignment = .center
        orLabel.backgroundColor = ThemeColor.Color.backgroundColor
        view.addSubview(orLabel)
    }
    
    private func setupSpotifyButton() {
        var config = UIButton.Configuration.filled()
        config.title = "Connect Spotify Account"
        config.baseBackgroundColor = UIColor.systemGreen.withAlphaComponent(0.6)
        config.baseForegroundColor = .white
        
        if let spotifyLogo = UIImage(named: "spotify_logo") {
            let resizedLogo = spotifyLogo.resize(to: CGSize(width: 28, height: 28))
            config.image = resizedLogo
            config.imagePlacement = .trailing
            config.imagePadding = 14
        }
        
        connectSpotifyButton.configuration = config
        connectSpotifyButton.addTarget(self, action: #selector(handleSpotifySignUp), for: .touchUpInside)
        view.addSubview(connectSpotifyButton)
    }
    
    private func setupConstraints() {
        
        //no autoresizing
        [titleBackdrop, titleLabel, emailField, passwordField, verifyPasswordField, signUpButton, orDivider, orLabel, connectSpotifyButton, haveAccountLabel, switchLoginButton].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }
        
        NSLayoutConstraint.activate([
            
            //title backdrop
            titleBackdrop.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            titleBackdrop.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            titleBackdrop.widthAnchor.constraint(equalToConstant: 320),
            titleBackdrop.heightAnchor.constraint(equalToConstant: 160),
            
            //title label
            titleLabel.centerXAnchor.constraint(equalTo: titleBackdrop.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: titleBackdrop.centerYAnchor),
            
            //email field
            emailField.topAnchor.constraint(equalTo: titleBackdrop.bottomAnchor, constant: 40),
            emailField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            emailField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            emailField.heightAnchor.constraint(equalToConstant: 50),
            
            //password field
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 16),
            passwordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            passwordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            passwordField.heightAnchor.constraint(equalToConstant: 50),
            
            //verify password field
            verifyPasswordField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 16),
            verifyPasswordField.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            verifyPasswordField.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            verifyPasswordField.heightAnchor.constraint(equalToConstant: 50),
            
            //sign up button
            signUpButton.topAnchor.constraint(equalTo: verifyPasswordField.bottomAnchor, constant: 24),
            signUpButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            signUpButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            signUpButton.heightAnchor.constraint(equalToConstant: 50),
            
            //or divider
            orDivider.topAnchor.constraint(equalTo: signUpButton.bottomAnchor, constant: 24),
            orDivider.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            orDivider.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            orDivider.heightAnchor.constraint(equalToConstant: 1),
            
            //or label
            orLabel.centerXAnchor.constraint(equalTo: orDivider.centerXAnchor),
            orLabel.centerYAnchor.constraint(equalTo: orDivider.centerYAnchor),
            orLabel.widthAnchor.constraint(equalToConstant: 40),
            
            //spotify button
            connectSpotifyButton.topAnchor.constraint(equalTo: orDivider.bottomAnchor, constant: 24),
            connectSpotifyButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            connectSpotifyButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            connectSpotifyButton.heightAnchor.constraint(equalToConstant: 50),
            
            //switch to login button
            switchLoginButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            switchLoginButton.leadingAnchor.constraint(equalTo: emailField.leadingAnchor),
            switchLoginButton.trailingAnchor.constraint(equalTo: emailField.trailingAnchor),
            switchLoginButton.heightAnchor.constraint(equalToConstant: 50),
            
            //have account label
            haveAccountLabel.bottomAnchor.constraint(equalTo: switchLoginButton.topAnchor, constant: -8),
            haveAccountLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
            
            
            
        ])
    }
    
    
    private func setupSpotifyObservers() {
        spotifySuccessObserver = NotificationCenter.default.addObserver(forName: Notification.Name("spotifyAuthSuccess"), object: nil, queue: .main) { [weak self] _ in
            self?.navigateToMainApp()
        }
        
        spotifyFailObserver = NotificationCenter.default.addObserver(forName: Notification.Name("spotifyAuthFailed"), object: nil, queue: .main) { [weak self] _ in
            self?.showSpotifyError()
        }
    }
    
    @objc private func handleSwitchToLogin() {
//        let loginVC = LoginViewController()
//        loginVC.modalPresentationStyle = .fullScreen
//        present(loginVC, animated: true)
        dismiss(animated: true)
    }
    
    @objc private func handleSignUp() {
        let trueEmail = emailField.text ?? ""
        let truePassword = passwordField.text ?? ""
        let trueVerifyPassword = verifyPasswordField.text ?? ""
        
        let email = trueEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let password = truePassword.trimmingCharacters(in: .whitespacesAndNewlines)
        let verifyPassword = trueVerifyPassword.trimmingCharacters(in: .whitespacesAndNewlines)
        
        
        guard !email.isEmpty, !password.isEmpty, !verifyPassword.isEmpty else {
            showAlert(title: "Missing fields", message: "Please fill in all of the fields.")
            return
        }
        
        guard email.contains("@"), email.contains(".") else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email")
            return
        }
        
        guard password == verifyPassword else {
            showAlert(title: "Password Mismatch", message: "Passwords do not match.")
            return
        }
        
        guard password.count >= 6 else {
            showAlert(title: "Weak Password", message: "Password length must be at least 6 characters.")
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { _, error in
            if let error = error {
                self.showAlert(title: "Sign Up Error", message: error.localizedDescription)
            } else {
                print("Account created successfully!")
                self.navigateToMainApp()
            }
        }
    }
    
    @objc private func handleSpotifySignUp() {
        SpotifyUserAuthorization.shared.startLogin(presentingVC: self, forSignup: true) { safari in
            if safari == nil {
                self.showAlert(title: "Error", message: "Failed to start Spotify login")
            }
        }
    }
    
    private func navigateToMainApp() {
        DispatchQueue.main.async {
            if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let delegate = scene.delegate as? SceneDelegate {
                delegate.showMainApp(animated: true)
            }
        }
    }
    
    private func showSpotifyError() {
        showAlert(
            title: "Spotify Connection Failure",
            message: "Unable to connect to Spotify. Please try again."
        )
    }
    
    //helper function to show alerts
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default)
        alert.addAction(action)
        present(alert, animated: true)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
