//
//  GroupHostViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit

final class GroupHostViewController: UIViewController {

    var group: LocalGroup
    
    private let sessionCodeLabel = UILabel()
    private let tableView = UITableView()
    private let actionButton = UIButton(type: .system)
    private let changeEmojiButton = UIButton(type: .system)
    
    private let emojiOptions = [
        "😀", "😎", "🥲", "😭",
        "🤪", "🤩", "😴", "😐",
        "😌", "🙂", "🙃", "😕",
        "🔥", "❤️", "⚡️", "💀"
    ]
    
    var myMember: GroupMember? {
        return group.members.first(where: { $0.id == GroupManager.shared.currentUserId })
    }

    init(group: LocalGroup) {
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Leave", style: .plain, target: self, action: #selector(leaveTapped))
        
        configureUI()
        layoutUI()
        
        // SYNC
        GroupManager.shared.listenToGroup(code: group.sessionCode) { [weak self] updatedGroup in
            guard let self = self else { return }
            self.group = updatedGroup
            self.tableView.reloadData()
            self.updateUIState()
            self.checkAutoStart()
            
            if updatedGroup.status == "started" {
                self.navigateToSession()
            }
        }
    }
    
    private func updateUIState() {
        sessionCodeLabel.text = "Code: \(group.sessionCode)"
        
        guard let me = myMember else { return }
        
        // BUTTON IS ALWAYS ENABLED
        actionButton.isEnabled = true
        
        if me.isReady {
            actionButton.setTitle("Ready! (Tap to Undo)", for: .normal)
            actionButton.backgroundColor = .systemGreen
        } else {
            actionButton.setTitle("I'm Ready", for: .normal)
            actionButton.backgroundColor = .systemBlue
        }
    }
    
    private func checkAutoStart() {
        guard let me = myMember, me.isHost else { return }
        let allReady = group.members.allSatisfy { $0.isReady }
        
        if allReady && group.status == "waiting" {
            GroupManager.shared.startSession(code: group.sessionCode)
        }
    }

    @objc private func actionTapped() {
        guard let me = myMember else { return }
        let newState = !me.isReady
        GroupManager.shared.updateMyState(code: group.sessionCode, emoji: me.emoji, isReady: newState)
    }
    
    @objc private func leaveTapped() {
        GroupManager.shared.leaveGroup(code: group.sessionCode) {
            GroupManager.shared.stopListening()
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    @objc private func changeEmojiTapped() {
        let pickerVC = UIViewController()
        pickerVC.view.backgroundColor = .systemBackground
        if let sheet = pickerVC.sheetPresentationController {
            sheet.detents = [.medium()]
        }
        
        let gridStack = UIStackView()
        gridStack.axis = .vertical
        gridStack.distribution = .fillEqually
        gridStack.spacing = 10
        gridStack.translatesAutoresizingMaskIntoConstraints = false
        pickerVC.view.addSubview(gridStack)
        
        var index = 0
        for _ in 0..<4 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 10
            for _ in 0..<4 {
                if index < emojiOptions.count {
                    let emoji = emojiOptions[index]
                    let btn = UIButton(type: .system)
                    btn.setTitle(emoji, for: .normal)
                    btn.titleLabel?.font = .systemFont(ofSize: 30)
                    btn.backgroundColor = .secondarySystemBackground
                    btn.layer.cornerRadius = 8
                    
                    let action = UIAction { [weak self, weak pickerVC] _ in
                        guard let self = self, let me = self.myMember else { return }
                        GroupManager.shared.updateMyState(code: self.group.sessionCode, emoji: emoji, isReady: me.isReady)
                        pickerVC?.dismiss(animated: true)
                    }
                    btn.addAction(action, for: .touchUpInside)
                    rowStack.addArrangedSubview(btn)
                    index += 1
                }
            }
            gridStack.addArrangedSubview(rowStack)
        }
        
        NSLayoutConstraint.activate([
            gridStack.centerXAnchor.constraint(equalTo: pickerVC.view.centerXAnchor),
            gridStack.centerYAnchor.constraint(equalTo: pickerVC.view.centerYAnchor),
            gridStack.widthAnchor.constraint(equalTo: pickerVC.view.widthAnchor, constant: -40),
            gridStack.heightAnchor.constraint(equalToConstant: 300)
        ])
        
        present(pickerVC, animated: true)
    }
    
    private func navigateToSession() {
        GroupManager.shared.stopListening()
        // Ensure you have PlaylistLogic.swift or the function helper
        let playlistMix = calculatePlaylistMix(group: group, totalSongsInPlaylist: 20)
        let sessionVC = GroupSessionViewController(mix: playlistMix)
        navigationController?.pushViewController(sessionVC, animated: true)
    }
    
    private func configureUI() {
        sessionCodeLabel.textAlignment = .center
        sessionCodeLabel.font = .systemFont(ofSize: 28, weight: .heavy)
        
        actionButton.layer.cornerRadius = 14
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 18)
        actionButton.setTitleColor(.white, for: .normal)
        actionButton.addTarget(self, action: #selector(actionTapped), for: .touchUpInside)
        
        changeEmojiButton.setTitle("Change Emoji", for: .normal)
        changeEmojiButton.backgroundColor = .secondarySystemBackground
        changeEmojiButton.setTitleColor(.label, for: .normal)
        changeEmojiButton.layer.cornerRadius = 14
        changeEmojiButton.addTarget(self, action: #selector(changeEmojiTapped), for: .touchUpInside)
        
        tableView.dataSource = self
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "Cell")
    }
    
    private func layoutUI() {
        let stack = UIStackView(arrangedSubviews: [sessionCodeLabel, tableView, changeEmojiButton, actionButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            actionButton.heightAnchor.constraint(equalToConstant: 52),
            changeEmojiButton.heightAnchor.constraint(equalToConstant: 52)
        ])
    }
}

extension GroupHostViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { group.members.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! GroupMemberCell
        cell.configure(with: group.members[indexPath.row])
        return cell
    }
    
    final class GroupMemberCell: UITableViewCell {
        override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
            super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
            backgroundColor = .clear
            selectionStyle = .none
        }
        required init?(coder: NSCoder) { fatalError() }
        
        func configure(with member: GroupMember) {
            let ready = member.isReady ? "✅ Ready" : "⏳"
            let host = member.isHost ? "👑" : ""
            textLabel?.text = "\(member.emoji) \(member.name) \(host)"
            detailTextLabel?.text = ready
        }
    }
}
