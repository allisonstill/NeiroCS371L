//
//  Playlist.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 10/21/25.
//

import Foundation
import UIKit

// MARK: - Song Model
class Song {
    let id: UUID
    var title: String
    var artist: String?
    var album: String?
    var genre: String?
    var lengthSeconds: Int? // duration in seconds
    var albumURL: String?

    init(title: String,
         artist: String? = nil,
         album: String? = nil,
         genre: String? = nil,
         lengthSeconds: Int? = nil,
         albumURL: String? = nil) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.album = album
        self.genre = genre
        self.lengthSeconds = lengthSeconds
        self.albumURL = albumURL
    }

    // MARK: - Helper Properties
    var formattedDuration: String {
        guard let seconds = lengthSeconds else { return "--:--" }
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }

    var displayTitle: String {
        "\(title)" + (artist != nil ? " — \(artist!)" : "")
    }
}

// MARK: - Playlist class
class Playlist {
    let id: UUID
    var title: String
    var emoji: String
    var createdAt: Date
    var songs: [Song]
    var gradientColors: [UIColor]?
    
    init(title: String, emoji: String, createdAt: Date = Date(), songs: [Song] = [],
         gradientColors: [UIColor]? = nil) {
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.createdAt = createdAt
        self.songs = songs
        self.gradientColors = gradientColors
    }
    
    init(id: UUID, title: String, emoji: String, createdAt: Date = Date(), songs: [Song] = [], gradientColors: [UIColor]? = nil) {
        self.id = id
        self.title = title
        self.emoji = emoji
        self.createdAt = createdAt
        self.songs = songs
        self.gradientColors = gradientColors
    }

    // MARK: - Computed Properties
    var songCount: Int { songs.count }

    var totalLengthSeconds: Int {
        songs.compactMap { $0.lengthSeconds }.reduce(0, +)
    }

    var formattedLength: String {
        let total = totalLengthSeconds
        let hours = total / 3600
        let mins = (total % 3600) / 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, mins)
        } else {
            return String(format: "%dm", mins)
        }
    }

    var genres: [String] {
        Array(Set(songs.compactMap { $0.genre })).sorted()
    }

    var description: String {
        """
        \(emoji) \(title)
        \(songCount) songs • \(formattedLength)
        Genres: \(genres.isEmpty ? "N/A" : genres.joined(separator: ", "))
        """
    }
    
    
    // MARK: - Helper Functions
    func addSong(_ song: Song) {
        songs.append(song)
    }

    func removeSong(byID id: UUID) {
        songs.removeAll { $0.id == id }
    }

    func averageSongLength() -> String {
        guard !songs.isEmpty else { return "--:--" }
        let avg = totalLengthSeconds / songs.count
        let mins = avg / 60
        let secs = avg % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - EXTENSION: Serialization for Firebase
// This allows us to save the generated playlist to the database so everyone sees the same songs
extension Song {
    var toDict: [String: Any] {
        var dict: [String: Any] = ["title": title]
        if let artist = artist { dict["artist"] = artist }
        if let album = album { dict["album"] = album }
        if let genre = genre { dict["genre"] = genre }
        if let lengthSeconds = lengthSeconds { dict["lengthSeconds"] = lengthSeconds }
        if let albumURL = albumURL { dict["albumURL"] = albumURL }
        return dict
    }

    convenience init?(dict: [String: Any]) {
        guard let title = dict["title"] as? String else { return nil }
        
        self.init(
            title: title,
            artist: dict["artist"] as? String,
            album: dict["album"] as? String,
            genre: dict["genre"] as? String,
            lengthSeconds: dict["lengthSeconds"] as? Int,
            albumURL: dict["albumURL"] as? String
        )
    }
}
