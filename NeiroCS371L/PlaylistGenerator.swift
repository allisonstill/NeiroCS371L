//
//  PlaylistGenerator.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/12/25.
//

//helping to generate playlists for create, random, and eventually describe

import UIKit

final class PlaylistGenerator {
    static let shared = PlaylistGenerator()
    private init() {}
    
    //generate playlist as long as spotify account is connected
    func generatePlaylistFromSpotify(for emoji: String,
                                     activityIndicator: UIActivityIndicatorView?,
                                     on vc: UIViewController,
                                     completion: @escaping (Result<Playlist, Error>) -> Void) {
        
        //not connected to spotify, throw error
        guard SpotifyUserAuthorization.shared.isConnected else {
            let error = NSError(domain: "PlaylistGenerator", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not Connected to Spotify"])
            completion(.failure(error))
            return
        }
        
        activityIndicator?.startAnimating()
        vc.view.isUserInteractionEnabled = false
        
        // get settings from Spotify Settings
        let settings = SpotifySettings.shared
        let targetCount = settings.playlistLength.songCount
        let excludedGenres = settings.excludedGenres
        
        //generate playlist!
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
    
    //private helper to create playlist based on songs given (return playlist)
    private func createPlaylist(emoji: String, songs: [Song]) -> Playlist {
        let playlistName = getPlaylistName(for: emoji)
        let gradientColors = generateGradientColors(from: emoji)
        
        //return playlist!
        return Playlist(title: playlistName, emoji: emoji, createdAt: Date(), songs: songs, gradientColors: gradientColors)
    }
    
    //save playlist to Firebase
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
    
    //generate gradient colors (UI purposes)
    func generateGradientColors(from emoji: String) -> [UIColor] {
        let hash = emoji.hashValue
        let firstHue = CGFloat((hash & 0xFF)) / 255.0
        let secondHue = CGFloat(((hash >> 8) & 0xFF)) / 255.0
        
        let firstColor = UIColor(hue: firstHue, saturation: 0.6, brightness: 0.5, alpha: 1.0)
        let secondColor = UIColor(hue: secondHue, saturation: 0.6, brightness: 0.3, alpha: 1.0)
        
        return [firstColor, secondColor]
    }
    
    //TODO: generate playlist names based on the emoji
    // as of now, just returning default name
    func getPlaylistName(for emoji: String) -> String {
        return "New \(emoji) Playlist"
    }
    
    //export playlist to spotify (on user account)
    func exportToSpotify(playlist: Playlist, activityIndicator: UIActivityIndicatorView?) {
        activityIndicator?.startAnimating()
        
        SpotifyAPI.shared.exportPlaylist(playlist: playlist) { result in
            
            DispatchQueue.main.async {
                activityIndicator?.stopAnimating()
                
                //TODO: eventually, we might want to add this as a link or button to actually go to the spotify account
                switch result {
                case .success(let url):
                    print("Playlist exported to \(url)")
                case .failure(let error):
                    print("Export failed: \(error.localizedDescription)")
                }
            }
        }
    }
    
    //check if there is already a playlist made with this emoji
    func existingPlaylist(for emoji: String) -> Playlist? {
        let existingPlaylists = PlaylistLibrary.playlists(for: emoji)
        return existingPlaylists.first
    }
    
    // generate an alert that the spotify has not been connected yet
    static func checkSpotifyConnection(on vc: UIViewController) -> Bool {
        if !SpotifyUserAuthorization.shared.isConnected {
            showAlert(on: vc, title: "Connect Spotify", message: "Please connect your Spotify account to generate playlists!")
            return false
        }
        return true
    }
    
    //general alert (helper function)
    static func showAlert(on vc: UIViewController, title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        vc.present(alert, animated: true)
    }   
}
