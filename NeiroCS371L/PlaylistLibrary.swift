//
//  PlaylistLibrary.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 10/22/25.
//

import Foundation

enum PlaylistLibrary {

    static func playlist(for emoji: String) -> Playlist? {
        switch emoji {

        // 😀 Happy / Upbeat
        case "😀":
            return Playlist(
                title: "Good Vibes Only",
                emoji: emoji,
                songs: [
                    Song(title: "Happy", artist: "Pharrell Williams", genre: "Pop", lengthSeconds: 233),
                    Song(title: "Good as Hell", artist: "Lizzo", genre: "Pop", lengthSeconds: 162),
                    Song(title: "Can’t Stop the Feeling!", artist: "Justin Timberlake", genre: "Pop", lengthSeconds: 236)
                ])

        // 😎 Cool / Chill
        case "😎":
            return Playlist(
                title: "Smooth & Chill",
                emoji: emoji,
                songs: [
                    Song(title: "Sunset Lover", artist: "Petit Biscuit", genre: "Chillwave", lengthSeconds: 215),
                    Song(title: "Electric Feel", artist: "MGMT", genre: "Indie", lengthSeconds: 230),
                    Song(title: "Ocean Eyes", artist: "Billie Eilish", genre: "Pop", lengthSeconds: 200)
                ])

        // 🥲 Bittersweet
        case "🥲":
            return Playlist(
                title: "Bittersweet Memories",
                emoji: emoji,
                songs: [
                    Song(title: "Someone Like You", artist: "Adele", genre: "Pop", lengthSeconds: 285),
                    Song(title: "Let Her Go", artist: "Passenger", genre: "Folk", lengthSeconds: 250),
                    Song(title: "When We Were Young", artist: "Adele", genre: "Soul", lengthSeconds: 300)
                ])

        // 😭 Sad
        case "😭":
            return Playlist(
                title: "Sad Hours",
                emoji: emoji,
                songs: [
                    Song(title: "Liability", artist: "Lorde", genre: "Pop", lengthSeconds: 215),
                    Song(title: "Fix You", artist: "Coldplay", genre: "Rock", lengthSeconds: 295),
                    Song(title: "The Night We Met", artist: "Lord Huron", genre: "Indie", lengthSeconds: 205)
                ])

        // 🤪 Crazy / Energetic
        case "🤪":
            return Playlist(
                title: "Party Chaos",
                emoji: emoji,
                songs: [
                    Song(title: "Turn Down for What", artist: "DJ Snake & Lil Jon", genre: "EDM", lengthSeconds: 210),
                    Song(title: "Animals", artist: "Martin Garrix", genre: "EDM", lengthSeconds: 260),
                    Song(title: "I Like It", artist: "Cardi B", genre: "Hip-Hop", lengthSeconds: 250)
                ])

        // 🤩 Excited / Motivated
        case "🤩":
            return Playlist(
                title: "Glow Up Energy",
                emoji: emoji,
                songs: [
                    Song(title: "Levitating", artist: "Dua Lipa", genre: "Pop", lengthSeconds: 205),
                    Song(title: "Uptown Funk", artist: "Bruno Mars", genre: "Funk", lengthSeconds: 270),
                    Song(title: "Dance the Night", artist: "Dua Lipa", genre: "Pop", lengthSeconds: 210)
                ])

        // 😴 Sleepy / Chill
        case "😴":
            return Playlist(
                title: "Late Night Lo-Fi",
                emoji: emoji,
                songs: [
                    Song(title: "Warmth", artist: "Keys of Moon", genre: "Lo-Fi", lengthSeconds: 214),
                    Song(title: "Night Drive", artist: "Evoke", genre: "Lo-Fi", lengthSeconds: 189),
                    Song(title: "Dreams", artist: "Joakim Karud", genre: "Lo-Fi", lengthSeconds: 220)
                ])

        // 😐 Neutral / Background
        case "😐":
            return Playlist(
                title: "Background Focus",
                emoji: emoji,
                songs: [
                    Song(title: "Weightless", artist: "Marconi Union", genre: "Ambient", lengthSeconds: 500),
                    Song(title: "First Breath After Coma", artist: "Explosions in the Sky", genre: "Post-Rock", lengthSeconds: 550)
                ])

        // 😌 Calm / Peaceful
        case "😌":
            return Playlist(
                title: "Relax & Unwind",
                emoji: emoji,
                songs: [
                    Song(title: "Sunset Lover", artist: "Petit Biscuit", genre: "Chill", lengthSeconds: 215),
                    Song(title: "Bloom", artist: "ODESZA", genre: "Electronic", lengthSeconds: 240),
                    Song(title: "Weightless", artist: "Marconi Union", genre: "Ambient", lengthSeconds: 480)
                ])

        // 🙂 Content / Casual
        case "🙂":
            return Playlist(
                title: "Easy Days",
                emoji: emoji,
                songs: [
                    Song(title: "Sunday Best", artist: "Surfaces", genre: "Pop", lengthSeconds: 175),
                    Song(title: "Put It All On Me", artist: "Ed Sheeran", genre: "Pop", lengthSeconds: 210),
                    Song(title: "Yellow", artist: "Coldplay", genre: "Rock", lengthSeconds: 260)
                ])

        // 🙃 Silly / Playful
        case "🙃":
            return Playlist(
                title: "Upside Down Fun",
                emoji: emoji,
                songs: [
                    Song(title: "Happy Together", artist: "The Turtles", genre: "Pop", lengthSeconds: 165),
                    Song(title: "Sugar, We're Goin Down", artist: "Fall Out Boy", genre: "Rock", lengthSeconds: 225)
                ])

        // 😕 Confused / Thinking
        case "😕":
            return Playlist(
                title: "Lost in Thought",
                emoji: emoji,
                songs: [
                    Song(title: "The Less I Know The Better", artist: "Tame Impala", genre: "Indie", lengthSeconds: 215),
                    Song(title: "505", artist: "Arctic Monkeys", genre: "Rock", lengthSeconds: 245)
                ])

        // 🔥 Hype / Intense
        case "🔥":
            return Playlist(
                title: "Workout Mode",
                emoji: emoji,
                songs: [
                    Song(title: "Power", artist: "Kanye West", genre: "Hip-Hop", lengthSeconds: 290),
                    Song(title: "Till I Collapse", artist: "Eminem", genre: "Rap", lengthSeconds: 300),
                    Song(title: "Lose Yourself", artist: "Eminem", genre: "Rap", lengthSeconds: 325)
                ])

        // ❤️ Love / Romantic
        case "❤️":
            return Playlist(
                title: "Heartbeats",
                emoji: emoji,
                songs: [
                    Song(title: "All of Me", artist: "John Legend", genre: "R&B", lengthSeconds: 270),
                    Song(title: "Perfect", artist: "Ed Sheeran", genre: "Pop", lengthSeconds: 265),
                    Song(title: "Adore You", artist: "Harry Styles", genre: "Pop", lengthSeconds: 220)
                ])

        // ⚡️ Energetic / Workout
        case "⚡️":
            return Playlist(
                title: "Cardio Mix",
                emoji: emoji,
                songs: [
                    Song(title: "Can’t Hold Us", artist: "Macklemore", genre: "Hip-Hop", lengthSeconds: 270),
                    Song(title: "Titanium", artist: "David Guetta", genre: "EDM", lengthSeconds: 245),
                    Song(title: "Stronger", artist: "Kanye West", genre: "Hip-Hop", lengthSeconds: 312)
                ])

        // ➕ Create New
        case "➕":
            return Playlist(
                title: "Untitled New Playlist",
                emoji: emoji,
                songs: [
                    Song(title: "Start Something", artist: "Neiro", genre: "Placeholder", lengthSeconds: 0)
                ])

        default:
            return nil
        }
    }
}
