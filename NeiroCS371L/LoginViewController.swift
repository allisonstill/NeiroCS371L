//
//  LoginViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 10/16/25.
//

import UIKit

class LoginViewController: UIViewController {

    private let titleLabel = UILabel()
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
        
        //title label: Login
        titleLabel.text = "Login"
        titleLabel.font = ThemeColor.Font.titleFont()
        titleLabel.textColor = ThemeColor.Color.titleColor
        titleLabel.textAlignment = center
        view.addSubview(titleLabel)
        
        loginButton.setTitle("Login", for: .normal)
    }

}
