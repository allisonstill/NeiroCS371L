//
//  GroupSessionViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit

final class GroupSessionViewController: UIViewController {

    private let mix: [EmojiBreakdown]
    private let tableView = UITableView()
    private let headerLabel = UILabel()

    init(mix: [EmojiBreakdown]) {
        self.mix = mix
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Group Playlist"
        navigationItem.hidesBackButton = true // Can't go back to waiting room
        
        configureUI()
    }
    
    private func configureUI() {
        headerLabel.text = "Here is your group's vibe mix:"
        headerLabel.font = .systemFont(ofSize: 22, weight: .bold)
        headerLabel.textAlignment = .center
        headerLabel.numberOfLines = 0
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        tableView.tableFooterView = UIView() // Hide empty lines
        
        view.addSubview(headerLabel)
        view.addSubview(tableView)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
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
        return mix.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let item = mix[indexPath.row]
        
        var content = cell.defaultContentConfiguration()
        content.text = "\(item.emoji) Vibe"
        content.secondaryText = "\(item.songCount) Songs"
        content.textProperties.font = .systemFont(ofSize: 24)
        content.secondaryTextProperties.font = .systemFont(ofSize: 18, weight: .semibold)
        content.secondaryTextProperties.color = .systemBlue
        
        cell.contentConfiguration = content
        return cell
    }
}
