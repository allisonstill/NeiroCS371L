import UIKit
import FirebaseAuth

class LoginViewController: UIViewController, UITextFieldDelegate {

    private let titleLabel = UILabel()
    private let titleBackdrop = UIView()
    private let emailField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let newUserLabel = UILabel()
    private let switchSignUpButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailField.delegate = self
        emailField.autocapitalizationType = .none
        passwordField.delegate = self
        passwordField.autocapitalizationType = .none

        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupScreen()
        
        // Hide password
        passwordField.isSecureTextEntry = true
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
        let buttonWidth: CGFloat = 220
        let buttonHeight: CGFloat = 48
        let buttonHorizontal = (width - buttonWidth) / 2
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
        titleLabel.center = CGPoint(x: centerHorizontal, y: titleBackdrop.frame.midY)

        let emailY = titleBackdrop.frame.maxY + spaceTitleFields
        emailField.frame = CGRect(x: fieldHorizontal, y: emailY, width: fieldWidth, height: fieldHeight)
        let passY = emailField.frame.maxY + spaceFields
        passwordField.frame = CGRect(x: fieldHorizontal, y: passY, width: fieldWidth, height: fieldHeight)
        let loginY = passwordField.frame.maxY + spaceFieldsLogin
        loginButton.frame = CGRect(x: buttonHorizontal, y: loginY, width: buttonWidth, height: buttonHeight)
        newUserLabel.sizeToFit()
        let signUpY = view.bounds.height - bottomPadding - buttonHeight
        let newLabelY = signUpY - spaceNewLabelButton - newUserLabel.bounds.height
        newUserLabel.center = CGPoint(x: centerHorizontal, y: newLabelY + newUserLabel.bounds.height/2)
        switchSignUpButton.frame = CGRect(x: buttonHorizontal, y: signUpY, width: buttonWidth, height: buttonHeight)
    }

    @objc private func handleSignUp() {
        let signUpVC = SignUpViewController()
        signUpVC.modalPresentationStyle = .fullScreen
        present(signUpVC, animated: true)
    }

    @objc private func handleLogin() {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            print("Not all inputs are complete.")
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { _, error in
            if let error = error {
                print("Login error: \(error.localizedDescription)")
                return
            }
            DispatchQueue.main.async {
                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let delegate = scene.delegate as? SceneDelegate {
                    delegate.showMainApp(animated: true)
                }
            }
        }
    }
}
