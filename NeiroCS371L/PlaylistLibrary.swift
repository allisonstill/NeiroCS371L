//
//  PlaylistLibrary.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 10/22/25.
//

import Foundation

//Replaced most of functionality here so that it was based on Spotify returned playlists, not hardcoded

class PlaylistLibrary {
    
    static let shared = PlaylistLibrary()
    private init() {}
    
    //store uuid of most recently opened playlist
    private enum RecentKeys { static let lastOpenedID = "neiro_last_opened_playlist_id" }
    
    //list of playlists in the app
    private var playlists: [Playlist] = []
    
    //save most recently opened playlist
    static func setLastOpened(_ playlist: Playlist) {
        UserDefaults.standard.set(playlist.id.uuidString, forKey: RecentKeys.lastOpenedID)
    }
    
    //change the id from userdefaults to in-memory
    static func lastOpenedPlaylist() -> Playlist? {
        guard let idString = UserDefaults.standard.string(forKey: RecentKeys.lastOpenedID),
              let id = UUID(uuidString: idString) else { return nil }
        
        return shared.playlists.first(where: { $0.id == id })
    }
    
    //add playlist to teh list of playlists in most recent order (most recently added)
    static func addPlaylist(_ playlist: Playlist, completion: ((Bool) -> Void)? = nil) {
        shared.playlists.insert(playlist, at: 0)
        
        SpotifyPlaylistFirestore.shared.savePlaylist(playlist) { result in
            
            switch result {
            case .success:
                print("Playlist saved to Firebase")
                completion?(true)
            case .failure(let error):
                print("Failed to save playlist to Firebase: \(error.localizedDescription)")
                completion?(false)
            }
        }
    }
    
    //load all playlists for current user from Firebase
    static func loadPlaylists(completion: @escaping (Bool) -> Void) {
        SpotifyPlaylistFirestore.shared.loadUserPlaylists { result in
            
            switch result {
            case .success(let playlists):
                shared.playlists = playlists
                print("Loaded \(playlists.count) playlists from Firebase")
                completion(true)
            case .failure(let error):
                print("Failed to load playlists from Firebase: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    //return all playlists
    static func allPlaylists() -> [Playlist] {
        return shared.playlists
    }
    
    //get playlist based on ID
    static func playlist(withID id: UUID) -> Playlist? {
        return shared.playlists.first { $0.id == id }
    }

    
    //return a playlist based on a certain emoji
    //core functionality!
    static func playlists(for emoji: String) -> [Playlist] {
        return shared.playlists.filter { $0.emoji == emoji }
    }
    
    //return most recent playlist (can be used in home page?)
    static func mostRecentPlaylist() -> Playlist? {
        return shared.playlists.first
    }
    
    //get total playlist count
    static var count: Int {
        return shared.playlists.count
    }
    
    
    //remove playlist from playlists
    static func removePlaylist(_ playlist: Playlist, completion: ((Bool) -> Void)? = nil) {
        shared.playlists.removeAll { $0.id == playlist.id }
        
        SpotifyPlaylistFirestore.shared.deletePlaylist(playlist) { result in
            switch result {
            case .success:
                print("Playlist deleted from Firebase")
                completion?(true)
            case .failure(let error):
                print("Failed to delete playlist from Firebase \(error.localizedDescription)")
                completion?(false)
            }
        }
    }
    
    //remove playlist based on ID
    static func removePlaylist(withID id: UUID, completion: ((Bool) -> Void)? = nil) {
        if let playlist = shared.playlists.first(where: {$0.id == id}) {
            removePlaylist(playlist, completion: completion)
        } else {
            completion?(false)
        }
    }
    
    //update playlist
    static func updatePlaylist(_ playlist: Playlist, completion: ((Bool) -> Void)? = nil) {
        
        if let index = shared.playlists.firstIndex(where: { $0.id == playlist.id }) {
            shared.playlists.remove(at: index)
        }

        shared.playlists.insert(playlist, at: 0)

        // save as last opened
        UserDefaults.standard.set(playlist.id.uuidString, forKey: RecentKeys.lastOpenedID)

        SpotifyPlaylistFirestore.shared.updatePlaylist(playlist) { result in
            switch result {
            case .success:
                print("Playlist updated in Firebase")
                completion?(true)
            case .failure(let error):
                print("Failed to update playlist in Firebase: \(error.localizedDescription)")
                completion?(false)
            }
        }
    }

    static func clearLocal() {
        shared.playlists.removeAll()
        print("Local playlists cleared")
    }
    
    //remove all playlists (clean ship)
    static func clearAll(completion: ((Bool) -> Void)? = nil) {
        shared.playlists.removeAll()
        
        SpotifyPlaylistFirestore.shared.clearAllUserPlaylists { result in
            switch result {
            case .success:
                print("All playlists cleared from Firebase")
                completion?(true)
            case .failure(let error):
                print("Failed to clear playlists in Firebase \(error.localizedDescription)")
                completion?(false)
            }
        }
    }
    
    //return the last opened playlist or newest if one hasn't been opened on this session
    static func homePlaylist() -> Playlist? {
        return lastOpenedPlaylist() ?? shared.playlists.first
    }
}
