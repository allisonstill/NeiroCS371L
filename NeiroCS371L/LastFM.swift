//
//  LastFM.swift
//  NeiroCS371L
//
//  Created by Jacob Mathew on 12/4/25.
//

import Foundation

enum LastFMError: LocalizedError {
    case invalidURL
    case requestFailed
    case noData
    case decodingError(Error)
    case noTracksReturned
    case noSpotifyMatches
    case notConnectedToSpotify

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Last.fm: Invalid URL."
        case .requestFailed:
            return "Last.fm: Request failed."
        case .noData:
            return "Last.fm: No data received."
        case .decodingError(let err):
            return "Last.fm: Failed to decode response: \(err.localizedDescription)"
        case .noTracksReturned:
            return "Last.fm: No tracks returned for these tags."
        case .noSpotifyMatches:
            return "Last.fm: Could not match any tracks to Spotify."
        case .notConnectedToSpotify:
            return "Spotify is not connected. Please log in first."
        }
    }
}

// MARK: - Last.fm JSON models

private struct LastFMTopTracksResponse: Codable {
    let tracks: LastFMTracksWrapper

    struct LastFMTracksWrapper: Codable {
        let track: [LastFMTrack]
        let attr: Attr?

        struct Attr: Codable {
            let tag: String?
            let page: String?
            let perPage: String?
            let totalPages: String?
            let total: String?

            enum CodingKeys: String, CodingKey {
                case tag
                case page
                case perPage
                case totalPages
                case total
            }
        }

        enum CodingKeys: String, CodingKey {
            case track
            case attr = "@attr"
        }
    }
}

private struct LastFMTrack: Codable {
    let name: String
    let artist: LastFMArtist

    struct LastFMArtist: Codable {
        let name: String
    }
}

// Track seed before Spotify search
private struct LastFMTrackSeed: Hashable {
    let title: String
    let artist: String

    func hash(into hasher: inout Hasher) {
        hasher.combine(title.lowercased())
        hasher.combine(artist.lowercased())
    }

    static func == (lhs: LastFMTrackSeed, rhs: LastFMTrackSeed) -> Bool {
        lhs.title.caseInsensitiveCompare(rhs.title) == .orderedSame &&
        lhs.artist.caseInsensitiveCompare(rhs.artist) == .orderedSame
    }
}

// MARK: - LastFM API wrapper

final class LastFMAPI {

    static let shared = LastFMAPI()
    private init() {}

    private let baseURL = "https://ws.audioscrobbler.com/2.0/"
    private let apiKey = "5f70428ef051d8b84463de91add0acba"

    // Limit per page when calling tag.getTopTracks
    private let pageLimit = 20

    // Public entry point
    func generateSongsFromEmoji(
        _ emoji: String,
        nicheness: Int = SessionStore.hipsterRating,
        songCount: Int = SessionStore.playlistMinutes / 3,
        excludedArtists: Set<String> = SessionStore.unwantedArtists,
        preferredArtists: Set<String> = SessionStore.preferredArtists,
        preferredGenres: Set<String> = SessionStore.preferredGenres,
        completion: @escaping (Result<[Song], Error>) -> Void
    ) {
        guard SpotifyUserAuthorization.shared.isConnected else {
            completion(.failure(LastFMError.notConnectedToSpotify))
            return
        }

        let clampedNicheness = max(1, min(10, nicheness))
        let tags = selectTags(for: emoji, preferredGenres: Array(preferredGenres))

        if tags.isEmpty {
            completion(.failure(LastFMError.noTracksReturned))
            return
        }

        // Distribute desired songs across tags as evenly as possible
        let perTagCounts = distribute(total: songCount, into: tags.count)

        let excludedSet = Set(excludedArtists.map { $0.lowercased() })
        let preferredArtistSet = Set(preferredArtists.map { $0.lowercased() })

        let group = DispatchGroup()
        var allSeeds: [LastFMTrackSeed] = []
        var firstError: Error?

        for (index, tag) in tags.enumerated() {
            let desiredForTag = perTagCounts[index]

            group.enter()
            collectSeedsForTag(
                tag: tag,
                nicheness: clampedNicheness,
                desiredCount: desiredForTag,
                excludedArtists: excludedSet
            ) { result in
                defer { group.leave() }

                switch result {
                case .failure(let error):
                    if firstError == nil {
                        firstError = error
                    }
                case .success(let seeds):
                    allSeeds.append(contentsOf: seeds)
                }
            }
        }

        group.notify(queue: .global(qos: .userInitiated)) { [weak self] in
            guard let self = self else { return }

            if allSeeds.isEmpty {
                completion(.failure(firstError ?? LastFMError.noTracksReturned))
                return
            }

            // Deduplicate seeds while keeping order
            var seen = Set<LastFMTrackSeed>()
            var uniqueSeeds: [LastFMTrackSeed] = []

            for seed in allSeeds {
                if !seen.contains(seed) {
                    seen.insert(seed)
                    uniqueSeeds.append(seed)
                }
            }

            // Reorder to prioritize preferred artists first
            let prioritized = uniqueSeeds.filter { preferredArtistSet.contains($0.artist.lowercased()) }
            let others = uniqueSeeds.filter { !preferredArtistSet.contains($0.artist.lowercased()) }
            let orderedSeeds = prioritized + others

            self.resolveSeedsViaSpotify(
                seeds: orderedSeeds,
                targetSongCount: songCount,
                excludedArtists: excludedSet,
                completion: completion
            )
        }
    }

