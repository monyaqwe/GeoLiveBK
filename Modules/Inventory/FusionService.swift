import Foundation

public enum FusionError: Error {
    case insufficientItems
    case tierLimitReached
    case mismatchTypes
    case mismatchTiers
}

/// Service to merge 3 identical items of the same tier into 1 upgraded item of the next tier
public final class FusionService {
    public static let shared = FusionService()
    
    private init() {}
    
    /// Merges 3 identical weapons of the same type and tier into a single next-tier weapon
    public func fuseWeapons(weapon1: WeaponDTO, weapon2: WeaponDTO, weapon3: WeaponDTO) -> Result<WeaponDTO, FusionError> {
        // Validate matching types
        guard weapon1.type == weapon2.type && weapon2.type == weapon3.type else {
            return .failure(.mismatchTypes)
        }
        
        // Validate matching tiers
        guard weapon1.tier == weapon2.tier && weapon2.tier == weapon3.tier else {
            return .failure(.mismatchTiers)
        }
        
        // Ensure there is a next tier
        guard let nextTier = weapon1.tier.next else {
            return .failure(.tierLimitReached)
        }
        
        // Fuse and return upgraded weapon
        let upgradedWeapon = WeaponDTO(type: weapon1.type, tier: nextTier)
        return .success(upgradedWeapon)
    }
    
    /// Helper to find triplets inside an array of weapons that can be fused
    public func findFuseableTriplets(in weapons: [WeaponDTO]) -> [[WeaponDTO]] {
        var groupedWeapons: [String: [WeaponDTO]] = [:]
        
        // Group weapons by type & tier
        for w in weapons {
            let key = "\(w.type.rawValue)_\(w.tier.rawValue)"
            groupedWeapons[key, default: []].append(w)
        }
        
        var triplets: [[WeaponDTO]] = []
        for (_, list) in groupedWeapons {
            var items = list
            while items.count >= 3 {
                let triplet = Array(items.prefix(3))
                triplets.append(triplet)
                items.removeFirst(3)
            }
        }
        
        return triplets
    }
}
