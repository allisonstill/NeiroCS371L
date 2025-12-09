//
//  GroupModels.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import Foundation
import FirebaseFirestore
import CoreLocation

struct GroupMember {
    let id: String
    var name: String
    var emoji: String
    var isHost: Bool
    var isReady: Bool
    
    var toDict: [String: Any] {
        return [
            "id": id,
            "name": name,
            "emoji": emoji,
            "isHost": isHost,
            "isReady": isReady
        ]
    }
}

// need to 'request' to join groups
struct JoinRequest {
    let userId: String
    let userName: String
    let timestamp: Date
    var status: String // "pending", "accepted", "denied"
    
    var toDict: [String: Any] {
        return [
            "userId": userId,
            "userName": userName,
            "timestamp": Timestamp(date: timestamp),
            "status": status
        ]
    }
    
    init?(dict: [String: Any]) {
        guard let userId = dict["userId"] as? String,
              let userName = dict["userName"] as? String,
              let timestamp = dict["timestamp"] as? Timestamp else { return nil }
        
        self.userId = userId
        self.userName = userName
        self.timestamp = timestamp.dateValue()
        self.status = dict["status"] as? String ?? "pending"
    }
    
    init(userId: String, userName: String, timestamp: Date = Date(), status: String = "pending") {
        self.userId = userId
        self.userName = userName
        self.timestamp = timestamp
        self.status = status
    }
}

// for map on group page
struct LocalGroup {
    let sessionCode: String
    var sessionName: String
    var isPublic: Bool
    var location: GeoPoint?
    var hostName: String
    var status: String
    var members: [GroupMember]
    var sharedSongs: [Song]?
    var pendingRequests: [JoinRequest]
    
    // coordinates of location
    var coordinate: CLLocationCoordinate2D? {
        guard let location = location else { return nil }
        return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
    }
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let membersData = data["members"] as? [[String: Any]] else { return nil }
        
        self.sessionCode = document.documentID
        self.sessionName = data["sessionName"] as? String ?? "Neiro Session"
        self.isPublic = data["isPublic"] as? Bool ?? false
        self.location = data["location"] as? GeoPoint
        self.hostName = data["hostName"] as? String ?? "Host"
        self.status = data["status"] as? String ?? "waiting"
        
        self.members = membersData.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let emoji = dict["emoji"] as? String,
                  let isHost = dict["isHost"] as? Bool else { return nil }
            
            let isReady = dict["isReady"] as? Bool ?? false
            return GroupMember(id: id, name: name, emoji: emoji, isHost: isHost, isReady: isReady)
        }
        
        // Load shared playlist if available
        if let songsData = data["sharedPlaylist"] as? [[String: Any]] {
            self.sharedSongs = songsData.compactMap { Song(dict: $0) }
        } else {
            self.sharedSongs = nil
        }
        
        // Load pending requests if available
        if let requestsData = data["pendingRequests"] as? [[String: Any]] {
            self.pendingRequests = requestsData.compactMap { JoinRequest(dict: $0) }
        } else {
            self.pendingRequests = []
        }
    }
    
    init(sessionCode: String, sessionName: String, isPublic: Bool, location: GeoPoint?,
         hostName: String, members: [GroupMember], status: String = "waiting") {
        self.sessionCode = sessionCode
        self.sessionName = sessionName
        self.isPublic = isPublic
        self.location = location
        self.hostName = hostName
        self.members = members
        self.status = status
        self.sharedSongs = nil
        self.pendingRequests = []
    }
    
    var toDict: [String: Any] {
        var dict: [String: Any] = [
            "sessionName": sessionName,
            "isPublic": isPublic,
            "hostName": hostName,
            "status": status,
            "members": members.map { $0.toDict },
            "pendingRequests": pendingRequests.map { $0.toDict }
        ]
        
        if let location = location {
            dict["location"] = location
        }
        
        if let songs = sharedSongs {
            dict["sharedPlaylist"] = songs.map { $0.toDict }
        }
        
        return dict
    }
}
