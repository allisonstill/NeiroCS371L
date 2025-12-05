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
        
        updateUIState()
        
        // SYNC LISTENER
        GroupManager.shared.listenToGroup(code: group.sessionCode) { [weak self] updatedGroup in
            guard let self = self else { return }
            self.group = updatedGroup
            self.tableView.reloadData()
            self.updateUIState()
            
            // Navigate if session started AND we have the playlist
            if updatedGroup.status == "started" {
                self.navigateToSession()
            }
        }
    }
    
    private func updateUIState() {
        sessionCodeLabel.text = "Code: \(group.sessionCode)"
        
        let me = myMember
        let isHost = me?.isHost ?? false
        let isReady = me?.isReady ?? false
        
        if isHost {
            // HOST LOGIC
            let others = group.members.filter { !$0.isHost }
            let allOthersReady = others.allSatisfy { $0.isReady } && !others.isEmpty
            
            if allOthersReady {
                actionButton.setTitle("Generate", for: .normal)
                actionButton.backgroundColor = .systemGreen
                actionButton.isEnabled = true
                actionButton.alpha = 1.0
            } else {
                let count = others.filter({ !$0.isReady }).count
                actionButton.setTitle("Waiting for \(count)...", for: .normal)
                actionButton.backgroundColor = .systemGray
                actionButton.isEnabled = false
                actionButton.alpha = 0.6
            }
            
        } else {
            // GUEST LOGIC
            actionButton.isEnabled = true
            actionButton.alpha = 1.0
            if isReady {
                actionButton.setTitle("Ready! (Tap to Undo)", for: .normal)
                actionButton.backgroundColor = .systemGreen
            } else {
                actionButton.setTitle("I'm Ready", for: .normal)
                actionButton.backgroundColor = .systemBlue
            }
        }
    }

    @objc private func actionTapped() {
        guard let me = myMember else { return }
        
        if me.isHost {
            // HOST STARTS GENERATION
            startGenerationProcess()
        } else {
            // GUEST TOGGLES READY
            let newState = !me.isReady
            GroupManager.shared.updateMyState(code: group.sessionCode, emoji: me.emoji, isReady: newState)
        }
    }
    
    // MARK: - Generation Logic (Host Only)
    private func startGenerationProcess() {
        let playlistMix = calculatePlaylistMix(group: group, totalSongsInPlaylist: 20)
        
        guard SpotifyUserAuthorization.shared.isConnected else {
            // Fallback: Start session with NO songs (stats only)
            print("⚠️ Spotify not connected. Starting stats-only session.")
            GroupManager.shared.startSessionWithSongs(code: group.sessionCode, songs: [])
            return
        }
        
        let alert = UIAlertController(title: "Generating...", message: "Mixing the group's vibe...", preferredStyle: .alert)
        present(alert, animated: true)
        
        PlaylistGenerator.shared.generateMixedPlaylist(from: playlistMix, on: self) { [weak self] result in
            DispatchQueue.main.async {
                alert.dismiss(animated: true)
                guard let self = self else { return }
                
                switch result {
                case .success(let playlist):
                    print("✅ Generated \(playlist.songs.count) songs.")
                    
                    // 1. Rename Playlist to include Host Name
                    let hostName = self.group.members.first(where: { $0.isHost })?.name ?? "Group"
                    playlist.title = "\(hostName) Group Playlist"
                    
                    // 2. Save to Host's Personal History immediately
                    PlaylistLibrary.addPlaylist(playlist) { _ in
                        // Notify Home Screen to refresh
                        NotificationCenter.default.post(name: .lastOpenedPlaylistDidChange, object: nil)
                    }
                    
                    // 3. Save to Firebase Group Data -> Triggers Listener for everyone
                    GroupManager.shared.startSessionWithSongs(code: self.group.sessionCode, songs: playlist.songs)
                    
                case .failure(let error):
                    print("❌ Generation failed: \(error). Starting stats-only.")
                    GroupManager.shared.startSessionWithSongs(code: self.group.sessionCode, songs: [])
                }
            }
        }
    }
    
    // MARK: - Navigation (Listener Triggered)
    private func navigateToSession() {
        GroupManager.shared.stopListening()
        
        let playlistMix = calculatePlaylistMix(group: group, totalSongsInPlaylist: 20)
        
        var finalPlaylist: Playlist? = nil
        
        // Use the shared songs from the database!
        if let sharedSongs = group.sharedSongs, !sharedSongs.isEmpty {
            
            // Reconstruct the playlist
            let hostName = group.members.first(where: { $0.isHost })?.name ?? "Group"
            let title = "\(hostName) Group Playlist"
            
            finalPlaylist = Playlist(
                title: title,
                emoji: "✨",
                createdAt: Date(),
                songs: sharedSongs,
                gradientColors: [UIColor.systemPurple, UIColor.systemBlue]
            )
            
            // If I am NOT the host, save this to my history now
            // (Host already saved it during generation)
            if let me = myMember, !me.isHost, let playlistToSave = finalPlaylist {
                PlaylistLibrary.addPlaylist(playlistToSave) { _ in
                    NotificationCenter.default.post(name: .lastOpenedPlaylistDidChange, object: nil)
                }
            }
        }
        
        let sessionVC = GroupSessionViewController(playlist: finalPlaylist, mix: playlistMix)
        navigationController?.pushViewController(sessionVC, animated: true)
    }
    
    @objc private func leaveTapped() {
        GroupManager.shared.stopListening()
        GroupManager.shared.leaveGroup(code: group.sessionCode) { [weak self] in
            DispatchQueue.main.async {
                self?.navigationController?.popViewController(animated: true)
            }
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
