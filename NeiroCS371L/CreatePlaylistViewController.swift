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
    
    // adding new playlist button (to gray out)
    private let createButton = UIButton(type: .system)

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
            collectionView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6) // updated to take up more space now that we only have one button
        ])
    }

    //only button is for creating the playlist based on a single emoji
    private func setupButtons() {
        var config = UIButton.Configuration.filled()
        config.title = "Create Playlist"
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        createButton.configuration = config
        createButton.isEnabled = true
        
        //will be shown when the user has selected an emoji
        createButton.isHidden = true
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createButton)
        NSLayoutConstraint.activate([
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            createButton.leadingAnchor.constraint(equalTo:view.leadingAnchor, constant: 24),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    
    //create button was pressed (pick an emoji to generate a playlist)
    @objc private func createTapped() {
        guard let emoji = selectedEmoji else {
            showAlert(title: "Pick an emoji", message: "Choose a mood to create a playlist.")
            return
        }
        
        //show existing playlist if the same emoji is selected
        if let existing = PlaylistGenerator.shared.existingPlaylist(for: emoji) {
            let detailVC = PlaylistDetailViewController()
            detailVC.playlist = existing
            detailVC.isNewPlaylist = true
            navigationController?.pushViewController(detailVC, animated: true)
            return
        }
        
        // Generate a playlist based on this emoji
        generatePlaylistFromSpotify(for: emoji)
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
    
    private func checkSpotifyConnection() {
        PlaylistGenerator.checkSpotifyConnection(on: self)
    }

    // MARK: Actions

    private func handleEmojiSelection(_ emoji: String) {
        guard emoji != "➕" else {
            showAlert(title: "Coming Soon", message: "Not yet implemented")
            return
        }
        
        //show create button
        UIView.animate(withDuration: 0.3){
            self.createButton.isHidden = false
        }
    }
    
    
    
    private func generatePlaylistFromSpotify(for emoji: String) {
        guard PlaylistGenerator.checkSpotifyConnection(on: self) else {return}
        
        
        PlaylistGenerator.shared.generatePlaylistFromSpotify(for: emoji, activityIndicator: activityIndicator, on: self) { [weak self] result in
            
            guard let self = self else {return}
            
            switch result {
            case .success(let playlist):
                self.saveAndShowPlaylist(playlist)
                
            case .failure(let error):
                PlaylistGenerator.showAlert(on: self, title: "Error", message: "We were not able to generate a playlist: \(error.localizedDescription)")
            }
        }
    }
    
    private func saveAndShowPlaylist(_ playlist: Playlist) {
        PlaylistGenerator.shared.savePlaylist(playlist, activityIndicator: activityIndicator) { [weak self] success in
        
            guard let self = self else {return}
            if success {
                self.onCreate?(playlist)
            }
            let detailVC = PlaylistDetailViewController()
            detailVC.playlist = playlist
            detailVC.isNewPlaylist = true
            self.navigationController?.pushViewController(detailVC, animated: true)
            
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
        if selectedEmoji == emoji {
            selectedEmoji = nil
            createButton.isHidden = true
        } else {
            selectedEmoji = emoji
            handleEmojiSelection(emoji)
        }
        collectionView.reloadData()
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
