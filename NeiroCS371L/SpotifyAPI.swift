//
//  SpotifyAPI.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/3/25.
//

import Foundation

class SpotifyAPI {
    static let shared = SpotifyAPI()
    private init() {}
    
    
    //base url for API
    private let baseURL = "https://api.spotify.com/v1"
    
    //get accessToken (might need to be refreshed) from SpotifyUserAuth
    private func getAccessToken() -> String? {
        return SpotifyUserAuthorization.shared.accessToken
    }
    
    private func isAuthenticated() -> Bool {
        return SpotifyUserAuthorization.shared.isConnected
    }
    
    //mapping emojis to musical attributes
    private func getMusicAttributes(for emoji: String) -> MusicAttributes {
        switch emoji {
            
        // Happy
        // high energy, positivity, fast tempo
        case "😀", "😃", "😄", "😁":
            return MusicAttributes(
                genres: ["pop", "dance", "happy"],
                keywords: ["happy", "upbeat", "cheerful", "fun", "positive"],
                energy: .high,
                valence: .high,
                tempo: .fast
            )
            
        // Chill
        // medium energy, medium positivity/sadness, medium tempo
        // middle of the road
        case "😎":
            return MusicAttributes(
                genres: ["chill", "indie", "electronic"],
                keywords: ["chill", "cool", "smooth", "laid-back", "relaxed"],
                energy: .medium,
                valence: .medium,
                tempo: .medium
            )
            
        // Thinking (possibly study?)
        // low energy, low tempo, medium postivity (nothing too sad)
        case "🤔":
            return MusicAttributes(
                genres: ["ambient", "classical", "instrumental"],
                keywords: ["thoughtful", "contemplative", "peaceful", "calm", "focus"],
                energy: .low,
                valence: .medium,
                tempo: .slow
            )
            
        // Bittersweet
        // possibly nostalgic music
        // medium tempo + energy, medium to low positivity
        case "🥲":
            return MusicAttributes(
                genres: ["indie", "folk", "acoustic"],
                keywords: ["bittersweet", "melancholic", "nostalgic", "emotional"],
                energy: .medium,
                valence: .mediumLow,
                tempo: .medium
            )
            
        // Sad
        // low energy, slow, positivity
        case "😭", "😢":
            return MusicAttributes(
                genres: ["sad", "acoustic", "indie"],
                keywords: ["sad", "emotional", "heartbreak", "melancholy", "slow"],
                energy: .low,
                valence: .low,
                tempo: .slow
            )
            
        // party
        // high energy, high positivity, VERY FAST tempo
        case "🤪":
            return MusicAttributes(
                genres: ["edm", "party", "dance"],
                keywords: ["party", "energetic", "wild", "crazy", "dance"],
                energy: .high,
                valence: .high,
                tempo: .veryFast
            )
            
        // happy/funny/upbeat
        //similar to happy above
        case "😂", "🤣":
            return MusicAttributes(
                genres: ["pop", "upbeat", "fun"],
                keywords: ["fun", "happy", "carefree", "upbeat", "lively"],
                energy: .high,
                valence: .high,
                tempo: .fast
            )
            
        // love or romantic
        // high positivity, and medium energy or tempo
        case "😍", "🥰", "❤️":
            return MusicAttributes(
                genres: ["love", "r&b", "soul"],
                keywords: ["love", "romantic", "passion", "heart", "sweet"],
                energy: .medium,
                valence: .high,
                tempo: .medium
            )
            
        // tired/sleep
        // medium positivity, but very slow energy and tempo
        case "😴", "🥱":
            return MusicAttributes(
                genres: ["ambient", "sleep", "calm"],
                keywords: ["sleep", "calm", "peaceful", "quiet", "soft"],
                energy: .veryLow,
                valence: .medium,
                tempo: .verySlow
            )
            
        // nervous -> needs calm music
        // medium positivity, but slow-ish tempo and low energy
        case "😰", "😨":
            return MusicAttributes(
                genres: ["ambient", "calm", "meditative"],
                keywords: ["calm", "peaceful", "soothing", "relaxing", "breathe"],
                energy: .low,
                valence: .medium,
                tempo: .slow
            )
            
        // angry (possibly metal?)
        case "😠", "😡":
            return MusicAttributes(
                genres: ["rock", "metal", "aggressive"],
                keywords: ["aggressive", "intense", "powerful", "angry", "hard"],
                energy: .veryHigh,
                valence: .low,
                tempo: .fast
            )
            
        // relaxed/calming
        // high positivity, but slow and low tempo/energy
        case "😌":
            return MusicAttributes(
                genres: ["ambient", "chill", "acoustic"],
                keywords: ["peaceful", "relaxed", "serene", "tranquil", "gentle"],
                energy: .low,
                valence: .high,
                tempo: .slow
            )
            
        // Energetic (could be workout?)
        // very high positivity, tempo, and energy
        case "⚡", "🔥":
            return MusicAttributes(
                genres: ["workout", "edm", "rock"],
                keywords: ["energetic", "powerful", "intense", "workout", "pump"],
                energy: .veryHigh,
                valence: .high,
                tempo: .veryFast
            )
            
        // default just returns the most popular music
        default:
            return MusicAttributes(
                genres: ["pop", "indie", "alternative"],
                keywords: ["popular", "trending", "top", "best"],
                energy: .medium,
                valence: .medium,
                tempo: .medium
            )
        }
    }

