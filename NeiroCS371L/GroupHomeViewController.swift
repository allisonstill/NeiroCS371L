//
//  GroupHomeViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit

final class GroupHomeViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let createButton = UIButton(type: .system)
    private let joinButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        title = "Group Sessions"
        navigationItem.largeTitleDisplayMode = .always
        
        configureLabels()
        configureButtons()
        layoutUI()
    }
    
    private func configureLabels() {
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Create a playlist with friends based on everyone’s mood."
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.8)
        subtitleLabel.numberOfLines = 0
    }
    
    private func configureButtons() {
        // create button
        stylePrimary(createButton, title: "Create a Group")
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        
        // join button (placeholder for now)
        styleSecondary(joinButton, title: "Join a Group")
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
    }
    
    private func stylePrimary(_ button: UIButton, title: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 52).isActive = true
    }
    
    private func styleSecondary(_ button: UIButton, title: String) {
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        button.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
        button.setTitleColor(.label, for: .normal)
        button.layer.cornerRadius = 14
        button.heightAnchor.constraint(equalToConstant: 48).isActive = true
    }
    
    private func layoutUI() {
        let stack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, createButton, joinButton])
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill
        
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }
    
    // MARK: - Actions
    
    @objc private func createTapped() {
        let vc = CreateGroupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
    
    @objc private func joinTapped() {
        let vc = JoinGroupViewController()
        navigationController?.pushViewController(vc, animated: true)
    }
}
