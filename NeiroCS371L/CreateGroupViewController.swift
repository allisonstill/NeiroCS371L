//
//  CreateGroupViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit

final class CreateGroupViewController: UIViewController, UITextFieldDelegate {
    
    private let nameField = UITextField()
    private let nameLabel = UILabel()
    private let emojiLabel = UILabel()
    private let continueButton = UIButton(type: .system)
    
    private var collectionView: UICollectionView!
    private var selectedEmoji: String?
    
    // reuse the same emoji palette
    private let emojis: [String] = [
        "😀","😎","🥲","😭",
        "🤪","🤩","😴","😐",
        "😌","🙂","🙃","😕",
        "🔥","❤️","⚡️","🤔"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        title = "Create Group"
        navigationItem.largeTitleDisplayMode = .never
        
        configureNameField()
        configureLabels()
        setupCollection()
        configureContinueButton()
        layoutUI()
        applyButtonState()
    }
    
    private func configureNameField() {
        nameField.translatesAutoresizingMaskIntoConstraints = false
        nameField.placeholder = "Your Name"
        nameField.font = .systemFont(ofSize: 16)
        nameField.textColor = .white
        nameField.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        nameField.layer.cornerRadius = 10
        nameField.setLeftPaddingPoints(12)
        nameField.setRightPaddingPoints(12)
        nameField.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        
        nameField.delegate = self
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
            self.view.endEditing(true)
        }
    
    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
            textField.resignFirstResponder()
            return true
        }
    
    private func configureLabels() {
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.text = "Name"
        nameLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        nameLabel.textColor = .white
        
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.text = "Pick your mood emoji"
        emojiLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        emojiLabel.textColor = .white
    }
    
    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 12
        layout.sectionInset = UIEdgeInsets(top: 12, left: 0, bottom: 4, right: 0)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func configureContinueButton() {
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.setTitle("Next", for: .normal)
        continueButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        continueButton.layer.cornerRadius = 14
        continueButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        continueButton.addTarget(self, action: #selector(nextTapped), for: .touchUpInside)
    }
    
    private func layoutUI() {
        let stack = UIStackView(arrangedSubviews: [nameLabel, nameField, emojiLabel, collectionView, continueButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill
        
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.35)
        ])
    }
    
    private func applyButtonState() {
        let hasName = !(nameField.text ?? "").trimmingCharacters(in: .whitespaces).isEmpty
        let hasEmoji = selectedEmoji != nil
        let enabled = hasName && hasEmoji
        
        continueButton.isEnabled = enabled
        continueButton.backgroundColor = enabled
        ? UIColor.systemBlue.withAlphaComponent(0.9)
        : UIColor.systemBlue.withAlphaComponent(0.4)
        continueButton.setTitleColor(.white, for: .normal)
    }
    
    // MARK: - Actions
    
    @objc private func textDidChange() {
        applyButtonState()
    }
    
    @objc private func nextTapped() {
        guard let emoji = selectedEmoji else { return }
        
        let rawName = (nameField.text ?? "").trimmingCharacters(in: .whitespaces)
        let userName = rawName.isEmpty ? "Group \(emoji)" : rawName
        
        // Use the Manager (Handles Firebase & ID generation automatically)
        // We DO NOT manually create 'GroupMember' here anymore.
        GroupManager.shared.createGroup(userName: userName) { [weak self] newGroup in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let group = newGroup {
                    let hostVC = GroupHostViewController(group: group)
                    self.navigationController?.pushViewController(hostVC, animated: true)
                } else {
                    print("Error creating group")
                }
            }
        }
    }
}

// MARK: - Collection

extension CreateGroupViewController: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        emojis.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell",
                                                      for: indexPath) as! EmojiCell
        let emoji = emojis[indexPath.item]
        cell.configure(emoji, isSelected: emoji == selectedEmoji)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = emojis[indexPath.item]
        selectedEmoji = (selectedEmoji == emoji) ? nil : emoji
        collectionView.reloadData()
        applyButtonState()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 4
        let spacing: CGFloat = 12 * (columns - 1)
        let width = (collectionView.bounds.width - spacing) / columns
        return CGSize(width: width, height: width)
    }
}

private extension UITextField {
    func setLeftPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.height))
        leftView = paddingView
        leftViewMode = .always
    }
    func setRightPaddingPoints(_ amount: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: amount, height: frame.height))
        rightView = paddingView
        rightViewMode = .always
    }
}
