import Foundation

/// DTO for holding Player-specific progress, stats, and currency state
public struct PlayerDTO: Codable {
    public let uid: String
    public var nickname: String
    
    // Core stats stored in Firebase
    public var level: Int
    public var currentXP: Int
    public var maxXP: Int
    public var currentHP: Int
    public var maxHP: Int
    public var baseDamage: Int
    
    // Soft & Premium currencies
    public var cash: Int       // Soft currency
    public var gems: Int       // Premium currency
    
    // Inventory attributes
    public var maxInventorySlots: Int {
        // Base 10 slots + 1 slot per player level
        return 10 + level
    }
    
    public init(uid: String, nickname: String, level: Int = 1, currentXP: Int = 0, maxXP: Int = 1000, currentHP: Int = 100, maxHP: Int = 100, baseDamage: Int = 30, cash: Int = 10000, gems: Int = 10) {
        self.uid = uid
        self.nickname = nickname
        self.level = level
        self.currentXP = currentXP
        self.maxXP = maxXP
        self.currentHP = currentHP
        self.maxHP = maxHP
        self.baseDamage = baseDamage
        self.cash = cash
        self.gems = gems
    }
}
