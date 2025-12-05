//
//  PlaylistLogic.swift
//  NeiroCS371L
//
//  Created by Andres Osornio on 12/4/25.
//

import Foundation

struct EmojiBreakdown {
    let emoji: String
    let songCount: Int
}

// Logic to calculate how many songs come from each vibe
func calculatePlaylistMix(group: LocalGroup, totalSongsInPlaylist: Int) -> [EmojiBreakdown] {
    let members = group.members
    let totalMembers = Double(members.count)
    if totalMembers == 0 { return [] }
    
    // 1. Count how many people picked each emoji
    // Example: ["🔥": 2, "😎": 1]
    var counts: [String: Int] = [:]
    for member in members {
        counts[member.emoji, default: 0] += 1
    }
    
    // 2. Calculate the exact number of songs per emoji
    var breakdown: [EmojiBreakdown] = []
    var assignedSongs = 0
    
    for (emoji, count) in counts {
        let percentage = Double(count) / totalMembers
        let songCount = Int((percentage * Double(totalSongsInPlaylist)).rounded())
        
        breakdown.append(EmojiBreakdown(emoji: emoji, songCount: songCount))
        assignedSongs += songCount
    }
    
    // 3. Fix Rounding Errors
    // (e.g. if we calculated 19 songs total but needed 20, add 1 to the first group)
    if assignedSongs < totalSongsInPlaylist {
        let diff = totalSongsInPlaylist - assignedSongs
        if !breakdown.isEmpty {
             let first = breakdown[0]
             breakdown[0] = EmojiBreakdown(emoji: first.emoji, songCount: first.songCount + diff)
        }
    }
    
    return breakdown
}
