//
//  GroupManager.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import Foundation
import FirebaseFirestore
import FirebaseAuth
import CoreLocation

class GroupManager {
    static let shared = GroupManager()
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var publicGroupsListener: ListenerRegistration?
    
    // Activity tracking
    private static let ACTIVITY_TIMEOUT: TimeInterval = 60 // if not active for 1 min, consider leaving
    
    var currentUserId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    private init() {
        // STOP AUTO-LOGIN
    }
    
    // MARK: - Auth Helper
    private func authenticate(completion: ((String?) -> Void)? = nil) {
        if let user = Auth.auth().currentUser {
            completion?(user.uid)
        } else {
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
    func createGroup(sessionName: String, isPublic: Bool, location: GeoPoint?, userName: String, completion: @escaping (LocalGroup?) -> Void) {
        ensureAuth { userId in
            let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
            let code = String((0..<5).map { _ in chars.randomElement()! })
            
            let host = GroupMember(id: userId, name: userName, emoji: "😎", isHost: true, isReady: false)
            
            var groupData: [String: Any] = [
                "createdAt": FieldValue.serverTimestamp(),
                "lastActivity": FieldValue.serverTimestamp(), // Track when host was last active
                "sessionName": sessionName,
                "isPublic": isPublic,
                "hostName": userName,
                "hostId": userId, // Track host ID
                "status": "waiting",
                "members": [host.toDict],
                "pendingRequests": []
            ]
            
            if let location = location {
                groupData["location"] = location
            }
            
            self.db.collection("groups").document(code).setData(groupData) { error in
                if let error = error {
                    print("Create Error: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    let newGroup = LocalGroup(
                        sessionCode: code,
                        sessionName: sessionName,
                        isPublic: isPublic,
                        location: location,
                        hostName: userName,
                        members: [host]
                    )
                    completion(newGroup)
                }
            }
        }
    }
    
    // MARK: - Activity Tracking
    
    func updateActivity(groupCode: String) {
        db.collection("groups").document(groupCode).updateData([
            "lastActivity": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Failed to update activity: \(error.localizedDescription)")
            }
        }
    }
    
    private func isGroupStale(_ document: DocumentSnapshot) -> Bool {
        guard let data = document.data(),
              let lastActivity = data["lastActivity"] as? Timestamp else {
            // No lastActivity means old group - consider it stale
            print("Group \(document.documentID) has no lastActivity timestamp yet - treating as fresh")
            return false
        }
        
        let lastActiveDate = lastActivity.dateValue()
        let now = Date()
        let timeSinceActivity = now.timeIntervalSince(lastActiveDate)
        
        if timeSinceActivity > GroupManager.ACTIVITY_TIMEOUT {
            let minutes = Int(timeSinceActivity / 60)
            print("Group \(document.documentID) inactive for \(minutes) minutes - STALE")
            return true
        }
        
        return false
    }

    // MARK: - Join
    func joinGroup(code: String, userName: String, emoji: String, completion: @escaping (LocalGroup?) -> Void) {
        ensureAuth { userId in
            let groupRef = self.db.collection("groups").document(code)
            
            groupRef.getDocument { [weak self] snapshot, error in
                if let error = error {
                    print("Firestore Read Error: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let self = self, let snapshot = snapshot, snapshot.exists else {
                    print("Error: Group Code \(code) not found.")
                    completion(nil)
                    return
                }
                
                let newMember = GroupMember(id: userId, name: userName, emoji: emoji, isHost: false, isReady: false)
                
                groupRef.updateData([
                    "members": FieldValue.arrayUnion([newMember.toDict])
                ]) { error in
                    if let error = error {
                        print("Join/Update Error: \(error.localizedDescription)")
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
    
    // MARK: - Public Groups & Location
    
    private func distance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2) / 1000.0 // Convert meters to km
    }
    
    private func validateAndCleanGroup(_ document: DocumentSnapshot) -> LocalGroup? {
        guard let data = document.data() else { return nil }
        
        // Check if members array exists and is not empty
        if let members = data["members"] as? [[String: Any]], members.isEmpty {
            print("🗑️ Found empty group: \(document.documentID)")
            deleteGroup(code: document.documentID)
            return nil
        }
        
        if let hostId = data["hostId"] as? String,
               let members = data["members"] as? [[String: Any]] {
                let hostStillHere = members.contains { ($0["id"] as? String) == hostId }
                let status = data["status"] as? String ?? "waiting"
                if status == "waiting" && !hostStillHere {
                    print("🗑️ Host left waiting session \(document.documentID) — deleting group")
                    deleteGroup(code: document.documentID)
                    return nil
                }
            }

        
        // Check if host is still active
        if isGroupStale(document) {
            let sessionName = data["sessionName"] as? String ?? "Unknown"
            print("🗑️ Group '\(sessionName)' host inactive - deleting")
            deleteGroup(code: document.documentID)
            return nil
        }
        
        // Try to create LocalGroup
        guard let group = LocalGroup(document: document) else {
            print("Failed to parse group: \(document.documentID)")
            deleteGroup(code: document.documentID)
            return nil
        }
        
        // Double-check members count
        if group.members.isEmpty {
            print("Group has empty members array: \(group.sessionName)")
            deleteGroup(code: group.sessionCode)
            return nil
        }
        
        return group
    }
    
    func fetchPublicGroups(near coordinate: CLLocationCoordinate2D, radiusInKm: Double = 50, completion: @escaping ([LocalGroup]) -> Void) {
        print("Fetching public groups near: \(coordinate.latitude), \(coordinate.longitude) within \(radiusInKm)km")
        
        db.collection("groups")
            .whereField("isPublic", isEqualTo: true)
            .whereField("status", isEqualTo: "waiting")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Fetch Public Groups Error: \(error.localizedDescription)")
                    completion([])
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents returned")
                    completion([])
                    return
                }
                
                print("Fetched \(documents.count) total public groups from Firebase")
                
                var validGroups: [LocalGroup] = []
                
                for document in documents {
                    // Validate and clean each group
                    guard let group = self.validateAndCleanGroup(document) else {
                        continue
                    }
                    
                    // Check distance
                    guard let groupCoord = group.coordinate else {
                        print("Group '\(group.sessionName)' has no location, skipping")
                        continue
                    }
                    
                    let dist = self.distance(from: coordinate, to: groupCoord)
                    
                    if dist <= radiusInKm {
                        print(" '\(group.sessionName)' - \(String(format: "%.1f", dist))km away - \(group.members.count) members")
                        validGroups.append(group)
                    } else {
                        print(" '\(group.sessionName)' - \(String(format: "%.1f", dist))km away - too far")
                    }
                }
                
                print("Returning \(validGroups.count) valid nearby groups")
                completion(validGroups)
            }
    }
    
    func listenToPublicGroups(near coordinate: CLLocationCoordinate2D, radiusInKm: Double = 50, onChange: @escaping ([LocalGroup]) -> Void) {
        publicGroupsListener?.remove()
                
        publicGroupsListener = db.collection("groups")
            .whereField("isPublic", isEqualTo: true)
            .whereField("status", isEqualTo: "waiting")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Public Groups Listener Error: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("No documents in listener")
                    onChange([])
                    return
                }
                
                print("Listener update: Processing \(documents.count) groups")
                
                var validGroups: [LocalGroup] = []
                
                for document in documents {
                    // Validate and clean each group
                    guard let group = self.validateAndCleanGroup(document) else {
                        continue
                    }
                    
                    // Filter by distance
                    guard let groupCoord = group.coordinate else {
                        continue
                    }
                    
                    let dist = self.distance(from: coordinate, to: groupCoord)
                    
                    if dist <= radiusInKm {
                        print("'\(group.sessionName)' - \(group.members.count) members")
                        validGroups.append(group)
                    }
                }
                
                print("Listener returning \(validGroups.count) valid groups")
                DispatchQueue.main.async { onChange(validGroups) }
            }
    }
    
    func stopListeningToPublicGroups() {
        publicGroupsListener?.remove()
        publicGroupsListener = nil
        print("Stopped listening to public groups")
    }
    
    // clean all empty/stale groups
    func cleanupEmptyGroups(completion: @escaping (Int) -> Void) {
        print("🧹 Starting cleanup of empty and stale groups")
        
        db.collection("groups")
            .whereField("status", isEqualTo: "waiting")
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("Cleanup error: \(error.localizedDescription)")
                    completion(0)
                    return
                }
                
                var deletedCount = 0
                
                for document in snapshot?.documents ?? [] {
                    // Check for empty members
                    if let members = document.data()["members"] as? [[String: Any]], members.isEmpty {
                        print("Cleanup: Deleting empty group \(document.documentID)")
                        self.deleteGroup(code: document.documentID)
                        deletedCount += 1
                        continue
                    }
                    
                    // Check for stale groups (inactive host)
                    if self.isGroupStale(document) {
                        let sessionName = document.data()["sessionName"] as? String ?? "Unknown"
                        print("Cleanup: Deleting stale group '\(sessionName)'")
                        self.deleteGroup(code: document.documentID)
                        deletedCount += 1
                    }
                }
                
                print("Cleanup complete: Deleted \(deletedCount) groups")
                completion(deletedCount)
            }
    }
    
