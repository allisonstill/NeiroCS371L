//
//  JoinGroupViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit

final class JoinGroupViewController: UIViewController {

    private let codeField = UITextField()
    private let nameField = UITextField()
    private let joinButton = UIButton(type: .system)
    
    // Grid Container
    private let emojiGridStack = UIStackView()
    private var emojiButtons: [UIButton] = []
    private var selectedEmoji: String?

    // The fixed list of options matching your screenshot
    private let emojiOptions = [
        "😀", "😎", "🥲", "😭",
        "🤪", "🤩", "😴", "😐",
        "😌", "🙂", "🙃", "😕",
        "🔥", "❤️", "⚡️", "💀"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Join Group"
        
        configureUI()
        layoutUI()
    }

    private func configureUI() {
        codeField.placeholder = "Enter 5-Letter Code"
        codeField.autocapitalizationType = .allCharacters
        codeField.textAlignment = .center
        codeField.font = .systemFont(ofSize: 22, weight: .bold)
        codeField.borderStyle = .roundedRect
        
        nameField.placeholder = "Your Name"
        nameField.textAlignment = .center
        nameField.font = .systemFont(ofSize: 18)
        nameField.borderStyle = .roundedRect
        
        // BUILD THE GRID
        emojiGridStack.axis = .vertical
        emojiGridStack.spacing = 15
        emojiGridStack.distribution = .fillEqually
        
        // Create 4 rows of 4 buttons
        var index = 0
        for _ in 0..<4 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.spacing = 15
            rowStack.distribution = .fillEqually
            
            for _ in 0..<4 {
                if index < emojiOptions.count {
                    let emoji = emojiOptions[index]
                    let btn = createEmojiButton(emoji: emoji)
                    rowStack.addArrangedSubview(btn)
                    emojiButtons.append(btn)
                    index += 1
                }
            }
            emojiGridStack.addArrangedSubview(rowStack)
        }

        joinButton.setTitle("Join Group", for: .normal)
        joinButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
        joinButton.backgroundColor = .systemBlue
        joinButton.setTitleColor(.white, for: .normal)
        joinButton.layer.cornerRadius = 12
        joinButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        joinButton.addTarget(self, action: #selector(joinTapped), for: .touchUpInside)
    }
    
    private func createEmojiButton(emoji: String) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setTitle(emoji, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 32)
        btn.backgroundColor = .secondarySystemBackground
        btn.layer.cornerRadius = 12
        btn.heightAnchor.constraint(equalToConstant: 60).isActive = true
        btn.addTarget(self, action: #selector(emojiTapped(_:)), for: .touchUpInside)
        return btn
    }

    private func layoutUI() {
        let mainStack = UIStackView(arrangedSubviews: [codeField, nameField, emojiGridStack, joinButton])
        mainStack.axis = .vertical
        mainStack.spacing = 25
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(mainStack)
        
        NSLayoutConstraint.activate([
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 30),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -30),
            mainStack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    @objc private func emojiTapped(_ sender: UIButton) {
        // Reset all
        emojiButtons.forEach {
            $0.backgroundColor = .secondarySystemBackground
            $0.layer.borderWidth = 0
        }
        // Highlight selected
        sender.backgroundColor = .systemBlue.withAlphaComponent(0.2)
        sender.layer.borderColor = UIColor.systemBlue.cgColor
        sender.layer.borderWidth = 2
        selectedEmoji = sender.title(for: .normal)
    }

    @objc private func joinTapped() {
        let code = (codeField.text ?? "").uppercased().trimmingCharacters(in: .whitespaces)
        let name = (nameField.text ?? "").trimmingCharacters(in: .whitespaces)
        
        guard !code.isEmpty else { return }
        
        guard let emoji = selectedEmoji else {
            let alert = UIAlertController(title: "Select Avatar", message: "Pick an emoji from the grid!", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let finalName = name.isEmpty ? "Guest" : name
        
        joinButton.isEnabled = false
        joinButton.setTitle("Joining...", for: .normal)

        GroupManager.shared.joinGroup(code: code, userName: finalName, emoji: emoji) { [weak self] group in
            DispatchQueue.main.async {
                self?.joinButton.isEnabled = true
                self?.joinButton.setTitle("Join Group", for: .normal)
                
                if let group = group {
                    let vc = GroupHostViewController(group: group)
                    self?.navigationController?.pushViewController(vc, animated: true)
                } else {
                    let alert = UIAlertController(title: "Error", message: "Group not found", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default))
                    self?.present(alert, animated: true)
                }
            }
        }
    }
}