    // MARK: - Tag selection

    private func selectTags(for emoji: String, preferredGenres: [String]) -> [String] {
        let emojiTags = emojiTagMap[emoji] ?? emojiTagMap["default"] ?? ["pop", "indie", "alternative"]

        var result: [String] = []
        var used = Set<String>()

        func addTagIfNew(_ tag: String) {
            let lower = tag.lowercased()
            guard !lower.isEmpty, !used.contains(lower) else { return }
            used.insert(lower)
            result.append(lower)
        }

        // First, preferred genres (user-configured)
        let shuffledPreferred = preferredGenres.shuffled()
        for tag in shuffledPreferred where result.count < 3 {
            addTagIfNew(tag)
        }

        // Then, emoji defaults
        let shuffledEmojiTags = emojiTags.shuffled()
        for tag in shuffledEmojiTags where result.count < 3 {
            addTagIfNew(tag)
        }

        // Fallback if somehow still empty
        if result.isEmpty {
            result = ["pop", "indie", "alternative"]
        }

        return Array(result.prefix(3))
    }

    // Map emoji → Last.fm tags (no ambiguous "chill"/"love" where possible)
    private let emojiTagMap: [String: [String]] = [
        // super happy / upbeat
        "😀": ["happy", "pop", "dance pop"],
        
        // cool / chill
        "😎": ["indie", "chill", "electronic"],
        
        // bittersweet / soft sad
        "🥲": ["indie folk", "singer-songwriter", "acoustic"],
        
        // full-on sad
        "😭": ["sad", "acoustic", "piano"],
        
        // chaotic / hyped
        "🤪": ["edm", "big room", "electro house"],
        
        // silly / fun
        "🤣": ["pop", "bubblegum pop", "dance pop"],
        
        // sleep / background
        "😴": ["calm", "ambient", "relaxing"],
        
        // neutral / background focus
        "😐": ["lo-fi", "chillhop", "background"],
        
        // relaxed / content
        "😌": ["acoustic", "mellow", "soft rock"],
        
        // gently upbeat
        "🙂": ["indie pop", "folk", "upbeat"],
        
        // confused / introspective
        "😕": ["alternative", "indie rock", "emo"],
        
        // worried / heavier sad
        "😟": ["emo", "sad", "post-rock"],
        
        // hype / intense
        "🔥": ["workout", "trap", "edm"],
        
        // love / romantic
        "❤️": ["romantic", "rnb", "soul"],
        
        // energetic / power up
        "⚡": ["workout", "rock", "electronic"],
        
        // fallback
        "default": ["pop", "indie", "alternative"]
    ]


    // MARK: - Per-tag seed collection

    private func collectSeedsForTag(
        tag: String,
        nicheness: Int,
        desiredCount: Int,
        excludedArtists: Set<String>,
        completion: @escaping (Result<[LastFMTrackSeed], Error>) -> Void
    ) {
        if desiredCount <= 0 {
            completion(.success([]))
            return
        }

        // First call page=1 to discover totalPages
        fetchTopTracks(tag: tag, page: 1, limit: pageLimit) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let firstPage):
                let totalPages = max(1, firstPage.totalPages)

                let startPage = self.startPage(forNicheness: nicheness, totalPages: totalPages)

                // Relative pages: 1st, 3rd, 6th after applying nicheness
                var pages: [Int] = []
                let candidates = [startPage, startPage + 2, startPage + 5]
                for p in candidates where p >= 1 && p <= totalPages {
                    if !pages.contains(p) {
                        pages.append(p)
                    }
                }

                if pages.isEmpty {
                    pages = [min(startPage, totalPages)]
                }

                // Distribute desiredCount across the pages
                let perPageCounts = self.distribute(total: desiredCount, into: pages.count)

                var tracksByPage: [Int: [LastFMTrack]] = [:]
                var firstError: Error?
                let group = DispatchGroup()

                for (index, page) in pages.enumerated() {
                    let samplesNeeded = perPageCounts[index]
                    guard samplesNeeded > 0 else { continue }

                    group.enter()

                    if page == 1 {
                        tracksByPage[1] = firstPage.tracks
                        group.leave()
                    } else {
                        self.fetchTopTracks(tag: tag, page: page, limit: self.pageLimit) { pageResult in
                            defer { group.leave() }

                            switch pageResult {
                            case .failure(let error):
                                if firstError == nil {
                                    firstError = error
                                }
                            case .success(let pageData):
                                tracksByPage[page] = pageData.tracks
                            }
                        }
                    }
                }

