import Foundation

/// Core Protocol for calculating progression stats, multipliers, and upgrade requirements
public protocol StatCalculationServiceProtocol {
    func calculateUpgradeCost(currentLevel: Int) -> Int
    func calculateBuildingMaxHP(baseMaxHP: Int, staffLevel: Int, equipLevel: Int) -> Int
    func calculateBuildingIncomeRate(baseRate: Int, level: Int, staffLevel: Int, equipLevel: Int, hasChefUpgrade: Bool, hasEquipmentUpgrade: Bool) -> Int
    func calculatePlayerMaxXP(level: Int) -> Int
}

/// Dynamic progression formulas to balance in-game economies
public final class StatCalculationService: StatCalculationServiceProtocol {
    public static let shared = StatCalculationService()
    
    private init() {}
    
    public func calculateUpgradeCost(currentLevel: Int) -> Int {
        // Upgrade cost: Level * 5000 coins
        return currentLevel * 5000
    }
    
    public func calculateBuildingMaxHP(baseMaxHP: Int, staffLevel: Int, equipLevel: Int) -> Int {
        // 300 base HP, +20 per staff level, +30 per equip level
        return 300 + (staffLevel * 20) + (equipLevel * 30)
    }
    
    public func calculateBuildingIncomeRate(baseRate: Int, level: Int, staffLevel: Int, equipLevel: Int, hasChefUpgrade: Bool, hasEquipmentUpgrade: Bool) -> Int {
        let base = baseRate * level
        let rawIncome = base + (staffLevel * 150) + (equipLevel * 250)
        
        // Upgrades apply multipliers (Chef: 1.5x, Equipment: 1.8x, both: 2.7x)
        var multiplier = 1.0
        if hasChefUpgrade {
            multiplier *= 1.5
        }
        if hasEquipmentUpgrade {
            multiplier *= 1.8
        }
        
        return Int(Double(rawIncome) * multiplier)
    }
    
    public func calculatePlayerMaxXP(level: Int) -> Int {
        // Linear scale for XP limits
        return level * 1000
    }
}
