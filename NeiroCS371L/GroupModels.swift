//
//  GroupModels.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import Foundation

struct GroupMember {
    let id: UUID
    var name: String
    var emoji: String
    var isHost: Bool
}

struct LocalGroup {
    let id: UUID
    var name: String
    var createdAt: Date
    var members: [GroupMember]
    var sessionCode: String
}