    // MARK: - Delete Group
    func deleteGroup(code: String) {
        db.collection("groups").document(code).delete { error in
            if let error = error {
                print("Delete Error for \(code): \(error.localizedDescription)")
            } else {
                print("Group \(code) deleted from Firebase")
            }
        }
    }
    
    // MARK: - Join Requests
    
    func sendJoinRequest(to groupCode: String, userName: String, completion: @escaping (Bool) -> Void) {
        ensureAuth { userId in
            // Always create a fresh "pending" JoinRequest with a new timestamp
            let request = JoinRequest(userId: userId, userName: userName)
            let groupRef = self.db.collection("groups").document(groupCode)
            
            print("Sending join request to \(groupCode) from \(userName)")
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(groupRef)
                } catch let nserror as NSError {
                    errorPointer?.pointee = nserror
                    return nil
                }
                
                guard snapshot.exists else {
                    print("Group \(groupCode) does not exist")
                    return nil
                }
                
                // Get current pendingRequests
                var requests = snapshot.data()?["pendingRequests"] as? [[String: Any]] ?? []
                
                // Remove any existing requests from this user
                requests.removeAll { dict in
                    (dict["userId"] as? String) == userId
                }
                
                // Add the fresh pending request
                requests.append(request.toDict)
                
                transaction.updateData(["pendingRequests": requests], forDocument: groupRef)
                return nil
            }) { _, error in
                if let error = error {
                    print("Send Join Request Error: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Join request sent successfully (now PENDING for this user)")
                    completion(true)
                }
            }
        }
    }
    

    func clearJoinRequestState(groupCode: String,
                               userId: String,
                               completion: (() -> Void)? = nil) {
        let groupRef = db.collection("groups").document(groupCode)
        
        print("Clearing join request state for user \(userId) in group \(groupCode)")
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(groupRef)
            } catch let nserror as NSError {
                errorPointer?.pointee = nserror
                return nil
            }
            
            guard var requests = snapshot.data()?["pendingRequests"] as? [[String: Any]] else {
                print("No pendingRequests to clear")
                return nil
            }
            
            // Remove ALL requests for this user (denied, pending, whatever)
            requests.removeAll { dict in
                (dict["userId"] as? String) == userId
            }
            
            transaction.updateData(["pendingRequests": requests], forDocument: groupRef)
            return nil
        }) { _, error in
            if let error = error {
                print("Clear Join Request State Error: \(error.localizedDescription)")
            } else {
                print("Cleared join request state for \(userId) in \(groupCode)")
            }
            DispatchQueue.main.async {
                completion?()
            }
        }
    }



    
    func handleJoinRequest(groupCode: String, request: JoinRequest, approved: Bool, emoji: String, completion: @escaping (Bool) -> Void) {
        let groupRef = db.collection("groups").document(groupCode)
        
        print("Handling join request: \(approved ? "ACCEPT" : "DENY") for \(request.userName)")
        
        db.runTransaction({ (transaction, errorPointer) -> Any? in
            let snapshot: DocumentSnapshot
            do {
                snapshot = try transaction.getDocument(groupRef)
            } catch let nserror as NSError {
                errorPointer?.pointee = nserror
                return nil
            }
            
            guard var requests = snapshot.data()?["pendingRequests"] as? [[String: Any]] else {
                return nil
            }
            
            // Find and update the request status
            for (i, r) in requests.enumerated() {
                if let userId = r["userId"] as? String, userId == request.userId {
                    var updatedRequest = r
                    updatedRequest["status"] = approved ? "accepted" : "denied"
                    requests[i] = updatedRequest
                    
                    // If approved, add the user to members array
                    if approved {
                        let newMember = GroupMember(
                            id: request.userId,
                            name: request.userName,
                            emoji: emoji,
                            isHost: false,
                            isReady: false
                        )
                        
                        var members = snapshot.data()?["members"] as? [[String: Any]] ?? []
                        
                        if members.contains(where: { ($0["id"] as? String) == request.userId }) {
                            print("User \(request.userName) is already a member, skipping re-add.")
                        } else {
                            members.append(newMember.toDict)
                        }
                        //members.append(newMember.toDict)
                        transaction.updateData(["members": members], forDocument: groupRef)
                        
                        print("Added \(request.userName) to members")
                    }
                    
                    break
                }
            }
            
            transaction.updateData(["pendingRequests": requests], forDocument: groupRef)
            return nil
        }) { _, error in
            if let error = error {
                print("Handle Join Request Error: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Join request handled successfully")
                completion(true)
            }
        }
    }
    
    func listenToJoinRequestStatus(groupCode: String, userId: String, onChange: @escaping (String?) -> Void) {
        // Stop any previous listener using the shared "listener" slot
        listener?.remove()
        
        let groupRef = db.collection("groups").document(groupCode)
        print("Listening for user \(userId) on group \(groupCode)")
        
        listener = groupRef.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Listener error: \(error.localizedDescription)")
                DispatchQueue.main.async { onChange(nil) }
                return
            }
            
            guard let snap = snapshot, let data = snap.data() else {
                print("No group data")
                DispatchQueue.main.async { onChange(nil) }
                return
            }
            
            // If the user is already in members, they are accepted
            if let members = data["members"] as? [[String: Any]],
               members.contains(where: { ($0["id"] as? String) == userId }) {
                print("User \(userId) is already in members → accepted")
                DispatchQueue.main.async { onChange("accepted") }
                return
            }
            
            // Otherwise, look at this user's join requests
            guard let requests = data["pendingRequests"] as? [[String: Any]], !requests.isEmpty else {
                print("No pendingRequests array or it's empty")
                DispatchQueue.main.async { onChange(nil) }
                return
            }
            
            var latestStatus: String?
            var latestDate: Date?
            
            for r in requests {
                guard
                    let reqUserId = r["userId"] as? String,
                    reqUserId == userId,
                    let ts = r["timestamp"] as? Timestamp
                else { continue }
                
                let date = ts.dateValue()
                if latestDate == nil || date > latestDate! {
                    latestDate = date
                    latestStatus = (r["status"] as? String) ?? "pending"
                }
            }
            
            print("Latest status for \(userId): \(latestStatus ?? "nil") at \(latestDate?.description ?? "-")")
            
            DispatchQueue.main.async {
                onChange(latestStatus)
            }
        }
    }


    
    // MARK: - Real-time Sync
    func listenToGroup(code: String, onChange: @escaping (LocalGroup) -> Void) {
        listener?.remove()
        
        // Update activity when starting to listen (host is active)
        updateActivity(groupCode: code)
        
        listener = db.collection("groups").document(code).addSnapshotListener { [weak self] snapshot, error in
            if let error = error {
                print("❌ Listener Error: \(error.localizedDescription)")
                return
            }
            
            guard let snapshot = snapshot, snapshot.exists else {
                print("Group no longer exists: \(code)")
                return
            }
            
            // Validate the group
            guard let group = self?.validateAndCleanGroup(snapshot) else {
                print("Group failed validation: \(code)")
                return
            }
            
            DispatchQueue.main.async { onChange(group) }
        }
    }
    
    func stopListening() {
        listener?.remove()
        listener = nil
        publicGroupsListener?.remove()
        publicGroupsListener = nil
    }
    
    // MARK: - Actions
    func updateMyState(code: String, emoji: String, isReady: Bool) {
        ensureAuth { userId in
            // Update activity timestamp too
            self.updateActivity(groupCode: code)
            
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
    
    func startSessionWithSongs(code: String, songs: [Song]) {
        let songDicts = songs.map { $0.toDict }
        
        db.collection("groups").document(code).updateData([
            "status": "started",
            "sharedPlaylist": songDicts
        ]) { error in
            if let error = error {
                print("Failed to start session: \(error.localizedDescription)")
            } else {
                print("Session Started & Playlist Saved to DB")
            }
        }
    }
    
    func leaveGroup(code: String, completion: @escaping () -> Void) {
        ensureAuth { userId in
            print("User \(userId) leaving group \(code)")
            
            let groupRef = self.db.collection("groups").document(code)
            
            self.db.runTransaction({ (transaction, errorPointer) -> Any? in
                let snapshot: DocumentSnapshot
                do {
                    snapshot = try transaction.getDocument(groupRef)
                } catch let nserror as NSError {
                    errorPointer?.pointee = nserror
                    return nil
                }
                
                guard var members = snapshot.data()?["members"] as? [[String: Any]] else {
                    print("No members array found")
                    return nil
                }
                
                let beforeCount = members.count
                members.removeAll { ($0["id"] as? String) == userId }
                let afterCount = members.count
                
                print("  Members before: \(beforeCount), after: \(afterCount)")
                
                // If no members left, delete the group entirely
                if members.isEmpty {
                    print("Last member leaving - DELETING GROUP \(code)")
                    transaction.deleteDocument(groupRef)
                } else {
                    print("  Updating members array")
                    transaction.updateData(["members": members], forDocument: groupRef)
                }
                
                return nil
            }) { _, error in
                if let error = error {
                    print("Leave Group Error: \(error.localizedDescription)")
                } else {
                    print("Successfully left group \(code)")
                }
                completion()
            }
        }
    }
}
