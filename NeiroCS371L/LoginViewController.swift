//
//  LoginViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 10/16/25.
//

import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    private let titleLabel = UILabel()
    private let titleBackdrop = UIView()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let forgotPasswordButton = UIButton(type: .system)
    private let orLabel = UILabel()
    private let spotifyLoginButton = UIButton(type: .system)
    private let newUserLabel = UILabel()
    private let switchSignUpButton = UIButton(type: .system)

    // Toggle for demo behavior
    var demo: Bool = true
    private var demoButton: UIButton?

    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        emailField.autocapitalizationType = .none
        passwordField.delegate = self
        passwordField.autocapitalizationType = .none
        passwordField.isSecureTextEntry = true

        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupScreen()
        
        NotificationCenter.default.addObserver(self, selector: #selector(spotifyAuthSuccess), name: Notification.Name("spotifyAuthSuccess"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(spotifyAuthFailed), name: Notification.Name("spotifyAuthFailed"), object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func spotifyAuthSuccess() {
        DispatchQueue.main.async { [weak self] in
            self?.spotifyLoginButton.isEnabled = true
            self?.spotifyLoginButton.setTitle("Sign in with Spotify", for: .normal)
            //scene delegate to navigate to main app
        }
    }
    
    @objc private func spotifyAuthFailed() {
        DispatchQueue.main.async { [weak self] in
            self?.spotifyLoginButton.isEnabled = true
            self?.spotifyLoginButton.setTitle("Sign in with Spotify", for: .normal)
            self?.showAlert(title: "Spotify Login Failed", message: "Unable to authenticate with Spotify. Please try again or use email and password to log in.")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Auto-fill once for convenience during demo
        if demo, (emailField.text ?? "").isEmpty, (passwordField.text ?? "").isEmpty {
            demoCreds()
        }
    }

    // MARK: - Demo helpers
    func demoCreds() {
        emailField.text = "neiro.test.user@gmail.com"
        passwordField.text = "neiro.test.user1!"
    }

    @objc private func fillDemo() { demoCreds() }

    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    // MARK: - Layout
    private func setupScreen() {
        titleBackdrop.backgroundColor = ThemeColor.Color.titleOutline.withAlphaComponent(0.2)
        titleBackdrop.layer.cornerRadius = 24
        view.addSubview(titleBackdrop)

        titleLabel.text = "Login"
        titleLabel.font = ThemeColor.Font.titleFont()
        titleLabel.textColor = ThemeColor.Color.titleColor
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)

        createTextField(emailField, placeholder: "email")
        createTextField(passwordField, placeholder: "password")

        loginButton.setTitle("Login", for: .normal)
        loginButton.backgroundColor = ThemeColor.Color.titleOutline
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 16
        loginButton.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        view.addSubview(loginButton)
        
        forgotPasswordButton.setTitle("Forgot Password?", for: .normal)
        forgotPasswordButton.setTitleColor(ThemeColor.Color.titleColor.withAlphaComponent(0.8), for: .normal)
        forgotPasswordButton.titleLabel?.font = ThemeColor.Font.bodyAuthFont().withSize(16)
        forgotPasswordButton.addTarget(self, action: #selector(handleForgotPassword), for: .touchUpInside)
        view.addSubview(forgotPasswordButton)
        
        orLabel.text = "or"
        orLabel.font = ThemeColor.Font.bodyAuthFont()
        orLabel.textColor = ThemeColor.Color.textColor
        orLabel.textAlignment = .center
        view.addSubview(orLabel)
        
        spotifyLoginButton.setTitle("Sign in with Spotify", for: .normal)
        spotifyLoginButton.backgroundColor = UIColor(red: 0.11, green: 0.73, blue: 0.33, alpha: 1.0) // looked up rgb for spotify color
        spotifyLoginButton.setTitleColor(.white, for: .normal)
        spotifyLoginButton.layer.cornerRadius = 16
        spotifyLoginButton.addTarget(self, action: #selector(handleSpotifyLogin), for: .touchUpInside)
        view.addSubview(spotifyLoginButton)

        newUserLabel.text = "New to Neiro?"
        newUserLabel.font = ThemeColor.Font.bodyAuthFont()
        newUserLabel.textColor = ThemeColor.Color.textColor
        newUserLabel.textAlignment = .center
        view.addSubview(newUserLabel)

        switchSignUpButton.setTitle("Sign Up", for: .normal)
        switchSignUpButton.backgroundColor = ThemeColor.Color.titleOutline
        switchSignUpButton.setTitleColor(.white, for: .normal)
        switchSignUpButton.layer.cornerRadius = 16
        switchSignUpButton.addTarget(self, action: #selector(handleSignUp), for: .touchUpInside)
        view.addSubview(switchSignUpButton)
    }

    private func createTextField(_ field: UITextField, placeholder: String) {
        field.placeholder = placeholder
        field.font = .systemFont(ofSize: 14)
        field.backgroundColor = UIColor.systemGray5
        field.layer.borderColor = ThemeColor.Color.titleOutline.cgColor
        field.layer.borderWidth = 1.5
        field.layer.cornerRadius = 10
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 34))
        field.leftViewMode = .always
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        view.addSubview(field)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let width = view.bounds.width
        let centerX = width / 2.0
        let side: CGFloat = 28
        let fieldWidth = max(260, width - side * 2)
        let fieldHeight: CGFloat = 34
        let fieldX = (width - fieldWidth) / 2.0
        let buttonWidth: CGFloat = 220
        let buttonHeight: CGFloat = 48
        let buttonX = (width - buttonWidth) / 2
        let titleTop = view.safeAreaInsets.top + 72
        let spaceTitleFields: CGFloat = 44
        let spaceFields: CGFloat = 18
        let spaceFieldsLogin: CGFloat = 30
        let spaceNewLabelButton: CGFloat = 18
        let bottomPadding: CGFloat = max(28, view.safeAreaInsets.bottom + 10)

        titleLabel.sizeToFit()
        let titleWidth = titleLabel.bounds.width + 48
        let titleHeight = titleLabel.bounds.height + 32
        titleBackdrop.frame = CGRect(x: (width - titleWidth) / 2 - 40, y: titleTop - 10, width: titleWidth + 80, height: titleHeight + 20)
        titleLabel.center = CGPoint(x: centerX, y: titleBackdrop.frame.midY)

        let emailY = titleBackdrop.frame.maxY + spaceTitleFields
        emailField.frame = CGRect(x: fieldX, y: emailY, width: fieldWidth, height: fieldHeight)
        let passY = emailField.frame.maxY + spaceFields
        passwordField.frame = CGRect(x: fieldX, y: passY, width: fieldWidth, height: fieldHeight)
        
        
        let loginY = passwordField.frame.maxY + spaceFieldsLogin
        loginButton.frame = CGRect(x: buttonX, y: loginY, width: buttonWidth, height: buttonHeight)
        
        let orY = loginButton.frame.maxY + 20
        orLabel.frame = CGRect(x:0, y: orY, width: width, height: 20)
        
        let spotifyY = orLabel.frame.maxY + 20
        spotifyLoginButton.frame = CGRect(x: buttonX, y: spotifyY, width: buttonWidth, height: buttonHeight)
        
        forgotPasswordButton.sizeToFit()
        let forgotY = spotifyLoginButton.frame.maxY + 18
        forgotPasswordButton.frame = CGRect(x: buttonX +  forgotPasswordButton.frame.width / 3, y: forgotY, width: forgotPasswordButton.bounds.width, height: forgotPasswordButton.bounds.height)

        newUserLabel.sizeToFit()
        let signUpY = view.bounds.height - bottomPadding - buttonHeight
        let newLabelY = signUpY - spaceNewLabelButton - newUserLabel.bounds.height
        newUserLabel.center = CGPoint(x: centerX, y: newLabelY + newUserLabel.bounds.height/2)
        switchSignUpButton.frame = CGRect(x: buttonX, y: signUpY, width: buttonWidth, height: buttonHeight)
    }

    // MARK: - Flows
    @objc private func handleSignUp() {
        let signUpVC = SignUpViewController()
        signUpVC.modalPresentationStyle = .fullScreen
        present(signUpVC, animated: true)
    }
    
    @objc private func handleSpotifyLogin() {
        spotifyLoginButton.isEnabled = false
        spotifyLoginButton.setTitle("Connecting to Spotify...", for: .normal)
        
        SpotifyUserAuthorization.shared.startLogin(presentingVC: self, forSignup: true) { [weak self] safariVC in
            if safariVC == nil {
                DispatchQueue.main.async {
                    self?.spotifyLoginButton.isEnabled = true
                    self?.spotifyLoginButton.setTitle("Sign in with Spotify", for: .normal)
                    self?.showAlert(title: "Error", message: "Could not log in with Spotify. Please try again.")
                }
            }
        }
    }
    
    @objc private func handleForgotPassword() {
        guard let email = emailField.text, !email.isEmpty else {
            showAlert(title: "Email Required", message: "Please enter your email above.")
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email.")
            return
        }
        sendPasswordReset(email: email)
    }

    @objc private func handleLogin() {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(title: "Missing fields", message: "Please fill in all fields.")
            return
        }
        
        guard email.contains("@") && email.contains(".") else {
            showAlert(title: "Invalid Email", message: "Please enter a valid email.")
            return
        }
        
        loginButton.isEnabled = false
        loginButton.setTitle("Logging in...", for: .normal)

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            
            DispatchQueue.main.async {
                self?.loginButton.isEnabled = true
                self?.loginButton.setTitle("Login", for: .normal)
            }
            
            if let error = error {
                self?.handleLoginError(error)
                return
            }
            print("Login success!")
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let delegate = scene.delegate as? SceneDelegate {
                    delegate.showMainApp(animated: true)
                }
            }
        }
    }
    
    private func handleLoginError(_ error: Error) {
        let nsError = error as NSError
        if let errorCode = AuthErrorCode(rawValue: nsError.code) {
            switch errorCode {
            case .wrongPassword:
                showAlert(title: "Incorrect Password", message: "The password you entered is incorrect. Please try again.")
            case .userNotFound:
                showAlert(title: "User Not Found", message: "No user was found with that email. Would you like to sign up?", showSignUp: true)
            case .invalidEmail:
                showAlert(title: "Invalid Email", message: "The email you entered is invalid. Please try again.")
            default:
                showAlert(title: "Login Failed", message: "\(error.localizedDescription)")
            
            }
        } else {
            showAlert(title: "Login Failed", message: "\(error.localizedDescription)")
        }
    }
    
    private func showAlert(title: String, message: String, showSignUp: Bool = false) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        if showSignUp {
            alert.addAction(UIAlertAction(title: "Sign Up", style: .default) { [weak self] _ in
                self?.handleSignUp()
            })
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        } else {
            alert.addAction(UIAlertAction(title: "OK", style: .default))
        }
        present(alert, animated: true)
    }
    
    private func sendPasswordReset(email: String) {
        let loadingAlert = UIAlertController(title: "Sending Reset Email...", message: "Please wait", preferredStyle: .alert)
        present(loadingAlert, animated: true)
        
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            DispatchQueue.main.async {
                loadingAlert.dismiss(animated: true) {
                    if let error = error {
                        self?.showAlert(title: "Reset Failed", message: "Unable to send password reset email: \(error.localizedDescription)")
                    } else {
                        self?.showAlert(title: "Check your Email", message: "A password reset email has been sent to your inbox.")
                    }
                }
            }
        }
    }
}
