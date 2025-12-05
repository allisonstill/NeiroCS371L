//
//  GroupModels.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import Foundation
import FirebaseFirestore

struct GroupMember: Codable {
    let id: String
    var name: String
    var emoji: String
    var isHost: Bool
    var isReady: Bool // <--- NEW: Track ready state
    
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

struct LocalGroup: Codable {
    let sessionCode: String
    var status: String // <--- NEW: "waiting" or "started"
    var members: [GroupMember]
    
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let membersData = data["members"] as? [[String: Any]] else { return nil }
        
        self.sessionCode = document.documentID
        self.status = data["status"] as? String ?? "waiting" // Default to waiting
        
        self.members = membersData.compactMap { dict in
            guard let id = dict["id"] as? String,
                  let name = dict["name"] as? String,
                  let emoji = dict["emoji"] as? String,
                  let isHost = dict["isHost"] as? Bool else { return nil }
            
            let isReady = dict["isReady"] as? Bool ?? false
            return GroupMember(id: id, name: name, emoji: emoji, isHost: isHost, isReady: isReady)
        }
    }
    
    // Initializer for creation
    init(sessionCode: String, members: [GroupMember], status: String = "waiting") {
        self.sessionCode = sessionCode
        self.members = members
        self.status = status
    }
}
