import Foundation

/// Core Protocol for managing global/local danger parameters
public protocol DangerLevelManagerProtocol {
    var currentDangerLevel: Int { get }
    func registerMobKilled()
    func resetDangerLevel()
}

/// Tracks player combat rating, dynamically scaling environment difficulty
public final class DangerLevelManager: DangerLevelManagerProtocol {
    public static let shared = DangerLevelManager()
    
    private let kDangerScaleThreshold = 5 // Increase dangerLevel every 5 mob kills
    private var mobKillsCount = 0
    
    // Per-MobType difficulty levels
    private var mobLevels: [MobType: Int] = [
        .necroRats: 1,
        .bandits: 1,
        .police: 1
    ]
    
    // Kill count tracking per MobType to enforce series-based leveling
    private var typeKills: [MobType: Int] = [
        .necroRats: 0,
        .bandits: 0,
        .police: 0
    ]
    
    private let kKillsThreshold = 5 // Enforce a series of 5 kills of the same type to level up
    
    public private(set) var currentDangerLevel: Int = 1 {
        didSet {
            onDangerLevelChanged?(currentDangerLevel)
        }
    }
    
    public var onDangerLevelChanged: ((Int) -> Void)?
    
    private init() {}
    
    // Returns the current level for a specific mob type
    public func level(for type: MobType) -> Int {
        return mobLevels[type] ?? 1
    }
    
    // Increments only the specific mob type's level
    public func incrementLevel(for type: MobType) {
        let current = mobLevels[type] ?? 1
        mobLevels[type] = current + 1
        
        // Also sync overall danger level for compatibility
        currentDangerLevel = mobLevels.values.max() ?? 1
    }
    
    // Registers a type-specific kill and returns true if it triggered a level-up
    public func registerKill(for type: MobType) -> Bool {
        let kills = (typeKills[type] ?? 0) + 1
        typeKills[type] = kills
        
        if kills >= kKillsThreshold {
            typeKills[type] = 0
            incrementLevel(for: type)
            return true
        }
        return false
    }
    
    public func registerMobKilled() {
        mobKillsCount += 1
        // Keep fallback logic if group mechanics are bypassed
        currentDangerLevel = mobLevels.values.max() ?? 1
    }
    
    public func resetDangerLevel() {
        mobKillsCount = 0
        currentDangerLevel = 1
        mobLevels = [
            .necroRats: 1,
            .bandits: 1,
            .police: 1
        ]
        typeKills = [
            .necroRats: 0,
            .bandits: 0,
            .police: 0
        ]
    }
}
