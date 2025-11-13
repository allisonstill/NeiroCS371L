//
//  GroupSessionViewController.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import UIKit

final class GroupSessionViewController: UIViewController {

    private var group: LocalGroup

    private let emojiLabel = UILabel()
    private let titleLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let generateButton = UIButton(type: .system)
    private let activityIndicator = UIActivityIndicatorView(style: .large)

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
        title = "Group Jam"
        navigationItem.largeTitleDisplayMode = .never

        configureLabels()
        configureButton()
        configureActivityIndicator()
        layoutUI()
        updateForConsensus()
    }

    private func configureLabels() {
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.font = .systemFont(ofSize: 72)
        emojiLabel.textAlignment = .center

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center

        descriptionLabel.translatesAutoresizingMaskIntoConstraints = false
        descriptionLabel.font = .systemFont(ofSize: 15)
        descriptionLabel.textColor = .white.withAlphaComponent(0.8)
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textAlignment = .center
    }

    private func configureButton() {
        generateButton.translatesAutoresizingMaskIntoConstraints = false
        generateButton.setTitle("Generate Group Playlist", for: .normal)
        generateButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        generateButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        generateButton.setTitleColor(.white, for: .normal)
        generateButton.layer.cornerRadius = 14
        generateButton.heightAnchor.constraint(equalToConstant: 52).isActive = true
        generateButton.addTarget(self, action: #selector(generateTapped), for: .touchUpInside)
    }

    private func configureActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
    }

    private func layoutUI() {
        let stack = UIStackView(arrangedSubviews: [emojiLabel, titleLabel, descriptionLabel, generateButton])
        stack.axis = .vertical
        stack.spacing = 18
        stack.alignment = .fill

        view.addSubview(stack)
        view.addSubview(activityIndicator)

        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -40),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),

            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 24)
        ])
    }

    private func updateForConsensus() {
        let consensusEmoji = computeConsensusEmoji()
        emojiLabel.text = consensusEmoji
        titleLabel.text = "Group Mood: \(consensusEmoji)"

        let memberCount = group.members.count
        descriptionLabel.text = "\(memberCount) people picked emojis. We’ll generate a playlist based on the group mood."
    }

    private func computeConsensusEmoji() -> String {
        guard !group.members.isEmpty else { return "🎵" }

        var counts: [String: Int] = [:]
        for member in group.members {
            counts[member.emoji, default: 0] += 1
        }

        // most common emoji; if tie, prefer host's emoji
        let hostEmoji = group.members.first(where: { $0.isHost })?.emoji

        let maxCount = counts.values.max() ?? 1
        var candidates = counts.filter { $0.value == maxCount }.map { $0.key }

        if let hostEmoji = hostEmoji, candidates.contains(hostEmoji) {
            return hostEmoji
        }
        candidates.sort()
        return candidates.first ?? "🎵"
    }

    // MARK: - Generate playlist

    @objc private func generateTapped() {
        guard SpotifyUserAuthorization.shared.isConnected else {
            showAlert(title: "Connect Spotify", message: "Please connect Spotify in Settings to generate a playlist.")
            return
        }

        let emoji = computeConsensusEmoji()
        startLoading()

        let settings = SpotifySettings.shared
        let targetCount = settings.playlistLength.songCount
        let excludedGenres = settings.excludedGenres

        SpotifyAPI.shared.generatePlaylist(
            for: emoji,
            targetSongCount: targetCount,
            excludedGenres: excludedGenres
        ) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                self.stopLoading()
                switch result {
                case .success(let songs):
                    self.showPlaylist(for: emoji, songs: songs)
                case .failure(let error):
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func startLoading() {
        generateButton.isEnabled = false
        generateButton.setTitle("Generating…", for: .normal)
        activityIndicator.startAnimating()
    }

    private func stopLoading() {
        generateButton.isEnabled = true
        generateButton.setTitle("Generate Group Playlist", for: .normal)
        activityIndicator.stopAnimating()
    }

    private func showPlaylist(for emoji: String, songs: [Song]) {
        let gradientColors = generateGradientColors(from: emoji)
        let playlist = Playlist(
            title: "Group \(emoji) Playlist",
            emoji: emoji,
            createdAt: Date(),
            songs: songs,
            gradientColors: gradientColors
        )

        PlaylistLibrary.addPlaylist(playlist) { success in
            print("Group playlist saved locally + Firebase: \(success)")
        }

        let detailVC = PlaylistDetailViewController()
        detailVC.playlist = playlist
        detailVC.isNewPlaylist = true
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func generateGradientColors(from emoji: String) -> [UIColor] {
        let hash = emoji.hashValue
        let firstHue = CGFloat((hash & 0xFF)) / 255.0
        let secondHue = CGFloat(((hash >> 8) & 0xFF)) / 255.0

        let firstColor = UIColor(hue: firstHue, saturation: 0.6, brightness: 0.5, alpha: 1.0)
        let secondColor = UIColor(hue: secondHue, saturation: 0.6, brightness: 0.3, alpha: 1.0)

        return [firstColor, secondColor]
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
