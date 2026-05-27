import Foundation

/// Core Protocol for Loot Box opening and verification
public protocol GachaServiceProtocol {
    func openLootBox(box: LootBoxDTO, completion: @escaping (Result<WeaponDTO, Error>) -> Void)
}

/// Server-authoritative pull simulator checking weights for weapons and modular drops
public final class GachaService: GachaServiceProtocol {
    public static let shared = GachaService()
    
    private init() {}
    
    public func openLootBox(box: LootBoxDTO, completion: @escaping (Result<WeaponDTO, Error>) -> Void) {
        // Send a request to network / Firebase functions to pull in a secure server context
        NetworkManager.shared.performServerAuthoritativeAction(actionName: "open_gacha_case", data: ["caseId": box.id]) { result in
            switch result {
            case .success:
                // Roll weighted table locally (simulating server returns)
                let drop = self.rollWeightedDropTable(weights: box.dropWeights)
                let weapon = WeaponDTO(type: drop.weaponType, tier: drop.tier)
                
                // Add weapon to player backpack inventory
                InventoryManager.shared.addItem(weapon) { addResult in
                    switch addResult {
                    case .success:
                        completion(.success(weapon))
                    case .failure(let err):
                        completion(.failure(err))
                    }
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func rollWeightedDropTable(weights: [GachaDropWeight]) -> GachaDropWeight {
        let totalWeight = weights.reduce(0) { $0 + $1.weight }
        let roll = Int.random(in: 0..<totalWeight)
        
        var currentSum = 0
        for entry in weights {
            currentSum += entry.weight
            if roll < currentSum {
                return entry
            }
        }
        
        return weights.first ?? GachaDropWeight(weaponType: .pistol, tier: .common, weight: 100)
    }
}
