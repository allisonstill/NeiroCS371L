//
//  SpotifySettings.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/3/25.
//

import Foundation

class SpotifySettings {
    static let shared = SpotifySettings()
    
    private let defaults = UserDefaults.standard
    
    private init() {}
    
    private enum Keys {
        static let excludedGenres = "spotify_excluded_genres"
        static let playlistLength = "spotify_playlist_length"
        static let defaultPlaylistName = "spotify_default_playlist_name"
        static let autoExportToSpotify = "spotify_auto_export"
    }
    
    // get excluded Genres & set in defaults
    var excludedGenres: [String] {
        get { return defaults.stringArray(forKey: Keys.excludedGenres) ?? [] }
        set { defaults.set(newValue, forKey: Keys.excludedGenres) }
    }
    
    // add new excluded genre
    func addExcludedGenre(_ genre: String) {
        var genres = excludedGenres
        if !genres.contains(genre) {
            genres.append(genre)
            excludedGenres = genres
        }
    }
    
    //take out excluded genre
    func removeExcludedGenre(_ genre: String) {
        var genres = excludedGenres
        genres.removeAll { $0 == genre }
        excludedGenres = genres
    }
    
    //check if a genre is excluded
    func isGenreExcluded(_ genre: String) -> Bool {
        return excludedGenres.contains(genre)
    }
    
    enum PlaylistLength: Int, CaseIterable {
        case short = 4 // 4 songs is about 10 mins long
        case medium = 10 // 10 songs is abt 30 mins long
        case long = 20  // 20 songs is abt 60 minutes long
        case extraLong = 40 //40 songs is about 120 minutes long
        
        var displayName: String {
            switch self {
            case .short: return "Short (about 10 minutes)"
            case .medium: return "Medium (about 30 minutes)"
            case .long: return "Long (about 60 minutes)"
            case .extraLong: return "Extra Long (about 120 minutes)"
            }
        }
        
        var songCount: Int {
            return rawValue
        }
    }
    
    //get & set playlist length in defaults
    var playlistLength: PlaylistLength {
        get {
            let rawValue = defaults.integer(forKey: Keys.playlistLength)
            return PlaylistLength(rawValue: rawValue) ?? .medium
        }
        set {defaults.set(newValue.rawValue, forKey: Keys.playlistLength) }
    }
    

    //get and set playlist name (default: 'Neiro Playlist')
    var defaultPlaylistName: String {
        get { return defaults.string(forKey: Keys.defaultPlaylistName) ?? "Neiro Playlist" }
        set { defaults.set(newValue, forKey: Keys.defaultPlaylistName) }
    }
    

    //exporting to Spotify account (if account connected)
    var autoExportToSpotify: Bool {
        get { return defaults.bool(forKey: Keys.autoExportToSpotify)}
        set { defaults.set(newValue, forKey: Keys.autoExportToSpotify)}
    }
    
    //list of sorted available genres
    static let availableGenres = [ "Pop", "Rock", "Hip Hop", "R&B", "Country", "Electronic", "Dance", "EDM", "Jazz", "Classical", "Blues", "Reggae", "Metal", "Indie", "Alternative", "Folk", "Soul", "Funk", "Punk", "Acoustic", "Latin", "K-Pop", "Ambient", "House", "Techno"
    ].sorted()
    

    //reset settings
    //no excluded genres, medium playlist length, default name, don't export
    func resetToDefaults() {
        excludedGenres = []
        playlistLength = .medium
        defaultPlaylistName = "Neiro Playlist"
        autoExportToSpotify = false
    }
}
