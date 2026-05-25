import SwiftUI

// MARK: - Near-neutral palette  (248 248 246 is the darkest surface)

extension Color {
    static let bgPrimary = Color(red: 0.992, green: 0.992, blue: 0.988)  // 253 253 252 — main bg
    static let bgCard    = Color(red: 0.984, green: 0.984, blue: 0.980)  // 251 251 250 — cards
    static let bgTabBar  = Color(red: 0.973, green: 0.973, blue: 0.965)  // 248 248 246 — tab chrome
    static let inkMid    = Color(red: 0.549, green: 0.510, blue: 0.463)  // warm mid-gray for secondary icons
    static let inkDeep   = Color(red: 0.196, green: 0.180, blue: 0.165)  // near-black warm for text
}
