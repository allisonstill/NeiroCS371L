//
//  PlaylistGenerator.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/12/25.
//

import UIKit

final class PlaylistGenerator {
    static let shared = PlaylistGenerator()
    private init() {}
    
    // MARK: - NEW: Group Session Mix Generator
    func generateMixedPlaylist(
        from breakdown: [EmojiBreakdown],
        on vc: UIViewController,
        activityIndicator: UIActivityIndicatorView? = nil,
        completion: @escaping (Result<Playlist, Error>) -> Void
    ) {
        // 1. Check Connection
        guard SpotifyUserAuthorization.shared.isConnected else {
            let error = NSError(domain: "PlaylistGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not Connected to Spotify"])
            completion(.failure(error))
            return
        }
        
        // 2. Start Loading UI
        activityIndicator?.startAnimating()
        vc.view.isUserInteractionEnabled = false
        
        let group = DispatchGroup()
        var allSongs: [Song] = []
        var requestErrors: [Error] = []
        
        // 3. Loop through every emoji in the breakdown
        for item in breakdown {
            if item.songCount > 0 {
                group.enter()
                // Use existing API to fetch songs for this specific emoji
                SpotifyAPI.shared.generatePlaylist(for: item.emoji, targetSongCount: item.songCount) { result in
                    switch result {
                    case .success(let songs):
                        allSongs.append(contentsOf: songs)
                    case .failure(let error):
                        print("⚠️ Failed to fetch songs for \(item.emoji): \(error.localizedDescription)")
                        requestErrors.append(error)
                    }
                    group.leave()
                }
            }
        }
        
        // 4. When all API calls finish
        group.notify(queue: .main) {
            activityIndicator?.stopAnimating()
            vc.view.isUserInteractionEnabled = true
            
            if allSongs.isEmpty {
                // If everything failed
                let error = requestErrors.first ?? NSError(domain: "Generator", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find any songs."])
                completion(.failure(error))
            } else {
                // 5. Create the final Mixed Playlist
                // Shuffle to mix the vibes together
                let mixedSongs = allSongs.shuffled()
                let gradient = self.generateGradientColors(from: "✨")
                
                let finalPlaylist = Playlist(
                    title: "Group Session Mix",
                    emoji: "✨",
                    createdAt: Date(),
                    songs: mixedSongs,
                    gradientColors: gradient
                )
                
                completion(.success(finalPlaylist))
            }
        }
    }
    
    // MARK: - Existing Single User Generation
    
    func generatePlaylistFromSpotify(for emoji: String,
                                     activityIndicator: UIActivityIndicatorView?,
                                     on vc: UIViewController,
                                     completion: @escaping (Result<Playlist, Error>) -> Void) {
        
        guard SpotifyUserAuthorization.shared.isConnected else {
            let error = NSError(domain: "PlaylistGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not Connected to Spotify"])
            completion(.failure(error))
            return
        }
        
        activityIndicator?.startAnimating()
        vc.view.isUserInteractionEnabled = false
        
        let settings = SpotifySettings.shared
        let targetCount = settings.playlistLength.songCount
        let excludedGenres = settings.excludedGenres
        
