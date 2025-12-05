//
//  GroupManager.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class GroupManager {
    static let shared = GroupManager()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    private init() {
        // STOP AUTO-LOGIN
        // We removed authenticate() here so the app stays logged out
        // until the user specifically logs in or joins a group.
    }
    
    // MARK: - Auth Helper
    private func authenticate(completion: ((String?) -> Void)? = nil) {
        if let user = Auth.auth().currentUser {
            completion?(user.uid)
        } else {
            // Only sign in anonymously if we absolutely have to (lazy login)
            Auth.auth().signInAnonymously { result, error in
                if let err = error {
                    print("❌ Auth Error: \(err.localizedDescription)")
                    completion?(nil)
                } else {
                    let uid = result?.user.uid ?? "Unknown"
                    print("✅ Signed in as NEW user: \(uid)")
                    completion?(uid)
                }
            }
        }
    }
    
    func ensureAuth(action: @escaping (String) -> Void) {
        authenticate { uid in
            guard let uid = uid else {
                print("❌ Operation aborted: User not authenticated.")
                return
            }
            action(uid)
        }
    }
    
    // MARK: - Create
    func createGroup(userName: String, completion: @escaping (LocalGroup?) -> Void) {
        ensureAuth { userId in
            let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
            let code = String((0..<5).map { _ in chars.randomElement()! })
            
            let host = GroupMember(id: userId, name: userName, emoji: "😎", isHost: true, isReady: false)
            
            let groupData: [String: Any] = [
                "createdAt": FieldValue.serverTimestamp(),
                "status": "waiting",
                "members": [host.toDict]
            ]
            
            self.db.collection("groups").document(code).setData(groupData) { error in
                if let error = error {
                    print("❌ Create Error: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    let newGroup = LocalGroup(sessionCode: code, members: [host])
                    completion(newGroup)
                }
            }
        }
    }

    // MARK: - Join
    func joinGroup(code: String, userName: String, emoji: String, completion: @escaping (LocalGroup?) -> Void) {
        ensureAuth { userId in
            let groupRef = self.db.collection("groups").document(code)
            
            groupRef.getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Firestore Read Error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let self = self, let snapshot = snapshot, snapshot.exists else {
                    print("❌ Error: Group Code \(code) not found.")
                    completion(nil)
                    return
                }
                
                let newMember = GroupMember(id: userId, name: userName, emoji: emoji, isHost: false, isReady: false)
                
                groupRef.updateData([
                    "members": FieldValue.arrayUnion([newMember.toDict])
                ]) { error in
                    if let error = error {
                        print("❌ Join/Update Error: \(error.localizedDescription)")
                        completion(nil)
                    } else {
                        groupRef.getDocument { updatedSnap, _ in
                            guard let updatedSnap = updatedSnap,
                                  let group = LocalGroup(document: updatedSnap) else { return }
                            completion(group)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Real-time Sync
    func listenToGroup(code: String, onChange: @escaping (LocalGroup) -> Void) {
        listener?.remove()
        listener = db.collection("groups").document(code).addSnapshotListener { snapshot, error in
            if let error = error {
                print("❌ Listener Error: \(error.localizedDescription)")
                return
            }
            guard let snapshot = snapshot, snapshot.exists,
                  let group = LocalGroup(document: snapshot) else { return }
            DispatchQueue.main.async { onChange(group) }
        }
    }
    
    func stopListening() { listener?.remove() }
    
    // MARK: - Actions
    func updateMyState(code: String, emoji: String, isReady: Bool) {
        ensureAuth { userId in
            let groupRef = self.db.collection("groups").document(code)
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let snapshot: DocumentSnapshot
                do { snapshot = try transaction.getDocument(groupRef) } catch let nserror as NSError {
                    errorPointer?.pointee = nserror
                    return nil
                }
                
                guard var members = snapshot.data()?["members"] as? [[String: Any]] else { return nil }
                
                for (i, m) in members.enumerated() {
                    if let id = m["id"] as? String, id == userId {
                        var updated = m
                        updated["emoji"] = emoji
                        updated["isReady"] = isReady
                        members[i] = updated
                        break
                    }
                }
                transaction.updateData(["members": members], forDocument: groupRef)
                return nil
            }) { _, error in
                if let error = error {
                    print("❌ Update State Error: \(error.localizedDescription)")
                }
            }
        }
    }
    
    // MARK: - SYNC FIX: Start Session with Playlist
    func startSessionWithSongs(code: String, songs: [Song]) {
        let songDicts = songs.map { $0.toDict }
        
        db.collection("groups").document(code).updateData([
            "status": "started",
            "sharedPlaylist": songDicts
        ]) { error in
            if let error = error {
                print("❌ Failed to start session: \(error.localizedDescription)")
            } else {
                print("✅ Session Started & Playlist Saved to DB")
            }
        }
    }
    
    func leaveGroup(code: String, completion: @escaping () -> Void) {
        ensureAuth { userId in
            let groupRef = self.db.collection("groups").document(code)
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let snapshot: DocumentSnapshot
                do { snapshot = try transaction.getDocument(groupRef) } catch let nserror as NSError {
                    errorPointer?.pointee = nserror
                    return nil
                }
                guard var members = snapshot.data()?["members"] as? [[String: Any]] else { return nil }
                
                members.removeAll { ($0["id"] as? String) == userId }
                
                transaction.updateData(["members": members], forDocument: groupRef)
                return nil
            }) { _, error in
                if let error = error {
                    print("❌ Leave Group Error: \(error.localizedDescription)")
                }
                completion()
            }
        }
    }
}
