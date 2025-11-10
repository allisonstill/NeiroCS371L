//
//  SpotifyModels.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/4/25.
//

import Foundation

//creating a spotifyTrack (song) struct
struct SpotifyTrack: Codable {
    let id: String
    let name: String
    let artists: [SpotifyArtist]
    let album: SpotifyAlbum
    let duration_ms: Int
    let preview_url: String?
    let uri: String
    let external_urls: ExternalUrls
    
    //includes a spotify artist struct for the artist of the song
    struct SpotifyArtist: Codable {
        let id: String
        let name: String
    }
    
    //includes a spotify album struct for the album of the song
    struct SpotifyAlbum: Codable {
        let id: String
        let name: String
        let images: [SpotifyImage]
    }
    
    //includes a spotify image struct for the image of the song
    //TODO: Not working right now
    struct SpotifyImage: Codable {
        let url: String
        let height: Int?
        let width: Int?
    }
    
    //includes an external urls struct for linking from the song
    //TODO: Not working right now
    struct ExternalUrls: Codable {
        let spotify: String
    }
    
    // Convert to Song struct
    func toSong() -> Song {
        let artistName = artists.first?.name
        let albumName = album.name
        let durationSeconds = duration_ms / 1000
        let albumImageURL = album.images.first?.url
        
        
        //create a song based on the SpotifyTrack
        return Song(
            title: name,
            artist: artistName,
            album: albumName,
            genre: nil, //get from search
            lengthSeconds: durationSeconds,
            albumURL: albumImageURL
        )
    }
}

//using spotify search for api endpoint
struct SpotifySearchResponse: Codable {
    let tracks: TracksResponse
    
    //list of tracks that are found within search
    struct TracksResponse: Codable {
        let items: [SpotifyTrack]
        let total: Int
        let limit: Int
        let offset: Int
    }
}

//playlists created from spotify search (find playlists)
struct SpotifyPlaylistResponse: Codable {
    let id: String
    let name: String
    let description: String?
    let external_urls: ExternalUrls
    let uri: String
    
    struct ExternalUrls: Codable {
        let spotify: String
    }
}

//user profile struct
struct SpotifyUserProfile: Codable {
    let id: String
    let display_name: String?
    let email: String?
}

//ADDED
// added music attributes as a way to narrow down the search qualities for our Spotify search endpoint
struct MusicAttributes {
    let genres: [String]
    let keywords: [String]
    let energy: EnergyLevel
    let valence: ValenceLevel
    let tempo: TempoLevel
    
    //what energy level do we want in the song?
    enum EnergyLevel {
        case veryLow, low, medium, high, veryHigh
    }
    
    //what positivity level do we want in the song? (more valence = happy)
    enum ValenceLevel {
        case low, mediumLow, medium, high
    }
    
    //what tempo level do we want in the song?
    enum TempoLevel {
        case verySlow, slow, medium, fast, veryFast
    }
}

//handle errors that result from the API not working
enum SpotifyAPIError: LocalizedError {
    case noAccessToken
    case invalidURL
    case noData
    case requestFailed
    case noTracksFound
    case playlistCreationFailed
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .noAccessToken:
            return "No Spotify access token. Please log in!"
        case .invalidURL:
            return "Invalid API URL."
        case .noData:
            return "No data received from Spotify."
        case .requestFailed:
            return "Request to Spotify failed."
        case .noTracksFound:
            return "No tracks found matching your criteria"
        case .playlistCreationFailed:
            return "Failed to create playlist."
        default:
            return "Spotify API Error"
        }
    }
}
