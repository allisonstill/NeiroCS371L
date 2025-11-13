//
//  GroupManager.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import Foundation

class GroupManager {
    static let shared = GroupManager()
    private init() {}
    
    static func generateSessionCode() -> String {
            let chars = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
            return String((0..<5).map { _ in chars.randomElement()! })
        }
    
    private var groups: [Group] = []

    func createGroup(name: String) -> Group {
        let group = Group(name: name)
        groups.append(group)
        return group
    }

    func allGroups() -> [Group] {
        return groups
    }
    
    // dummy group
    
    // only valid code for joining
    let dummyJoinCode = "ABCDE"

    // group that anyone can "join"
    private lazy var dummyGroup: LocalGroup = {
        return LocalGroup(
            id: UUID(),
            name: "Friends Jam 👍",
            createdAt: Date(),
            members: [
                GroupMember(id: UUID(), name: "Alex",   emoji: "😎", isHost: true),
                GroupMember(id: UUID(), name: "Jordan", emoji: "🔥", isHost: false),
                GroupMember(id: UUID(), name: "Taylor", emoji: "🙂", isHost: false)
            ],
            sessionCode: dummyJoinCode
        )
    }()

    func joinGroup(withCode code: String) -> LocalGroup? {
        if code.uppercased() == dummyJoinCode {
            return dummyGroup
        }
        return nil
    }
}