                group.notify(queue: .global(qos: .userInitiated)) {
                    var seeds: [LastFMTrackSeed] = []
                    var seen = Set<LastFMTrackSeed>()

                    for (index, page) in pages.enumerated() {
                        let wanted = perPageCounts[index]
                        guard wanted > 0,
                              let tracks = tracksByPage[page],
                              !tracks.isEmpty else { continue }

                        let chosen = Array(tracks.shuffled().prefix(min(wanted, tracks.count)))

                        for track in chosen {
                            let title = track.name.trimmingCharacters(in: .whitespacesAndNewlines)
                            let artist = track.artist.name.trimmingCharacters(in: .whitespacesAndNewlines)

                            guard !title.isEmpty, !artist.isEmpty else { continue }

                            if excludedArtists.contains(artist.lowercased()) {
                                continue
                            }

                            let seed = LastFMTrackSeed(title: title, artist: artist)
                            if !seen.contains(seed) {
                                seen.insert(seed)
                                seeds.append(seed)
                            }
                        }
                    }

                    if seeds.isEmpty {
                        completion(.failure(firstError ?? LastFMError.noTracksReturned))
                    } else {
                        completion(.success(seeds))
                    }
                }
            }
        }
    }

    private func startPage(forNicheness nicheness: Int, totalPages: Int) -> Int {
        if totalPages <= 1 { return 1 }
        let fraction = Double(nicheness - 1) / 10.0    // 1 → 0.0, 10 → 0.9
        let raw = Int(Double(totalPages) * fraction)
        return max(1, min(totalPages, raw == 0 ? 1 : raw))
    }

    // Split a total into n buckets as evenly as possible
    private func distribute(total: Int, into buckets: Int) -> [Int] {
        guard buckets > 0 else { return [] }
        let base = total / buckets
        let remainder = total % buckets

        var result: [Int] = []
        for i in 0..<buckets {
            let extra = i < remainder ? 1 : 0
            result.append(base + extra)
        }
        return result
    }

    // MARK: - Raw tag.getTopTracks call

    private struct TagTopTracksPage {
        let tracks: [LastFMTrack]
        let totalPages: Int
    }

    private func fetchTopTracks(
        tag: String,
        page: Int,
        limit: Int,
        completion: @escaping (Result<TagTopTracksPage, Error>) -> Void
    ) {
        guard var components = URLComponents(string: baseURL) else {
            completion(.failure(LastFMError.invalidURL))
            return
        }

        components.queryItems = [
            URLQueryItem(name: "method", value: "tag.gettoptracks"),
            URLQueryItem(name: "tag", value: tag),
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "format", value: "json"),
            URLQueryItem(name: "limit", value: "\(limit)"),
            URLQueryItem(name: "page", value: "\(page)")
        ]

        guard let url = components.url else {
            completion(.failure(LastFMError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Last.fm request error for tag \(tag), page \(page): \(error)")
                completion(.failure(LastFMError.requestFailed))
                return
            }

            guard let data = data else {
                completion(.failure(LastFMError.noData))
                return
            }

            do {
                let decoded = try JSONDecoder().decode(LastFMTopTracksResponse.self, from: data)
                let tracks = decoded.tracks.track

                let totalPagesStr = decoded.tracks.attr?.totalPages ?? "1"
                let totalPages = Int(totalPagesStr) ?? 1

                completion(.success(TagTopTracksPage(tracks: tracks, totalPages: totalPages)))
            } catch {
                print("Last.fm decode error for tag \(tag), page \(page): \(error)")
                if let raw = String(data: data, encoding: .utf8) {
                    print("Last.fm raw response:\n\(raw)")
                }
                completion(.failure(LastFMError.decodingError(error)))
            }
        }.resume()
    }

    // MARK: - Spotify resolution

    private func resolveSeedsViaSpotify(
        seeds: [LastFMTrackSeed],
        targetSongCount: Int,
        excludedArtists: Set<String>,
        completion: @escaping (Result<[Song], Error>) -> Void
    ) {
        var songs: [Song] = []
        var seen = Set<LastFMTrackSeed>()
        let group = DispatchGroup()

        for seed in seeds {
            group.enter()
            let query = "\(seed.title) \(seed.artist)"

            SpotifyAPI.shared.searchTracks(query: query, limit: 1, offset: 0) { result in
                defer { group.leave() }

                switch result {
                case .failure(let error):
                    print("Spotify search failed for '\(query)': \(error.localizedDescription)")

                case .success(let tracks):
                    guard let first = tracks.first else { return }
                    let song = first.toSong()

                    let artistName = song.artist ?? seed.artist
                    if excludedArtists.contains(artistName.lowercased()) {
                        return
                    }

                    let normSeed = LastFMTrackSeed(
                        title: song.title,
                        artist: artistName
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
                completion(.failure(LastFMError.noSpotifyMatches))
                return
            }

            let shuffled = songs.shuffled()
            let selected = Array(shuffled.prefix(targetSongCount))
            completion(.success(selected))
        }
    }
}
