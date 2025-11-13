//
//  RandomEmojiViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/12/25.
//

import UIKit

class RandomEmojiViewController: UIViewController {
    
    // Callback to return a new playlist to the list VC
    var onCreate: ((Playlist) -> Void)?
    
    private var selectedEmoji: String?
    
    // array of emojis available for 'random' selection
    var emojis: [String] = ["😀","😎","🥲","😭",
                            "🤪","🤩","😴","😐",
                            "😌","🙂","🙃","😕",
                            "🔥","❤️","⚡️"]
    
    private var shakePhoneLabel = UILabel()
    private var shakePhoneImageView = UIImageView()
    private var chosenEmojiLabel = UILabel()
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    private var createButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Random Emoji Playlist"
        view.backgroundColor = ThemeColor.Color.backgroundColor
        setupScreen()
        setupActivityIndicator()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkSpotifyConnection()
    }
    
    private func setupScreen() {
        //shake phone image
        shakePhoneImageView.image = UIImage(systemName: "iphone.radiowaves.left.and.right")
        shakePhoneImageView.contentMode = .scaleAspectFit
        shakePhoneImageView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shakePhoneImageView)
        
        //instructions label to tell user to shake their phone
        shakePhoneLabel.text = "Shake your phone to select\n a random emoji!"
        shakePhoneLabel.numberOfLines = 0
        shakePhoneLabel.textAlignment = .center
        shakePhoneLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        shakePhoneLabel.textColor = .white
        shakePhoneLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(shakePhoneLabel)
        
        //label that will show emoji when phone is shaken
        chosenEmojiLabel.font = .systemFont(ofSize: 80)
        chosenEmojiLabel.textAlignment = .center
        chosenEmojiLabel.isHidden = true
        chosenEmojiLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chosenEmojiLabel)
        
        //create button
        var config = UIButton.Configuration.filled()
        config.title = "Create Playlist"
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        createButton.configuration = config
        createButton.addTarget(self, action: #selector(createTapped), for: .touchUpInside)
        createButton.isHidden = true
        createButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createButton)
        
        NSLayoutConstraint.activate([
            
            //image representing shaking phone
            shakePhoneImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            shakePhoneImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            shakePhoneImageView.widthAnchor.constraint(equalToConstant: 100),
            shakePhoneImageView.heightAnchor.constraint(equalToConstant: 100),
            
            //instructions to shake phone
            shakePhoneLabel.topAnchor.constraint(equalTo: shakePhoneImageView.bottomAnchor, constant: 24),
            shakePhoneLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            shakePhoneLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            //emoji label that will show up when phone is shaken
            chosenEmojiLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            chosenEmojiLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: 75),
            
            //create button near bottom of screen
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -32),
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            createButton.heightAnchor.constraint(equalToConstant: 50)
            
            
        ])
        
    }
    
    private func setupActivityIndicator() {
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.hidesWhenStopped = true
        view.addSubview(activityIndicator)
        
        NSLayoutConstraint.activate([
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
            
        ])
    }
    
    //if the user shakes the phone, pick a random emoji
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            selectRandomEmoji()
        }
    }
    
    //select random emoji from list of possible emojis
    private func selectRandomEmoji() {
        guard let randomEmoji = emojis.randomElement() else { return }
        selectedEmoji = randomEmoji
        
        chosenEmojiLabel.text = randomEmoji
        
        //show the chosen emoji
        UIView.animate(withDuration: 0.5, delay: 0, options: .curveEaseOut) {
            self.chosenEmojiLabel.isHidden = false
        }
        
        //show the create button (must have the emoji selected)
        UIView.animate(withDuration: 0.3, delay: 0.2, options: .curveEaseOut) {
            self.createButton.isHidden = false
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    //just calls playlistgenerator's checkSpotifyConnection
    private func checkSpotifyConnection() {
        PlaylistGenerator.checkSpotifyConnection(on: self)
    }
    
    //selector action for if the create button is pressed
    @objc private func createTapped() {
        guard let emoji = selectedEmoji else {return}
        if let existing = PlaylistGenerator.shared.existingPlaylist(for: emoji) {
            let detailVC = PlaylistDetailViewController()
            detailVC.playlist = existing
            detailVC.isNewPlaylist = true
            navigationController?.pushViewController(detailVC, animated: true)
            return
        }
        generatePlaylistFromSpotify(for: emoji)
    }
    
    //generate playlist
    //rely on PlaylistGenerator's generate playlist, but show alert if it doesn't work
    private func generatePlaylistFromSpotify(for emoji: String) {
        guard PlaylistGenerator.checkSpotifyConnection(on: self) else {return}
        
        PlaylistGenerator.shared.generatePlaylistFromSpotify(for: emoji, activityIndicator: activityIndicator, on: self) { [weak self] result in
            
            guard let self = self else {return}
            switch result {
            case .success(let playlist):
                self.saveAndShowPlaylist(playlist)
            case .failure(let error):
                PlaylistGenerator.showAlert(on: self, title: "Error", message: "We were not able to generate playlist: \(error.localizedDescription)")
            }
        }
    }
    
    //save and show/push new playlist on vc
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
}
