//
//  GroupHostViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit

final class GroupHostViewController: UIViewController {

    private var group: LocalGroup
    private let tableView = UITableView()
    private let headerLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let sessionCodeLabel = UILabel()
    private let copyButton = UIButton(type: .system)

    init(group: LocalGroup) {
        self.group = group
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = ThemeColor.Color.backgroundColor
        title = group.name
        navigationItem.largeTitleDisplayMode = .never

        addMockMembersIfNeeded()
        configureHeader()
        configureTableView()
        configureStartButton()
        layoutUI()
        configureSessionCode()
    }

    private func addMockMembersIfNeeded() {
        guard group.members.count == 1 else { return }

        let mockNames = ["Alex", "Taylor", "Jordan"]
        let emojiPool = ["😀","😭","😍","😎","🤪","😌","⚡️","❤️"].shuffled()

        var newMembers = group.members

        for (index, name) in mockNames.enumerated() {
            let member = GroupMember(
                id: UUID(),
                name: name,
                emoji: emojiPool[index % emojiPool.count],
                isHost: false
            )
            newMembers.append(member)
        }
        group.members = newMembers
    }

    private func configureHeader() {
        headerLabel.translatesAutoresizingMaskIntoConstraints = false
        headerLabel.text = "People in this session"
        headerLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        headerLabel.textColor = .white
    }

    private func configureTableView() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(GroupMemberCell.self, forCellReuseIdentifier: "GroupMemberCell")
    }

    private func configureStartButton() {
        startButton.translatesAutoresizingMaskIntoConstraints = false
        startButton.setTitle("Start Group Session", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        startButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 14
        startButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)
    }

    private func layoutUI() {
        let stack = UIStackView(arrangedSubviews: [
            sessionCodeLabel,
            copyButton,
            headerLabel,
            tableView,
            startButton
        ])
        stack.axis = .vertical
        stack.spacing = 16
        stack.alignment = .fill

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
        ])
    }
    
    private func configureSessionCode() {
        sessionCodeLabel.translatesAutoresizingMaskIntoConstraints = false
        sessionCodeLabel.text = "Session Code: \(group.sessionCode)"
        sessionCodeLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        sessionCodeLabel.textColor = .white
        sessionCodeLabel.textAlignment = .center

        copyButton.translatesAutoresizingMaskIntoConstraints = false
        copyButton.setTitle("Copy Code", for: .normal)
        copyButton.titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        copyButton.tintColor = .white
        copyButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        copyButton.layer.cornerRadius = 10
        copyButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        copyButton.addTarget(self, action: #selector(copyCode), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func startTapped() {
        let sessionVC = GroupSessionViewController(group: group)
        navigationController?.pushViewController(sessionVC, animated: true)
    }
    
    @objc private func copyCode() {
        UIPasteboard.general.string = group.sessionCode
        let alert = UIAlertController(title: "Copied",
                                      message: "Session code copied to clipboard.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Table DataSource

extension GroupHostViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        group.members.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupMemberCell",
                                                 for: indexPath) as! GroupMemberCell
        let member = group.members[indexPath.row]
        cell.configure(with: member)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        64
    }
}

// MARK: - Cell

final class GroupMemberCell: UITableViewCell {

    private let emojiLabel = UILabel()
    private let nameLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let stack = UIStackView()
    private let container = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureUI() {
        backgroundColor = .clear
        selectionStyle = .none

        container.translatesAutoresizingMaskIntoConstraints = false
        container.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.6)
        container.layer.cornerRadius = 14
        contentView.addSubview(container)

        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.font = .systemFont(ofSize: 30)

        nameLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        nameLabel.textColor = .white

        subtitleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        subtitleLabel.textColor = .white.withAlphaComponent(0.7)

        stack.axis = .vertical
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.addArrangedSubview(nameLabel)
        stack.addArrangedSubview(subtitleLabel)

        container.addSubview(emojiLabel)
        container.addSubview(stack)

        NSLayoutConstraint.activate([
            container.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            container.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4),
            container.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4),

            emojiLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 14),
            emojiLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 40),

            stack.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 10),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -14),
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
    }

    func configure(with member: GroupMember) {
        emojiLabel.text = member.emoji
        nameLabel.text = member.name
        subtitleLabel.text = member.isHost ? "Host" : "Member"
    }
}
