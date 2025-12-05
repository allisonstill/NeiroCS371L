//
//  ListenBrainz.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 12/3/25.
//

import Foundation

enum ListenBrainzError: LocalizedError {
    case invalidURL
    case requestFailed
    case noData
    case decodingError(Error)
    case noRecordingsFound
    case noTracksFound

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "ListenBrainz: Invalid URL."
        case .requestFailed:
            return "ListenBrainz: Request failed."
        case .noData:
            return "ListenBrainz: No data received."
        case .decodingError(let err):
            return "ListenBrainz: Failed to decode response: \(err.localizedDescription)"
        case .noRecordingsFound:
            return "ListenBrainz: No recordings returned for these tags."
        case .noTracksFound:
            return "ListenBrainz: Could not match any recordings to Spotify tracks."
        }
    }
}

// Single LB radio recording row from /1/lb-radio/tags
struct LBRadioTagsRecording: Codable {
    let percent: Double
    let recording_mbid: String
    let source: String
    let tag_count: Int
}

// Response row from Labs spotify-id-from-mbid/json
struct LabsSpotifyMatch: Codable {
    let recording_mbid: String
    let artist_name: String
    let release_name: String?
    let track_name: String
    let spotify_track_ids: [String]
}

// Internal helper to represent a track before we hit Spotify
private struct LBTrackSeed: Hashable {
    let title: String
    let artist: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(title.lowercased())
        hasher.combine(artist.lowercased())
    }

    static func == (lhs: LBTrackSeed, rhs: LBTrackSeed) -> Bool {
        lhs.title.caseInsensitiveCompare(rhs.title) == .orderedSame &&
        lhs.artist.caseInsensitiveCompare(rhs.artist) == .orderedSame
    }
}

// Emoji → ListenBrainz tag config
private struct EmojiRadioConfig {
    let tags: [String]
}

class ListenBrainzAPI {
    
    static let shared = ListenBrainzAPI()
    private init() {}
    
    private let baseURL = "https://api.listenbrainz.org/1"
    private let labsBaseURL = "https://labs.api.listenbrainz.org"
    private let userToken = "6ee83b70-d989-4386-8fd1-e6e817b9344f"
    
    // Approximate "easy" mode by using more popular recordings (higher popularity window)
    private let easyPopBegin = 80
    private let easyPopEnd = 100
    
    // Map emoji → tags
    private func config(for emoji: String) -> EmojiRadioConfig {
        switch emoji {
        case "😀", "😃", "😄", "😁":
            return EmojiRadioConfig(tags: ["happy", "pop", "dance", "upbeat"])
        case "😎":
            return EmojiRadioConfig(tags: ["chill", "downtempo", "lo-fi", "electronic"])
        case "🤔":
            return EmojiRadioConfig(tags: ["ambient", "focus", "study", "instrumental"])
        case "🥲":
            return EmojiRadioConfig(tags: ["bittersweet", "indie", "folk", "nostalgic"])
        case "😭", "😢":
            return EmojiRadioConfig(tags: ["sad", "melancholy", "heartbreak", "acoustic"])
        case "🤪":
            return EmojiRadioConfig(tags: ["party", "edm", "dance", "club"])
        case "😂", "🤣":
            return EmojiRadioConfig(tags: ["fun", "happy", "upbeat", "pop"])
        case "😍", "🥰", "❤️":
            return EmojiRadioConfig(tags: ["love", "romantic", "r&b", "soul"])
        case "😴", "🥱":
            return EmojiRadioConfig(tags: ["sleep", "calm", "ambient", "chill"])
        case "😰", "😨":
            return EmojiRadioConfig(tags: ["calm", "meditative", "relax", "soothing"])
        case "😠", "😡":
            return EmojiRadioConfig(tags: ["metal", "rock", "aggressive"])
        case "😌":
            return EmojiRadioConfig(tags: ["relax", "serene", "acoustic", "chill"])
        case "⚡", "🔥":
            return EmojiRadioConfig(tags: ["workout", "edm", "rock", "high energy"])
        default:
            return EmojiRadioConfig(tags: ["pop", "indie", "alternative"])
        }
    }
    
