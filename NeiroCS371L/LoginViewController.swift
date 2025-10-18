//
//  LoginViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 10/16/25.
//

import UIKit

class LoginViewController: UIViewController {

    private let titleLabel = UILabel()
    private let titleBackdrop = UIView()
    private let usernameField = UITextField()
    private let passwordField = UITextField()
    private let loginButton = UIButton(type: .system)
    private let newUserLabel = UILabel()
    private let switchSignUpButton = UIButton(type: .system)
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupScreen()
    }
    
    private func setupScreen() {
        
        //title backdrop
        titleBackdrop.backgroundColor = ThemeColor.Color.titleOutline.withAlphaComponent(0.2)
        titleBackdrop.layer.cornerRadius = 24
        view.addSubview(titleBackdrop)
        
        //title label: Login
        titleLabel.text = "Login"
        titleLabel.font = ThemeColor.Font.titleFont()
        titleLabel.textColor = ThemeColor.Color.titleColor
        titleLabel.textAlignment = .center
        view.addSubview(titleLabel)
        
       
        //creating textfields
        createTextField(usernameField, placeholder: "username")
        createTextField(passwordField, placeholder: "password")
        
        
        // login button
        loginButton.setTitle("Login", for: .normal)
        loginButton.backgroundColor = ThemeColor.Color.titleOutline
        loginButton.setTitleColor(.white, for: .normal)
        loginButton.layer.cornerRadius = 16
        view.addSubview(loginButton)
        
        //New to Neiro? label
        newUserLabel.text = "New to Neiro?"
        newUserLabel.font = ThemeColor.Font.bodyAuthFont()
        newUserLabel.textColor = ThemeColor.Color.textColor
        newUserLabel.textAlignment = .center
        view.addSubview(newUserLabel)
        
        //sign up button
        switchSignUpButton.setTitle("Sign Up", for: .normal)
        switchSignUpButton.backgroundColor = ThemeColor.Color.titleOutline
        switchSignUpButton.setTitleColor(.white, for: .normal)
        switchSignUpButton.layer.cornerRadius = 16
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
        
        let safeBoxTop = view.safeAreaInsets.top
        let safeBoxBottom = view.safeAreaInsets.bottom
        let width = view.bounds.width
        let centerHorizontal = width / 2.0
        
        let side: CGFloat = 28
        let fieldWidth = max(260, width - side * 2)
        let fieldHeight: CGFloat = 34
        let fieldHorizontal = (width - fieldWidth) / 2.0
        
        let buttonWidth: CGFloat = 220
        let buttonHeight: CGFloat = 48
        let buttonHorizontal = (width - buttonWidth) / 2
        
        let titleTop = safeBoxTop + 72
        let titlePaddingX: CGFloat = 24
        let titlePaddingY: CGFloat = 12
        
        let spaceTitleFields: CGFloat = 44
        let spaceFields: CGFloat = 18
        let spaceFieldsLogin: CGFloat = 30
        //let spaceLoginNewLabel: CGFloat = 72
        let spaceNewLabelButton: CGFloat = 18
        let bottomPadding: CGFloat = max(28, safeBoxBottom + 10)
            
        
        titleLabel.sizeToFit()
        let titleWidth = titleLabel.bounds.width + titlePaddingX * 2
        let titleHeight = titleLabel.bounds.height + titlePaddingY * 2
        titleBackdrop.frame = CGRect(x: (width - titleWidth) / 2 - 40, y: titleTop - 10, width: titleWidth + 80, height: titleHeight + 20)
        titleLabel.center = CGPoint(x: centerHorizontal, y: titleBackdrop.frame.midY)

        let userY = titleBackdrop.frame.maxY + spaceTitleFields
        usernameField.frame = CGRect(x: fieldHorizontal, y: userY, width: fieldWidth, height: fieldHeight)
        
        let passY = usernameField.frame.maxY + spaceFields
        passwordField.frame = CGRect(x: fieldHorizontal, y: passY, width: fieldWidth, height: fieldHeight)
        
        let loginY = passwordField.frame.maxY + spaceFieldsLogin
        loginButton.frame = CGRect(x: buttonHorizontal, y: loginY, width: buttonWidth, height: buttonHeight)
        
        newUserLabel.sizeToFit()
        let signUpY = view.bounds.height - bottomPadding - buttonHeight
        let newLabelY = signUpY - spaceNewLabelButton - newUserLabel.bounds.height
        
        
        newUserLabel.center = CGPoint(x: centerHorizontal, y: newLabelY + newUserLabel.bounds.height/2)
        
        switchSignUpButton.frame = CGRect(x: buttonHorizontal, y: signUpY, width: buttonWidth, height: buttonHeight)
        
    }

}
