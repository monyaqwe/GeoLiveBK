import Foundation

public final class InventoryViewModel {
    
    // Callbacks to notify UI changes
    public var onInventoryUpdated: (() -> Void)?
    public var onFusionCompleted: ((WeaponDTO) -> Void)?
    public var onFusionFailed: ((String) -> Void)?
    
    public init() {}
    
    public func getWeapons() -> [WeaponDTO] {
        return InventoryManager.shared.items.compactMap { $0 as? WeaponDTO }
    }
    
    public func getMods() -> [ModDTO] {
        return InventoryManager.shared.items.compactMap { $0 as? ModDTO }
    }
    
    public func addWeapon(type: WeaponType, tier: WeaponTier) {
        let weapon = WeaponDTO(type: type, tier: tier)
        InventoryManager.shared.addItem(weapon) { [weak self] result in
            switch result {
            case .success:
                self?.onInventoryUpdated?()
            case .failure(let err):
                print("Failed to add weapon: \(err.localizedDescription)")
            }
        }
    }
    
    /// Attempt to fuse 3 weapons of the same type and tier
    public func fuseSelectedWeapons(w1: WeaponDTO, w2: WeaponDTO, w3: WeaponDTO) {
        let result = FusionService.shared.fuseWeapons(weapon1: w1, weapon2: w2, weapon3: w3)
        switch result {
        case .success(let upgraded):
            // Remove fused elements from inventory
            InventoryManager.shared.removeItem(id: w1.id) { _ in }
            InventoryManager.shared.removeItem(id: w2.id) { _ in }
            InventoryManager.shared.removeItem(id: w3.id) { _ in }
            
            // Add upgraded variant
            InventoryManager.shared.addItem(upgraded) { [weak self] _ in
                self?.onFusionCompleted?(upgraded)
                self?.onInventoryUpdated?()
            }
        case .failure(let err):
            onFusionFailed?("Fusion failed: \(err)")
        }
    }
}