    // based on a given emoji, generate a playlist
    // by default, number of songs is 10 (medium playlist length)
    func generatePlaylist(
        for emoji: String,
        targetSongCount: Int = 10,
        excludedGenres: [String] = [],
        completion: @escaping (Result<[Song], Error>) -> Void
    ) {
        guard isAuthenticated() else {
            completion(.failure(SpotifyAPIError.noAccessToken))
            return
        }
        
        //get music attributes based on the chosen emoji
        let attributes = getMusicAttributes(for: emoji)
        var allTracks: [SpotifyTrack] = []
        let group = DispatchGroup()
        
        // filter out excluded genres
        let availableGenres = attributes.genres.filter { genre in
            !excludedGenres.contains(where: { excluded in
                genre.lowercased().contains(excluded.lowercased())
            })
        }
        
        let baseGenres = availableGenres.isEmpty ? ["pop", "indie", "rock"] : availableGenres
        
        // creating an array of search terms (based on attributes and genres that are still included/available)
        //let searchTerms = Array((attributes.keywords.prefix(3) + availableGenres.prefix(2)))
        let searchTerms = Array(baseGenres.shuffled().prefix(4))
        
        // search a couple times to generate a playlist
        for term in searchTerms {
            group.enter()
            searchTracks(query: term, limit: 10) { result in
                switch result {
                case .success(let tracks):
                    allTracks.append(contentsOf: tracks)
                case .failure(let error):
                    print("Search failed for '\(term)': \(error.localizedDescription)")
                }
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            
            //remove duplicates from the playlist
            var uniqueTracks: [SpotifyTrack] = []
            var seenIDs = Set<String>()
            
            for track in allTracks {
                if !seenIDs.contains(track.id) {
                    uniqueTracks.append(track)
                    seenIDs.insert(track.id)
                }
            }
            
            let checkUniqueTracks: [SpotifyTrack] = Dictionary(
                grouping: uniqueTracks,
                by: { track in
                    let title = track.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                    let artist = track.artists.first?.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
                    return "\(title)__\(artist)"
                }
            ).compactMap {$0.value.first} // only keep one version of duplicated songs
            
            // shuffle playlist so we get diff sources
            // limit to the number of target songs we want
            let selectedTracks = Array(checkUniqueTracks.shuffled().prefix(targetSongCount))
            
            // convert to Song objects
            let songs = selectedTracks.map { $0.toSong() }
            
            if songs.isEmpty {
                completion(.failure(SpotifyAPIError.noTracksFound))
            } else {
                completion(.success(songs))
            }
        }
    }
    
    // search tracks, develop search query, and use search API endpoint
    func searchTracks(
        query: String,
        limit: Int = 10,
        offset: Int = 0,
        completion: @escaping (Result<[SpotifyTrack], Error>) -> Void
    ) {
        guard let token = getAccessToken() else {
            completion(.failure(SpotifyAPIError.noAccessToken))
            return
        }
        
        // creating search query to use the Spotify API endpoint
        // TODO: if this is failing -- look here: https://developer.spotify.com/documentation/web-api/reference/search
        var components = URLComponents(string: "\(baseURL)/search")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "type", value: "track"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "offset", value: "\(offset)")
        ]
        
        //generate url based on query components
        guard let url = components?.url else {
            completion(.failure(SpotifyAPIError.invalidURL))
            return
        }
        
