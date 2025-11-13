//
//  JoinGroupViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit

final class JoinGroupViewController: UIViewController {

    private let codeField = UITextField()
    private let joinButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        title = "Join Group"
        navigationItem.largeTitleDisplayMode = .never

        configureUI()
        layoutUI()
    }

    private func configureUI() {
        codeField.placeholder = "Enter group code"
        codeField.autocapitalizationType = .allCharacters
        codeField.textAlignment = .center
        codeField.font = .systemFont(ofSize: 22, weight: .semibold)
        codeField.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        codeField.layer.cornerRadius = 12
        codeField.translatesAutoresizingMaskIntoConstraints = false

        joinButton.setTitle("Join", for: .normal)
        joinButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        joinButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.layer.cornerRadius = 14
        joinButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        joinButton.translatesAutoresizingMaskIntoConstraints = false
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
    }

    private func layoutUI() {
        let stack = UIStackView(arrangedSubviews: [codeField, joinButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .fill

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func joinTapped() {
        let code = (codeField.text ?? "").uppercased().trimmingCharacters(in: .whitespaces)

        if let group = GroupManager.shared.joinGroup(withCode: code) {
            let vc = GroupHostViewController(group: group)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            let alert = UIAlertController(title: "Invalid Code",
                                          message: "No group found with that code.",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
