import Foundation

/// General item protocol for items that can occupy slot in player's inventory
public protocol ItemProtocol {
    var id: UUID { get }
    var name: String { get }
    var description: String { get }
    var slotOccupied: Int { get } // MUST occupy exactly 1 inventory slot
}

public enum WeaponType: String, Codable, CaseIterable {
    case pistol  = "Pistol"
    case smg     = "SMG"
    case shotgun = "Shotgun"
}

public enum WeaponTier: Int, Codable, Comparable, CaseIterable {
    case common = 1
    case uncommon = 2
    case rare = 3
    case epic = 4
    case legendary = 5
    
    public var name: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }
    
    public static func < (lhs: WeaponTier, rhs: WeaponTier) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
    
    public var next: WeaponTier? {
        return WeaponTier(rawValue: self.rawValue + 1)
    }
}

/// Concrete DTO for Weapon inventory items
public struct WeaponDTO: ItemProtocol, Codable {
    public let id: UUID
    public var name: String
    public var description: String
    public var slotOccupied: Int { return 1 } // Occupies exactly 1 slot
    
    public var type: WeaponType
    public var tier: WeaponTier
    public var damage: Int
    public var fireRate: Double
    
    // Mods equipped on this weapon
    public var equippedMods: [ModDTO]
    
    public init(id: UUID = UUID(), type: WeaponType, tier: WeaponTier = .common, damage: Int? = nil, fireRate: Double? = nil, equippedMods: [ModDTO] = []) {
        self.id = id
        self.type = type
        self.tier = tier
        self.equippedMods = equippedMods
        
        // Base damage and fire rate defaults
        let baseDmg: Int
        let baseRate: Double
        
        switch type {
        case .pistol:
            baseDmg = 15
            baseRate = 2.0
        case .smg:
            baseDmg = 10
            baseRate = 8.0
        case .shotgun:
            baseDmg = 45
            baseRate = 1.0
        }
        
        // Scale stats significantly with Tier
        // Tier multiplier: Common=1.0, Uncommon=1.8, Rare=3.0, Epic=5.0, Legendary=9.0
        let tierMultiplier: Double
        switch tier {
        case .common: tierMultiplier = 1.0
        case .uncommon: tierMultiplier = 1.8
        case .rare: tierMultiplier = 3.0
        case .epic: tierMultiplier = 5.0
        case .legendary: tierMultiplier = 9.0
        }
        
        self.damage = damage ?? Int(Double(baseDmg) * tierMultiplier)
        self.fireRate = fireRate ?? baseRate
        self.name = "\(tier.name) \(type.rawValue)"
        self.description = "A reliable \(tier.name.lowercased()) tier tactical firearm."
    }
}

/// DTO for weapon modification drops
public struct ModDTO: ItemProtocol, Codable {
    public let id: UUID
    public var name: String
    public var description: String
    public var slotOccupied: Int { return 1 }
    
    public var statAffected: String // "Damage", "FireRate", "HP"
    public var multiplierBoost: Double
    
    public init(id: UUID = UUID(), name: String, description: String, statAffected: String, multiplierBoost: Double) {
        self.id = id
        self.name = name
        self.description = description
        self.statAffected = statAffected
        self.multiplierBoost = multiplierBoost
    }
}
