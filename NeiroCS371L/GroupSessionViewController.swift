//
//  GroupSessionViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit

final class GroupSessionViewController: UIViewController {

    private let playlist: Playlist?
    private let mix: [EmojiBreakdown]
    
    private let tableView = UITableView()
    private let headerLabel = UILabel()

    // We now accept an optional Playlist (containing the real songs)
    init(playlist: Playlist?, mix: [EmojiBreakdown]) {
        self.playlist = playlist
        self.mix = mix
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = playlist?.title ?? "Group Vibe Check"
        
        // Prevent going back to Lobby (it's closed)
        //navigationItem.hidesBackButton = true
        // Add custom "Leave" button
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Leave Session", style: .done, target: self, action: #selector(leaveTapped))
        
        configureUI()
    }
    
    @objc private func leaveTapped() {
        // Pop back to the very beginning (Main Menu)
        navigationController?.popToRootViewController(animated: true)
    }
    
    private func configureUI() {
        // Header Text
        if let _ = playlist {
            headerLabel.text = "Here is your generated playlist!"
        } else {
            headerLabel.text = "Spotify not connected.\nHere is your vibe breakdown:"
        }
        
        headerLabel.font = .systemFont(ofSize: 20, weight: .bold)
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        
        view.addSubview(headerLabel)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            headerLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            headerLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            tableView.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 20),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}

extension GroupSessionViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let playlist = playlist {
            return playlist.songs.count
        } else {
            return mix.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        var content = cell.defaultContentConfiguration()
        
        if let playlist = playlist {
            // SHOW REAL SONGS
            let song = playlist.songs[indexPath.row]
            content.text = song.title
            content.secondaryText = song.artist
            content.image = UIImage(systemName: "music.note")
        } else {
            // SHOW STATS (Fallback for Simulator)
            let item = mix[indexPath.row]
            content.text = "\(item.emoji) Vibe"
            content.secondaryText = "\(item.songCount) Songs calculated"
            content.textProperties.font = .systemFont(ofSize: 20)
        }
        
        cell.contentConfiguration = content
        return cell
    }
}