        //make GET request (API search request)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(SpotifyAPIError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(SpotifyAPIError.noData))
                return
            }
            
            //try to decode into SpotifySearchResponse
            do {
                let searchResponse = try JSONDecoder().decode(SpotifySearchResponse.self, from: data)
                completion(.success(searchResponse.tracks.items))
            } catch {
                completion(.failure(SpotifyAPIError.decodingError(error)))
            }
        }.resume()
    }
    
    // get current user's Spotify profile
    func getCurrentUserProfile(completion: @escaping (Result<SpotifyUserProfile, Error>) -> Void) {
        guard let token = getAccessToken() else {
            completion(.failure(SpotifyAPIError.noAccessToken))
            return
        }
        
        //the "me" endpoint returns current user's info
        let endpoint = "\(baseURL)/me"
        guard let url = URL(string: endpoint) else {
            completion(.failure(SpotifyAPIError.invalidURL))
            return
        }
        
        //make GET request
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        //network call
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(SpotifyAPIError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(SpotifyAPIError.noData))
                return
            }
            
            //try to decode into SpotifyUserProfile
            do {
                let profile = try JSONDecoder().decode(SpotifyUserProfile.self, from: data)
                completion(.success(profile))
            } catch {
                completion(.failure(SpotifyAPIError.decodingError(error)))
            }
        }.resume()
    }
    
    //create/generate a playlist in the current user's account
    //needs valid access token
    func createPlaylist(
        name: String,
        description: String,
        isPublic: Bool = false,
        completion: @escaping (Result<SpotifyPlaylistResponse, Error>) -> Void
    ) {
        guard let token = getAccessToken() else {
            completion(.failure(SpotifyAPIError.noAccessToken))
            return
        }
        
        // Use the user ID from existing auth
        guard let userID = SpotifyUserAuthorization.shared.spotifyUserID else {
            completion(.failure(SpotifyAPIError.noAccessToken))
            return
        }
        
        //use user/playlists endpoint to POST a playlist here
        let endpoint = "\(baseURL)/users/\(userID)/playlists"
        guard let url = URL(string: endpoint) else {
            completion(.failure(SpotifyAPIError.invalidURL))
            return
        }
        
        //make POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //request body
        let body: [String: Any] = [
            "name": name,
            "description": description,
            "public": isPublic
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        //make API call to create playlist
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(SpotifyAPIError.networkError(error)))
                return
            }
            
            guard let data = data else {
                completion(.failure(SpotifyAPIError.noData))
                return
            }
            
            //attempt to decode response into SpotifyPlaylistResponse
            do {
                let playlist = try JSONDecoder().decode(SpotifyPlaylistResponse.self, from: data)
                completion(.success(playlist))
            } catch {
                completion(.failure(SpotifyAPIError.decodingError(error)))
            }
        }.resume()
    }
    
    // updating the playlist (adding tracks/songs)
    //needs track URIs!!
    func addTracksToPlaylist(
        playlistId: String,
        trackURIs: [String],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard let token = getAccessToken() else {
            completion(.failure(SpotifyAPIError.noAccessToken))
            return
        }
        
        //api endpoint to add tracks to a specific playlist based on playlist id
        let endpoint = "\(baseURL)/playlists/\(playlistId)/tracks"
        guard let url = URL(string: endpoint) else {
            completion(.failure(SpotifyAPIError.invalidURL))
            return
        }
        
        //create POST request with track uri(s)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        //request body
        let body: [String: Any] = ["uris": trackURIs]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        //make API request to add songs
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(SpotifyAPIError.networkError(error)))
                return
            }
            
            //if the status code is a 200-number (typically 200 or 201), success!
            if let httpResponse = response as? HTTPURLResponse,
               (200...299).contains(httpResponse.statusCode) {
                completion(.success(()))
            } else {
                completion(.failure(SpotifyAPIError.requestFailed))
            }
        }.resume()
    }
    

    //exporting playlist back to Spotify
    // recreates this playlist on Spotify by searching for Spotify song URIs
    func exportPlaylist(
        playlist: Playlist,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard isAuthenticated() else {
            completion(.failure(SpotifyAPIError.noAccessToken))
            return
        }
        
        // Create playlist name/description
        let playlistName = "\(playlist.emoji) \(playlist.title)"
        let description = "Created by Neiro • \(playlist.songCount) songs"
        
        //call createPlaylist to generate new playlist on Spotify
        createPlaylist(name: playlistName, description: description, isPublic: false) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let spotifyPlaylist):
                // Need to search for each song to get URIs
                // Call getTrackURIs (helper)
                self.getTrackURIs(for: playlist.songs) { uriResult in
                    switch uriResult {
                    case .success(let uris):
                        // Add tracks to playlist
                        self.addTracksToPlaylist(playlistId: spotifyPlaylist.id, trackURIs: uris) { addResult in
                            switch addResult {
                                
                                //return the link to the Spotify playlist
                            case .success():
                                completion(.success(spotifyPlaylist.external_urls.spotify))
                            case .failure(let error):
                                completion(.failure(error))
                            }
                        }
                    case .failure(let error):
                        completion(.failure(error))
                    }
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    //helper function to get all of the track uris for songs on a playlist
    // used to help export Neiro playlist to spotify
    private func getTrackURIs(for songs: [Song], completion: @escaping (Result<[String], Error>) -> Void) {
        var uris: [String] = []
        let group = DispatchGroup()
        
        //Spotify limit is 100! do not exceed!
        //our most is about 40, so 50 for safe-keeping
        for song in songs.prefix(50) {
            group.enter()
            
            //search tracks based on query (song title + artist so we don't get songs of the same name by different people)
            let query = "\(song.title) \(song.artist ?? "")"
            searchTracks(query: query, limit: 1) { result in
                
                //add uri of first matching track to list of uris
                if case .success(let tracks) = result, let track = tracks.first {
                    uris.append(track.uri)
                }
                group.leave()
            }
        }
        
        // return list of found URIs
        group.notify(queue: .main) {
            if uris.isEmpty {
                completion(.failure(SpotifyAPIError.noTracksFound))
            } else {
                completion(.success(uris))
            }
        }
    }
}
