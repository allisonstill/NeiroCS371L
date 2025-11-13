//
//  Group.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 11/12/25.
//

import Foundation

class Group {
    let id: UUID
    var name: String
    var members: [String]
    var emojis: [String]
    
    init(name: String, members: [String] = [], emojis: [String] = []) {
        self.id = UUID()
        self.name = name
        self.members = members
        self.emojis = emojis
    }
}