    // Public entry point: emoji → [Song] using LB radio + Labs + Spotify search
    func generateSongsFromEmoji(
        _ emoji: String,
        targetSongCount: Int = 10,
        completion: @escaping (Result<[Song], Error>) -> Void
    ) {
        
        // Make sure Spotify is connected first
        guard SpotifyUserAuthorization.shared.isConnected else {
            completion(.failure(SpotifyAPIError.noAccessToken))
            return
        }
        
        let overfetchFactor = 4
        let desiredRecordings = max(targetSongCount * overfetchFactor, targetSongCount)
        
        fetchRadioRecordings(for: emoji, count: desiredRecordings) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                completion(.failure(error))
                
            case .success(let mbids):
                if mbids.isEmpty {
                    completion(.failure(ListenBrainzError.noRecordingsFound))
                    return
                }
                
                self.fetchTrackSeeds(for: mbids) { seedsResult in
                    switch seedsResult {
                    case .failure(let error):
                        completion(.failure(error))
                        
                    case .success(let seeds):
                        if seeds.isEmpty {
                            completion(.failure(ListenBrainzError.noTracksFound))
                            return
                        }
                        
                        self.resolveSeedsViaSpotify(
                            seeds: seeds,
                            targetSongCount: targetSongCount,
                            completion: completion
                        )
                    }
                }
            }
        }
    }
    
    // Step 1: call /1/lb-radio/tags to get a bunch of recording_mbids
    private func fetchRadioRecordings(
        for emoji: String,
        count: Int,
        completion: @escaping (Result<[String], Error>) -> Void
    ) {
        let cfg = config(for: emoji)
        
        guard var components = URLComponents(string: "\(baseURL)/lb-radio/tags") else {
            completion(.failure(ListenBrainzError.invalidURL))
            return
        }
        
        var items: [URLQueryItem] = []
        
        for tag in cfg.tags {
            items.append(URLQueryItem(name: "tag", value: tag))
        }
        
        items.append(URLQueryItem(name: "operator", value: "OR"))
        
        items.append(URLQueryItem(name: "pop_begin", value: "\(easyPopBegin)"))
        items.append(URLQueryItem(name: "pop_end", value: "\(easyPopEnd)"))
        
        items.append(URLQueryItem(name: "count", value: "\(count)"))
        
        components.queryItems = items
        
        guard let url = components.url else {
            completion(.failure(ListenBrainzError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(ListenBrainzError.requestFailed))
                print("LB tags request error: \(error)")
                return
            }
            
            guard let data = data else {
                completion(.failure(ListenBrainzError.noData))
                return
            }
            
            do {
                let recordings = try JSONDecoder().decode([LBRadioTagsRecording].self, from: data)
                
                if recordings.isEmpty {
                    if let raw = String(data: data, encoding: .utf8) {
                        print("LB tags returned empty recordings. Raw JSON:\n\(raw)")
                    }
                    completion(.success([]))
                    return
                }
                
                let mbids = recordings.map { $0.recording_mbid }
                completion(.success(mbids))
            } catch {
                completion(.failure(ListenBrainzError.decodingError(error)))
            }
        }.resume()
    }
    
    // Step 2: for each MBID, ask Labs for track_name + artist_name
    private func fetchTrackSeeds(
        for recordingMBIDs: [String],
        completion: @escaping (Result<Set<LBTrackSeed>, Error>) -> Void
    ) {
        let group = DispatchGroup()
        var seeds = Set<LBTrackSeed>()
        var firstError: Error?
        
        for mbid in recordingMBIDs {
            group.enter()
            fetchLabsTrackMetadata(for: mbid) { result in
                defer { group.leave() }
                
                switch result {
                case .failure(let error):
                    if firstError == nil {
                        firstError = error
                    }
                    
                case .success(let matchOpt):
                    guard let match = matchOpt else { return }
                    
                    let title = match.track_name.trimmingCharacters(in: .whitespacesAndNewlines)
                    let artist = match.artist_name.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    guard !title.isEmpty, !artist.isEmpty else { return }
                    
                    let seed = LBTrackSeed(title: title, artist: artist)
                    seeds.insert(seed)
                }
            }
        }
        
        group.notify(queue: .global(qos: .userInitiated)) {
            if seeds.isEmpty, let error = firstError {
                completion(.failure(error))
            } else {
                completion(.success(seeds))
            }
        }
    }
    
    private func fetchLabsTrackMetadata(
        for mbid: String,
        completion: @escaping (Result<LabsSpotifyMatch?, Error>) -> Void
    ) {
        guard var components = URLComponents(string: "\(labsBaseURL)/spotify-id-from-mbid/json") else {
            completion(.failure(ListenBrainzError.invalidURL))
            return
        }
        
        components.queryItems = [
            URLQueryItem(name: "recording_mbid", value: mbid)
        ]
        
        guard let url = components.url else {
            completion(.failure(ListenBrainzError.invalidURL))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Token \(userToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(ListenBrainzError.requestFailed))
                print("Labs error for mbid \(mbid): \(error)")
                return
            }
            
            guard let http = response as? HTTPURLResponse else {
                completion(.failure(ListenBrainzError.requestFailed))
                return
            }
            
            guard (200...299).contains(http.statusCode) else {
                if let data = data, let raw = String(data: data, encoding: .utf8) {
                    print("Labs spotify-id-from-mbid HTTP \(http.statusCode) for mbid \(mbid):\n\(raw)")
                } else {
                    print("Labs spotify-id-from-mbid HTTP \(http.statusCode) for mbid \(mbid)")
                }
                completion(.success(nil))
                return
            }
            
            guard let data = data else {
                completion(.failure(ListenBrainzError.noData))
                return
            }
            
            do {
                let matches = try JSONDecoder().decode([LabsSpotifyMatch].self, from: data)
                let first = matches.first
                completion(.success(first))
            } catch {
                print("Labs decode error for mbid \(mbid): \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("Labs raw body:\n\(raw)")
                }
                completion(.failure(ListenBrainzError.decodingError(error)))
            }
        }.resume()
    }
    
    // Step 3: use Spotify search to resolve seeds into Song models
    private func resolveSeedsViaSpotify(
        seeds: Set<LBTrackSeed>,
        targetSongCount: Int,
        completion: @escaping (Result<[Song], Error>) -> Void
    ) {
        var songs: [Song] = []
        var seen = Set<LBTrackSeed>()
        let group = DispatchGroup()
        
        // Don’t hammer Spotify with every LB seed; just use a reasonable subset.
        let seedsToUse = Array(seeds.shuffled().prefix(targetSongCount * 4))
        
        for seed in seedsToUse {
            group.enter()
            let query = "\(seed.title) \(seed.artist)"
            
            SpotifyAPI.shared.searchTracks(query: query, limit: 5, offset: 0) { result in
                defer { group.leave() }
                
                switch result {
                case .failure(let error):
                    print("Spotify search failed for '\(query)': \(error.localizedDescription)")
                    
                case .success(let tracks):
                    guard !tracks.isEmpty else { return }
                    
                    let targetTitle = seed.title.normalizedForCompare
                    let targetArtist = seed.artist.normalizedForCompare
                    
                    // Prefer an exact-ish match on normalized title & first artist
                    let bestTrack = tracks.first(where: { track in
                        let trackTitle = track.name.normalizedForCompare
                        let trackArtist = track.artists.first?.name.normalizedForCompare ?? ""
                        return trackTitle == targetTitle && trackArtist == targetArtist
                    }) ?? tracks.first
                    
                    guard let chosen = bestTrack else { return }
                    
                    let song = chosen.toSong()
                    let normSeed = LBTrackSeed(
                        title: song.title,
                        artist: song.artist ?? seed.artist
                    )
                    
                    if !seen.contains(normSeed) {
                        seen.insert(normSeed)
                        songs.append(song)
                    }
                }
            }
        }
        
        group.notify(queue: .main) {
            if songs.isEmpty {
                completion(.failure(ListenBrainzError.noTracksFound))
                return
            }
            
            let shuffled = songs.shuffled()
            let selected = Array(shuffled.prefix(targetSongCount))
            completion(.success(selected))
        }
    }
}

private extension String {
    var normalizedForCompare: String {
        // strip accents, lower-case, and remove most punctuation
        let folded = self.folding(options: .diacriticInsensitive, locale: .current)
        let lower = folded.lowercased()
        return lower.replacingOccurrences(
            of: #"[^\w\s]"#,
            with: "",
            options: .regularExpression
        )
    }
}
