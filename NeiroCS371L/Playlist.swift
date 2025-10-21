//
//  Playlist.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 10/21/25.
//

import Foundation

// MARK: - Song Model
class Song {
    let id: UUID
    var title: String
    var artist: String?
    var album: String?
    var genre: String?
    var lengthSeconds: Int? // duration in seconds

    init(title: String,
         artist: String? = nil,
         album: String? = nil,
         genre: String? = nil,
         lengthSeconds: Int? = nil) {
        self.id = UUID()
        self.title = title
        self.artist = artist
        self.album = album
        self.genre = genre
        self.lengthSeconds = lengthSeconds
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

    init(title: String, emoji: String, createdAt: Date = Date(), songs: [Song] = []) {
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.createdAt = createdAt
        self.songs = songs
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

    // MARK: - Demo Data, for testing
    static var demo: Playlist {
        let songs = [
            Song(title: "Blinding Lights", artist: "The Weeknd", album: "After Hours", genre: "Pop", lengthSeconds: 200),
            Song(title: "Levitating", artist: "Dua Lipa", album: "Future Nostalgia", genre: "Pop", lengthSeconds: 203),
            Song(title: "Lose Yourself", artist: "Eminem", album: "8 Mile", genre: "Rap", lengthSeconds: 326),
            Song(title: "Sunflower", artist: "Post Malone", album: "Spider-Verse", genre: "Alternative", lengthSeconds: 157)
        ]
        return Playlist(title: "Sunny Vibes", emoji: "😎", createdAt: Date(), songs: songs)
    }

    static var demoList: [Playlist] {
        [Playlist.demo]
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
