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
    
    public private(set) var currentDangerLevel: Int = 1 {
        didSet {
            onDangerLevelChanged?(currentDangerLevel)
        }
    }
    
    public var onDangerLevelChanged: ((Int) -> Void)?
    
    private init() {}
    
    public func registerMobKilled() {
        mobKillsCount += 1
        currentDangerLevel += 1
    }
    
    public func resetDangerLevel() {
        mobKillsCount = 0
        currentDangerLevel = 1
    }
}
