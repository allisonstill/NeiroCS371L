//
//  CreatePlaylistViewController.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 10/20/25.
//

import UIKit

final class CreatePlaylistViewController: UIViewController {

    // Callback to return a new playlist to the list VC
    var onCreate: ((Playlist) -> Void)?

    // Easily editable emoji set
    var emojis: [String] = ["😀","😎","🥲","😭",
                            "🤪","🤩","😴","😐",
                            "😌","🙂","🙃","😕",
                            "🔥","❤️","⚡️","➕"]

    private var collectionView: UICollectionView!
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    private var selectedEmoji: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create Playlist"
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupCollection()
        setupButtons()
        setupActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkSpotifyConnection()
    }

    private func setupCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 16, bottom: 8, right: 16)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.register(EmojiCell.self, forCellWithReuseIdentifier: "EmojiCell")
        collectionView.delegate = self
        collectionView.dataSource = self

        view.addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.45)
        ])
    }

    private func setupButtons() {
        let makeRandom = primaryButton("Select Random Playlist Mood")
        makeRandom.addTarget(self, action: #selector(randomTapped), for: .touchUpInside)

        let describe = secondaryButton("Describe Your Own Playlist")
        describe.addTarget(self, action: #selector(describeTapped), for: .touchUpInside)

        let stack = UIStackView(arrangedSubviews: [makeRandom, describe])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill

        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: collectionView.bottomAnchor, constant: 20),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .white
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
    }

    private func primaryButton(_ title: String) -> UIButton {
        let button = UIButton(type: .system)
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.title = title
            config.baseBackgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
            config.baseForegroundColor = .label
            config.cornerStyle = .medium
            config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var attrs = incoming
                attrs.font = .systemFont(ofSize: 16, weight: .semibold)
                return attrs
            }
            button.configuration = config
            button.layer.cornerRadius = 12
            button.layer.masksToBounds = true
        } else {
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
            button.layer.cornerRadius = 12
            button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 14, bottom: 12, right: 14)
        }
        return button
    }

    private func secondaryButton(_ title: String) -> UIButton {
        let b = primaryButton(title)
        
        if #available(iOS 15.0, *) {
            if var config = b.configuration {
                config.baseBackgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.7)
                b.configuration = config
            }
        } else {
            b.backgroundColor = UIColor.tertiarySystemBackground.withAlphaComponent(0.7)
        }
        return b
    }
    
    private func checkSpotifyConnection() {
        guard !SpotifyUserAuthorization.shared.isConnected else { return }
        showAlert(title: "Connect Spotify", message: "To generate playlists, please connect Spotify account!")
    }

    // MARK: Actions
    @objc private func randomTapped() {
        guard let random = emojis.filter({ $0 != "➕" }).randomElement() else { return }
    
            selectedEmoji = random
            collectionView.reloadData()
            handleEmojiSelection(random)
    }

    @objc private func describeTapped() {
        // placeholder for text/AI prompt integration later
        showAlert(title: "Coming Soon", message: "Not yet implemented.")
    }

    private func handleEmojiSelection(_ emoji: String) {
        guard emoji != "➕" else {
            showAlert(title: "Coming Soon", message: "Not yet implemented")
            return
        }
        
        //check if playlist already exists
        let existingPlaylists = PlaylistLibrary.playlists(for: emoji)
        if let existing = existingPlaylists.first {
            navigateToPlaylistDetail(playlist: existing, isNew: true)
            return
        }

        //generate new playlist
        generatePlaylistFromSpotify(for: emoji)
    }
    
    
    
    private func generatePlaylistFromSpotify(for emoji: String) {
        guard SpotifyUserAuthorization.shared.isConnected else {
            showAlert(title: "Not Connected", message: "Please Connect Spotify Account.")
            return
        }
        
        activityIndicator.startAnimating()
        view.isUserInteractionEnabled = false
        
        // get settings from Spotify Settings
        let settings = SpotifySettings.shared
        let targetCount = settings.playlistLength.songCount
        let excludedGenres = settings.excludedGenres
        
        SpotifyAPI.shared.generatePlaylist(
            for: emoji,
            targetSongCount: targetCount,
            excludedGenres: excludedGenres) { [weak self] result in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.view.isUserInteractionEnabled = true
                
                self?.handlePlaylistGenerationRes(result, emoji: emoji)
            }
        }
    }
    
    private func handlePlaylistGenerationRes(_ result: Result<[Song], Error>, emoji: String) {
        switch result {
        case .success(let songs):
            createAndShowPlaylist(emoji: emoji, songs: songs)
        case .failure(let error):
            showAlert(title: "Error", message: "Didn't generate playlist: \(error.localizedDescription)")
        }
    }
    
    private func createAndShowPlaylist(emoji: String, songs: [Song]) {
        let playlistName = getPlaylistName(for: emoji)
        let gradientColors = generateGradientColors(from: emoji)
        let playlist = Playlist(
            title: playlistName,
            emoji: emoji,
            createdAt: Date(),
            songs: songs,
            gradientColors: gradientColors
        )
        
        PlaylistLibrary.addPlaylist(playlist) { [weak self] success in
            DispatchQueue.main.async {
                if success {
                    print("Playlist added and saved to Firebase")
                    self?.onCreate?(playlist)
                }
                
                self?.navigateToPlaylistDetail(playlist: playlist, isNew: true)
                
                if SpotifySettings.shared.autoExportToSpotify {
                    self?.exportToSpotify(playlist: playlist)
                }
            }
        }
    }
    
    private func navigateToPlaylistDetail(playlist: Playlist, isNew: Bool) {
        let detailVC = PlaylistDetailViewController()
        detailVC.playlist = playlist
        detailVC.isNewPlaylist = isNew
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    //generate gradient colors (UI purposes)
    private func generateGradientColors(from emoji: String) -> [UIColor] {
        let hash = emoji.hashValue
        let firstHue = CGFloat((hash & 0xFF)) / 255.0
        let secondHue = CGFloat(((hash >> 8) & 0xFF)) / 255.0
        
        let firstColor = UIColor(hue: firstHue, saturation: 0.6, brightness: 0.5, alpha: 1.0)
        let secondColor = UIColor(hue: secondHue, saturation: 0.6, brightness: 0.3, alpha: 1.0)
        
        return [firstColor, secondColor]
    }
    
    //TODO: generate playlist names based on the emoji
    private func getPlaylistName(for emoji: String) -> String {
        return "New \(emoji) Playlist"
    }
    
    private func exportToSpotify(playlist: Playlist) {
        activityIndicator.startAnimating()
        
        SpotifyAPI.shared.exportPlaylist(playlist: playlist) { [weak self] result in
            
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                
                switch result {
                case .success(let url):
                    print("Playlist exported to \(url)")
                case .failure(let error):
                    print("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Collection
extension CreatePlaylistViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { emojis.count }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EmojiCell", for: indexPath) as! EmojiCell
        let emoji = emojis[indexPath.item]
        cell.configure(emoji, isSelected: emoji == selectedEmoji)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let columns: CGFloat = 4
        let spacing: CGFloat = 12 * (columns + 1)
        let width = (collectionView.bounds.width - spacing) / columns
        return CGSize(width: width, height: width)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let emoji = emojis[indexPath.item]
        selectedEmoji = emoji
        collectionView.reloadData()
        handleEmojiSelection(emoji)
    }
}

// MARK: - Emoji Cell
final class EmojiCell: UICollectionViewCell {
    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.layer.cornerRadius = 14
        contentView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)

        label.font = .systemFont(ofSize: 28)
        label.textAlignment = .center
        contentView.addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func configure(_ emoji: String, isSelected: Bool = false) {
        label.text = emoji
        if isSelected {
            contentView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
            contentView.layer.borderWidth = 2
            contentView.layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            contentView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.7)
            contentView.layer.borderWidth = 0
            contentView.layer.borderColor = UIColor.clear.cgColor
        }
    }
}
