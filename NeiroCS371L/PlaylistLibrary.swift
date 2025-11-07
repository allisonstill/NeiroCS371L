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
    
    //list of playlists in the app
    private var playlists: [Playlist] = []
    
    //add playlist to teh list of playlists in most recent order (most recently added)
    static func addPlaylist(_ playlist: Playlist) {
        shared.playlists.insert(playlist, at: 0)
    }
    
    //return all playlists
    static func allPlaylists() -> [Playlist] {
        return shared.playlists
    }
    
    //get playlist based on ID
    static func playlist(withID id: UUID) -> Playlist? {
        return shared.playlists.first { $0.id == id }
    }
    
    //remove playlist from playlists
    static func removePlaylist(_ playlist: Playlist) {
        shared.playlists.removeAll { $0.id == playlist.id }
    }
    
    //remove playlist based on ID
    static func removePlaylist(withID id: UUID) {
        shared.playlists.removeAll { $0.id == id }
    }
    
    //remove all playlists (clean ship)
    static func clearAll() {
        shared.playlists.removeAll()
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
}
