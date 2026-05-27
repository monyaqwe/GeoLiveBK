import Foundation

/// DTO representing items collected from defeated hostiles
public struct LootDrop: Codable {
    public let xpAwarded: Int
    public let softCurrencyAwarded: Int
    public let weaponDrop: WeaponDTO?
    public let modDrop: ModDTO?
    
    public init(xpAwarded: Int, softCurrencyAwarded: Int, weaponDrop: WeaponDTO? = nil, modDrop: ModDTO? = nil) {
        self.xpAwarded = xpAwarded
        self.softCurrencyAwarded = softCurrencyAwarded
        self.weaponDrop = weaponDrop
        self.modDrop = modDrop
    }
}

/// Dynamic manager handling item drop chances, skulls (XP), and equipment upgrades
public final class LootManager {
    public static let shared = LootManager()
    
    private init() {}
    
    /// Generates dynamic loot drops when defeating hostiles
    public func rollLootForMob(type: MobType, dangerLevel: Int) -> LootDrop {
        // Base XP Skulls scaling with danger level (+10% per level)
        let xpBase = type.baseXP
        let xpScale = Double(xpBase) * (1.0 + Double(dangerLevel - 1) * 0.10)
        let xpReward = Int(xpScale)
        
        // Base soft currency rewards
        let currencyReward = Int.random(in: 100...300) * dangerLevel
        
        // 0.5% chance for a rare weapon or mod drop
        let rareRoll = Double.random(in: 0.0...100.0)
        var weaponDrop: WeaponDTO? = nil
        var modDrop: ModDTO? = nil
        
        if rareRoll <= 0.5 { // 0.5% chance
            // Roll weapon or mod (50/50 chance)
            if Bool.random() {
                // Weapons drop with higher tiers at larger danger levels
                let weaponType = WeaponType.allCases.randomElement() ?? .pistol
                let tier: WeaponTier
                let tierRoll = Int.random(in: 1...100) + dangerLevel * 2
                
                if tierRoll < 75 {
                    tier = .common
                } else if tierRoll < 92 {
                    tier = .uncommon
                } else if tierRoll < 98 {
                    tier = .rare
                } else if tierRoll < 100 {
                    tier = .epic
                } else {
                    tier = .legendary
                }
                
                weaponDrop = WeaponDTO(type: weaponType, tier: tier)
            } else {
                let stats = ["Damage", "FireRate", "HP"]
                let stat = stats.randomElement() ?? "Damage"
                modDrop = ModDTO(
                    name: "Tactical \(stat) Mod",
                    description: "Increases \(stat.lowercased()) capabilities.",
                    statAffected: stat,
                    multiplierBoost: Double.random(in: 0.05...0.20)
                )
            }
        }
        
        return LootDrop(xpAwarded: xpReward, softCurrencyAwarded: currencyReward, weaponDrop: weaponDrop, modDrop: modDrop)
    }
}
