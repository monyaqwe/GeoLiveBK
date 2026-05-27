import Foundation

/// Item weight for Gacha drop tables
public struct GachaDropWeight: Codable {
    public let weaponType: WeaponType
    public let tier: WeaponTier
    public let weight: Int // Higher weight means higher probability
}

/// DTO for Loot Boxes purchasable in the Store
public struct LootBoxDTO: Codable {
    public let id: String
    public var name: String
    public var description: String
    public var costCash: Int
    public var costGems: Int
    
    // Distribution weights
    public var dropWeights: [GachaDropWeight]
    
    public init(id: String, name: String, description: String, costCash: Int, costGems: Int, dropWeights: [GachaDropWeight]) {
        self.id = id
        self.name = name
        self.description = description
        self.costCash = costCash
        self.costGems = costGems
        self.dropWeights = dropWeights
    }
    
    /// Standard Tactical Case drop weights
    public static var standardTacticalCase: LootBoxDTO {
        return LootBoxDTO(
            id: "case_standard",
            name: "Standard Tactical Case",
            description: "Contains standard grade military hardware. Guaranteed Common or Uncommon drop.",
            costCash: 5000,
            costGems: 0,
            dropWeights: [
                GachaDropWeight(weaponType: .pistol, tier: .common, weight: 60),
                GachaDropWeight(weaponType: .smg, tier: .common, weight: 25),
                GachaDropWeight(weaponType: .shotgun, tier: .common, weight: 10),
                GachaDropWeight(weaponType: .pistol, tier: .uncommon, weight: 4),
                GachaDropWeight(weaponType: .smg, tier: .uncommon, weight: 1)
            ]
        )
    }
    
    /// Premium Operations Case drop weights
    public static var premiumOpsCase: LootBoxDTO {
        return LootBoxDTO(
            id: "case_premium",
            name: "Premium Ops Case",
            description: "High-grade operative drop box. Increased chance for Rare, Epic, or Legendary weapons.",
            costCash: 0,
            costGems: 15,
            dropWeights: [
                GachaDropWeight(weaponType: .pistol, tier: .uncommon, weight: 40),
                GachaDropWeight(weaponType: .smg, tier: .uncommon, weight: 30),
                GachaDropWeight(weaponType: .shotgun, tier: .uncommon, weight: 15),
                GachaDropWeight(weaponType: .smg, tier: .rare, weight: 10),
                GachaDropWeight(weaponType: .shotgun, tier: .epic, weight: 4),
                GachaDropWeight(weaponType: .shotgun, tier: .legendary, weight: 1)
            ]
        )
    }
}
