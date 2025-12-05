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
    
    var currentUserId: String {
        return Auth.auth().currentUser?.uid ?? UUID().uuidString
    }
    
    private init() {
        // CRITICAL FIX: Sign out on launch to force a UNIQUE ID for every simulator run
        try? Auth.auth().signOut()
        
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let err = error { print("Auth Error: \(err)") }
                else { print("✅ Signed in as NEW user: \(result?.user.uid ?? "Unknown")") }
            }
        }
    }
    
    // MARK: - Create
    func createGroup(userName: String, completion: @escaping (LocalGroup?) -> Void) {
        let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        let code = String((0..<5).map { _ in chars.randomElement()! })
        
        let host = GroupMember(id: currentUserId, name: userName, emoji: "😎", isHost: true, isReady: false)
        
        let groupData: [String: Any] = [
            "createdAt": FieldValue.serverTimestamp(),
            "status": "waiting",
            "members": [host.toDict]
        ]
        
        db.collection("groups").document(code).setData(groupData) { error in
            if let error = error {
                completion(nil)
            } else {
                let newGroup = LocalGroup(sessionCode: code, members: [host])
                completion(newGroup)
            }
        }
    }

    // MARK: - Join
    func joinGroup(code: String, userName: String, emoji: String, completion: @escaping (LocalGroup?) -> Void) {
        let groupRef = db.collection("groups").document(code)
        
        groupRef.getDocument { [weak self] snapshot, error in
            guard let self = self, let snapshot = snapshot, snapshot.exists else {
                completion(nil)
                return
            }
            
            let newMember = GroupMember(id: self.currentUserId, name: userName, emoji: emoji, isHost: false, isReady: false)
            
            groupRef.updateData([
                "members": FieldValue.arrayUnion([newMember.toDict])
            ]) { error in
                if error != nil {
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
    
    // MARK: - Real-time Sync
    func listenToGroup(code: String, onChange: @escaping (LocalGroup) -> Void) {
        listener?.remove()
        listener = db.collection("groups").document(code).addSnapshotListener { snapshot, error in
            guard let snapshot = snapshot, snapshot.exists,
                  let group = LocalGroup(document: snapshot) else { return }
            DispatchQueue.main.async { onChange(group) }
        }
    }
    
    func stopListening() { listener?.remove() }
    
    // MARK: - Actions
    func updateMyState(code: String, emoji: String, isReady: Bool) {
        let groupRef = db.collection("groups").document(code)
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do { snapshot = try transaction.getDocument(groupRef) } catch let nserror as NSError {
                errorPointer?.pointee = nserror
                return nil
            }
            
            guard var members = snapshot.data()?["members"] as? [[String: Any]] else { return nil }
            
            for (i, m) in members.enumerated() {
                if let id = m["id"] as? String, id == self.currentUserId {
                    var updated = m
                    updated["emoji"] = emoji
                    updated["isReady"] = isReady
                    members[i] = updated
                    break
                }
            }
            transaction.updateData(["members": members], forDocument: groupRef)
            return nil
        }) { _, _ in }
    }
    
    func startSession(code: String) {
        db.collection("groups").document(code).updateData(["status": "started"])
    }
    
    func leaveGroup(code: String, completion: @escaping () -> Void) {
        let groupRef = db.collection("groups").document(code)
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do { snapshot = try transaction.getDocument(groupRef) } catch let nserror as NSError {
                errorPointer?.pointee = nserror
                return nil
            }
            guard var members = snapshot.data()?["members"] as? [[String: Any]] else { return nil }
            members.removeAll { ($0["id"] as? String) == self.currentUserId }
            transaction.updateData(["members": members], forDocument: groupRef)
            return nil
        }) { _, _ in completion() }
    }
}
