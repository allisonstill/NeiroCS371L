//
//  DescribeLLMViewController.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/12/25.
//

import UIKit

class DescribeLLMViewController: UIViewController, UITextViewDelegate {
    
    //if this is set, we wll update the playlist; else: create new playlist
    var updatingPlaylist: Playlist?
    var onUpdate: ((Playlist) -> Void)?
    
    // Callback to return a new playlist to the list VC
    var onCreate: ((Playlist) -> Void)?
    
    private let describeLabel = UILabel()
    private let helperLabel = UILabel()
    private let textBackgroundView = UIView()
    private let textArea = UITextView()
    private let placeholderLabel = UILabel()
    private let createButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Describe Playlist"
        view.backgroundColor = ThemeColor.Color.backgroundColor
        textArea.delegate = self
        
        setupScreen()
    }
    
    private func setupScreen() {
        describeLabel.text = "Describe the type of playlist you would like to create in 1-2 sentences."
        describeLabel.numberOfLines = 0
        describeLabel.textAlignment = .center
        describeLabel.font = .systemFont(ofSize: 16, weight: .regular)
        describeLabel.textColor = .white
        describeLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(describeLabel)
        
        // set up new helper label as instructions for the user to know what to input in the LLM box
        helperLabel.translatesAutoresizingMaskIntoConstraints = false
        helperLabel.textColor = .lightGray
        helperLabel.textAlignment = .center
        helperLabel.font = .systemFont(ofSize: 14)
        helperLabel.numberOfLines = 0
        
        // change instruction helper text based on if we are creating or updating
        if updatingPlaylist == nil {
            helperLabel.text = "Please describe BOTH the mood and length of the playlist. Example: '60 minutes of upbeat, positive, pop music to use for a workout.'"
        } else {
            helperLabel.text = "Please describe BOTH the new mood and new length of the playlist you want. Example: 'Make this playlist slightly more upbeat and longer, like 60 minutes long, but keep the same general vibe."
        }
        
        view.addSubview(helperLabel)
        
        textBackgroundView.translatesAutoresizingMaskIntoConstraints = false
        textBackgroundView.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.9)
        textBackgroundView.layer.cornerRadius = 14
        textBackgroundView.layer.shadowColor = UIColor.black.cgColor
        textBackgroundView.layer.shadowOpacity = 0.25
        textBackgroundView.layer.shadowRadius = 10
        textBackgroundView.layer.shadowOffset = CGSize(width: 0, height: 4)
        view.addSubview(textBackgroundView)
                                                       
        
        textArea.font = .systemFont(ofSize: 16)
        textArea.layer.cornerRadius = 8
        textArea.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.8)
        textArea.layer.borderWidth = 1
        textArea.layer.borderColor = UIColor.secondaryLabel.cgColor
        textArea.translatesAutoresizingMaskIntoConstraints = false
        textArea.textContainerInset = UIEdgeInsets(top: 16, left: 12, bottom: 16, right: 12)
        view.addSubview(textArea)
        
        // add placeholder to the LLM box
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.text = "Describe the mood and length of the playlist!"
        placeholderLabel.textColor = UIColor.lightGray.withAlphaComponent(0.8)
        placeholderLabel.font = .systemFont(ofSize: 16)
        placeholderLabel.numberOfLines = 0
        
        textArea.addSubview(placeholderLabel)
        
        setupCreateButton()
        
        NSLayoutConstraint.activate([
            
            
            describeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 32),
            describeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            describeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            
            helperLabel.topAnchor.constraint(equalTo: describeLabel.bottomAnchor, constant: 8),
            helperLabel.leadingAnchor.constraint(equalTo: describeLabel.leadingAnchor),
            helperLabel.trailingAnchor.constraint(equalTo: describeLabel.trailingAnchor),
            
            textBackgroundView.topAnchor.constraint(equalTo: helperLabel.bottomAnchor, constant: 16),
            textBackgroundView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            textBackgroundView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            textBackgroundView.heightAnchor.constraint(equalToConstant: 180),
            
            textArea.topAnchor.constraint(equalTo: textBackgroundView.topAnchor),
            textArea.leadingAnchor.constraint(equalTo: textBackgroundView.leadingAnchor),
            textArea.trailingAnchor.constraint(equalTo: textBackgroundView.trailingAnchor),
            textArea.bottomAnchor.constraint(equalTo: textBackgroundView.bottomAnchor),
            
            placeholderLabel.topAnchor.constraint(equalTo: textArea.topAnchor, constant: 12),
            placeholderLabel.leadingAnchor.constraint(equalTo: textArea.leadingAnchor, constant: 12),
            placeholderLabel.trailingAnchor.constraint(equalTo: textArea.trailingAnchor, constant: -12),
            
            createButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            createButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            createButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
            createButton.heightAnchor.constraint(equalToConstant: 50),
            
        ])
        
        
    }
    
    private func setupCreateButton() {
        // create button changes from generate to update depending on function we are completing
        let buttonTitle = updatingPlaylist == nil ? "Generate Playlist" : "Update Playlist"
        createButton.setTitle(buttonTitle, for: .normal)
        createButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        createButton.backgroundColor = .systemBlue
        createButton.setTitleColor(.white, for: .normal)
        createButton.layer.cornerRadius = 12
        createButton.contentEdgeInsets = UIEdgeInsets(top: 14, left: 20, bottom: 14, right: 20)
        
        createButton.addTarget(self, action: #selector(createPlaylistTapped), for: .touchUpInside)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(createButton)
    }
    
    
    // create playlist button was pressed
    @objc private func createPlaylistTapped() {
        
        // make sure text has been entered to the LLM text box
        let text = textArea.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            showAlert(title: "Describe your playlist", message: "Please enter 1-2 sentences describing your playlist in the text area.")
            return
        }
        
        let lowercase = text.lowercased()
        
        // ensure input text contains time before LLM call
        let textContainsTime = lowercase.contains("minute") || lowercase.contains("min") || lowercase.contains("hour") || lowercase.contains("short") || lowercase.contains("medium") || lowercase.contains("long") || lowercase.contains("extra")
        
        // ensure input text contains mood before LLM call
        let textContainsMood = lowercase.contains("happy") || lowercase.contains("sad") || lowercase.contains("chill") || lowercase.contains("calm") || lowercase.contains("upbeat") || lowercase.contains("energetic") || lowercase.contains("romantic") || lowercase.contains("angry") || lowercase.contains("relaxed") || lowercase.contains("vibe")
        
        if !textContainsMood || !textContainsTime {
            showAlert(title: "More Details Needed", message: "Please include both a mood and a playlist length (time). For example, try asking for a 'calm 30-minute playlist'.")
            return
        }
        
        // change create button text as indicator of LLM request working
        setLoading(true, title: updatingPlaylist == nil ? "Generating..." : "Updating...")
        
        let currentEmoji = updatingPlaylist?.emoji
        let currentLength = updatingPlaylist != nil ? SpotifySettings.shared.playlistLength.displayName : nil
        
        Task { [weak self] in
            guard let self else { return }
            do {
                // get response from LLM (Gemini) & handle response
                let geminiResponse = try await DescribeLLMModels.shared.getDescription(text: text, currentEmoji: currentEmoji, currentLength: currentLength)
                await MainActor.run {
                    self.handleLLMResponse(geminiResponse)
                }
            } catch {
                
                // Error! Couldn't get response from Gemini
                await MainActor.run {
                    self.setLoading(false, title: self.updatingPlaylist == nil ? "Generate Playlist" : "Update Playlist")
                    self.showAlert(title: "Error", message: "We could not understand your request. Make sure to include both a mood and a playlist length, and please try again: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // helper loading function -> changes create button's text
    // provides a UI indicator that the LLM is working
    private func setLoading(_ loading: Bool, title: String) {
        createButton.isEnabled = !loading
        createButton.setTitle(title, for: .normal)
        view.isUserInteractionEnabled = !loading
        createButton.alpha = loading ? 0.7 : 1.0
    }
    
    // based on input to LLM, either create new or update playlist
    private func handleLLMResponse(_ response: DescribeLLMResponse) {
        let lengthEnum = SpotifySettings.PlaylistLength.fromLLM(response.playlistLength)
        SpotifySettings.shared.playlistLength = lengthEnum
        
        if let updateThisPlaylist = updatingPlaylist {
            // update already existing playlist with new songs
            updatePlaylist(updateThisPlaylist, using: response.emoji, length: lengthEnum)
        } else {
            // create brand new playlist
            createPlaylist(using: response.emoji, length: lengthEnum)
        }
    }
    
    // update an already existing playlist
    private func updatePlaylist(_ playlist: Playlist, using emoji: String, length: SpotifySettings.PlaylistLength) {
        
        // make sure we are still connected to spotify
        guard SpotifyUserAuthorization.shared.isConnected else {
            setLoading(false, title: "Update Playlist")
            showAlert(title: "Not Connected", message: "Please connect a Spotify account before continuing.")
            return
        }
        
        // get settings that we are conforming our playlist to
        SpotifySettings.shared.playlistLength = length
        let settings = SpotifySettings.shared
        let targetCount = settings.playlistLength.songCount
        let excludedGenres = settings.excludedGenres
        
        SpotifyAPI.shared.generatePlaylist(for: emoji, targetSongCount: targetCount, excludedGenres: excludedGenres) {
            [weak self] result in
            
            DispatchQueue.main.async {
                guard let self else {return}
                self.setLoading(false, title: "Update Playlist")
                switch result {
                case .failure(let error):
                    self.showAlert(title: "Update Failed", message: error.localizedDescription)
                case .success(let newSongs):
                    let uniqueSongs = Dictionary(grouping: newSongs, by: {
                        "\($0.title)_\($0.artist ?? "")"
                    }).compactMap {$0.value.first}
                    
                    playlist.emoji = emoji
                    playlist.songs = uniqueSongs
                    PlaylistLibrary.updatePlaylist(playlist)
                    
                    self.onUpdate?(playlist)
                    
                    let alert = UIAlertController(title: "Playlist Updated", message: "Your playlist mood and length were updated.", preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
                        self.navigationController?.popViewController(animated: true)
                    })
                    self.present(alert, animated: true)
                }
            }
        }
    }
    
    // create new playlist
    private func createPlaylist(using emoji: String, length: SpotifySettings.PlaylistLength) {
        
        // make sure spotify is still connected
        guard PlaylistGenerator.checkSpotifyConnection(on: self) else {
            setLoading(false, title: "Generate Playlist")
            return
        }
        
        // use desired length
        SpotifySettings.shared.playlistLength = length
        
        // generate playlist call
        PlaylistGenerator.shared.generatePlaylistFromSpotify(for: emoji, activityIndicator: nil, on: self) { [weak self] result in
            
            DispatchQueue.main.async {
                guard let self else {return}
                self.setLoading(false, title: "Generate Playlist")
                
                switch result {
                
                // failed to create a playlist, show alert to user
                case .failure(let error):
                    PlaylistGenerator.showAlert(on: self, title: "Error", message: "We couldn't generate a new playlist: \(error.localizedDescription)")
                
                // created a new playlist! save and show the new playlist!
                case .success (let playlist):
                    PlaylistGenerator.shared.savePlaylist(playlist) { _ in }
                    self.onCreate?(playlist)
                    
                    let detailVC = PlaylistDetailViewController()
                    detailVC.playlist = playlist
                    detailVC.isNewPlaylist = true
                    self.navigationController?.pushViewController(detailVC, animated: true)
                }
            }
            
        }
    }
        
    // Called when the user clicks on the view outside of the UITextField
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    // get rid of placeholder when we start typing
    func textViewDidChange(_ textView: UITextView) {
        placeholderLabel.isHidden = !textView.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // alert helper function
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
}