        SpotifyAPI.shared.generatePlaylist(
            for: emoji,
            targetSongCount: targetCount,
            excludedGenres: excludedGenres) { result in
            DispatchQueue.main.async {
                activityIndicator?.stopAnimating()
                vc.view.isUserInteractionEnabled = true
                
                switch result {
                case .success(let songs):
                    let playlist = self.createPlaylist(emoji: emoji, songs: songs)
                    completion(.success(playlist))
                    
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - ListenBrainz Generation
    func generatePlaylistFromListenBrainz(
        for emoji: String,
        activityIndicator: UIActivityIndicatorView?,
        on vc: UIViewController,
        completion: @escaping (Result<Playlist, Error>) -> Void
    ) {
        guard SpotifyUserAuthorization.shared.isConnected else {
            let error = NSError(
                domain: "PlaylistGenerator",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Not Connected to Spotify"]
            )
            completion(.failure(error))
            return
        }

        activityIndicator?.startAnimating()
        vc.view.isUserInteractionEnabled = false

        let settings = SpotifySettings.shared
        let targetCount = settings.playlistLength.songCount

        ListenBrainzAPI.shared.generateSongsFromEmoji(emoji, targetSongCount: targetCount) { result in
            DispatchQueue.main.async {
                activityIndicator?.stopAnimating()
                vc.view.isUserInteractionEnabled = true

                switch result {
                case .success(let songs):
                    let playlist = self.createPlaylist(emoji: emoji, songs: songs)
                    completion(.success(playlist))

                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }
    
    // MARK: - Last.fm Generation
        
    func generatePlaylistFromLastFM(
        for emoji: String,
        nicheness: Int = SessionStore.hipsterRating,
        activityIndicator: UIActivityIndicatorView?,
        on vc: UIViewController,
        completion: @escaping (Result<Playlist, Error>) -> Void
    ) {
        guard SpotifyUserAuthorization.shared.isConnected else {
            let error = NSError(
                domain: "PlaylistGenerator",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Not Connected to Spotify"]
            )
            completion(.failure(error))
            return
        }
          
        activityIndicator?.startAnimating()
        vc.view.isUserInteractionEnabled = false
          
        let settings = SpotifySettings.shared
        let targetCount = settings.playlistLength.songCount
          
        let excludedArtists: Set<String> = SessionStore.unwantedArtists
        let preferredArtists:Set<String> = SessionStore.preferredArtists
        let preferredGenres: Set<String> = SessionStore.preferredGenres
          
        LastFMAPI.shared.generateSongsFromEmoji(
            emoji,
            nicheness: nicheness,
            songCount: targetCount,
            excludedArtists: excludedArtists,
            preferredArtists: preferredArtists,
            preferredGenres: preferredGenres
        ) { result in
            DispatchQueue.main.async {
                activityIndicator?.stopAnimating()
                vc.view.isUserInteractionEnabled = true
                  
                switch result {
                case .success(let songs):
                    let playlist = self.createPlaylist(emoji: emoji, songs: songs)
                    completion(.success(playlist))
                      
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    // MARK: - Helpers
    
    private func createPlaylist(emoji: String, songs: [Song]) -> Playlist {
        let playlistName = getPlaylistName(for: emoji)
        let gradientColors = generateGradientColors(from: emoji)
        
        return Playlist(title: playlistName, emoji: emoji, createdAt: Date(), songs: songs, gradientColors: gradientColors)
    }
    
    func savePlaylist( _ playlist: Playlist, activityIndicator: UIActivityIndicatorView? = nil, completion: @escaping (Bool) -> Void) {
        PlaylistLibrary.addPlaylist(playlist) { success in
            DispatchQueue.main.async {
                if success {
                    print("Playlist added/saved to Firebase!")
                }
                completion(success)
            }
        }
    }
    
    func generateGradientColors(from emoji: String) -> [UIColor] {
        let hash = emoji.hashValue
        let firstHue = CGFloat((hash & 0xFF)) / 255.0
        let secondHue = CGFloat(((hash >> 8) & 0xFF)) / 255.0
        
        let firstColor = UIColor(hue: firstHue, saturation: 0.6, brightness: 0.5, alpha: 1.0)
        let secondColor = UIColor(hue: secondHue, saturation: 0.6, brightness: 0.3, alpha: 1.0)
        
        return [firstColor, secondColor]
    }
    
    func getPlaylistName(for emoji: String) -> String {
        return "New \(emoji) Playlist"
    }
    
    func exportToSpotify(playlist: Playlist, activityIndicator: UIActivityIndicatorView?) {
        activityIndicator?.startAnimating()
        
        SpotifyAPI.shared.exportPlaylist(playlist: playlist) { result in
            DispatchQueue.main.async {
                activityIndicator?.stopAnimating()
                switch result {
                case .success(let url):
                    print("Playlist exported to \(url)")
                case .failure(let error):
                    print("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func existingPlaylist(for emoji: String) -> Playlist? {
        let existingPlaylists = PlaylistLibrary.playlists(for: emoji)
        return existingPlaylists.first
    }
    
    static func checkSpotifyConnection(on vc: UIViewController) -> Bool {
        if !SpotifyUserAuthorization.shared.isConnected {
            showAlert(on: vc, title: "Connect Spotify", message: "Please connect your Spotify account to generate playlists!")
            return false
        }
        return true
    }
    
    static func showAlert(on vc: UIViewController, title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }
}
