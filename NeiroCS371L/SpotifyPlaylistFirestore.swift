//
//  SpotifyPlaylistFirestore.swift
//  NeiroCS371L
//
//  Created by Allison Still on 11/8/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class SpotifyPlaylistFirestore {
    static let shared = SpotifyPlaylistFirestore()
    private init() {}
    
    private let db = Firestore.firestore()
    private let playlistsCollection = "playlists"
    
    func savePlaylist(_ playlist: Playlist, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "SpotifyPlaylistFirestore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }
        
        let playlistData = playlistToDict(playlist, userID: userID)
        
        db.collection(playlistsCollection).document(playlist.id.uuidString).setData(playlistData) { error in
            
            if let error = error {
                completion(.failure(error))
            } else {
                print("Playlist saved!")
                completion(.success(()))
            }
            
        }
        
    }
    
    func loadUserPlaylists(completion: @escaping (Result<[Playlist], Error>) -> Void) {
        
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "SpotifyPlaylistFirestore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }
        
        db.collection(playlistsCollection).whereField("userID", isEqualTo: userID).order(by: "createdAt", descending: true).getDocuments { snapshot, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success([]))
                return
            }
            
            let playlists = documents.compactMap { doc -> Playlist? in
                return self.dictToPlaylist(doc.data())
            }
            
            print("Loaded: \(playlists.count) playlists from Firebase")
            completion(.success(playlists))
        }
    }
    
    func deletePlaylist(_ playlist: Playlist, completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard Auth.auth().currentUser?.uid != nil else {
            completion(.failure(NSError(domain: "SpotifyPlaylistFirestore", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }
        
        db.collection(playlistsCollection).document(playlist.id.uuidString).delete { error in
            if let error = error {
                completion(.failure(error))
            } else {
                print("Playlist deleted: \(playlist.title)")
                completion(.success(()))
            }
        }
    }
    
    func updatePlaylist(_ playlist: Playlist, completion: @escaping (Result<Void, Error>) -> Void) {
        savePlaylist(playlist, completion: completion)
    }
    
    func clearAllUserPlaylists(completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion(.failure(NSError(domain: "FirebasePlaylistManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "No user logged in"])))
            return
        }
        
        db.collection(playlistsCollection).whereField("userID", isEqualTo: userID).getDocuments { snapshot, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let documents = snapshot?.documents else {
                completion(.success(()))
                return
            }
            
            let batch = self.db.batch()
            for doc in documents {
                batch.deleteDocument(doc.reference)
            }
            
            batch.commit { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    print("All playlists cleared from Firebase")
                    completion(.success(()))
                }
            }
        }
    }
    
    private func playlistToDict(_ playlist: Playlist, userID: String) -> [String: Any] {
        
        var dict: [String: Any] = [
            "id": playlist.id.uuidString,
            "userID": userID,
            "title": playlist.title,
            "emoji": playlist.emoji,
            "createdAt": Timestamp(date: playlist.createdAt),
            "songs": playlist.songs.map { songToDict($0) }
        ]
        return dict
    }
    
    private func songToDict(_ song: Song) -> [String: Any] {
        var dict: [String: Any] = [
            "id": song.id.uuidString,
            "title": song.title
        ]
        
        if let artist = song.artist { dict["artist"] = artist }
        if let album = song.album { dict["album"] = album }
        if let genre = song.genre { dict["genre"] = genre }
        if let length = song.lengthSeconds { dict["lengthSeconds"] = length }
        if let albumURL = song.albumURL { dict["albumURL"] = albumURL }
        
        return dict
    }
    
    private func dictToPlaylist(_ dict: [String: Any]) -> Playlist? {
        guard let idString = dict["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = dict["title"] as? String,
              let emoji = dict["emoji"] as? String,
              let timestamp = dict["createdAt"] as? Timestamp else {
            return nil
        }
        
        let createdAt = timestamp.dateValue()
        let songsData = dict["songs"] as? [[String: Any]] ?? []
        let songs = songsData.compactMap {dictToSong($0) }
        let playlist = Playlist(id: id, title: title, emoji: emoji, createdAt: createdAt, songs: songs)
        return playlist
    }
    
    private func dictToSong(_ dict: [String: Any]) -> Song? {
        guard let title = dict["title"] as? String else {return nil}
        let artist = dict["artist"] as? String
        let album = dict["album"] as? String
        let genre = dict["genre"] as? String
        let lengthSeconds = dict["lengthSeconds"] as? Int
        let albumURL = dict["albumURL"] as? String
        
        return Song(title: title, artist: artist, album: album, genre: genre, lengthSeconds: lengthSeconds, albumURL: albumURL)
    }
}
