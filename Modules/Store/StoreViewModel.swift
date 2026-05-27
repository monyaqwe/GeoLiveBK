import Foundation

public final class StoreViewModel {
    
    public var activePlayer: PlayerDTO
    
    // Callbacks
    public var onStorePurchaseSuccess: ((String) -> Void)?
    public var onStorePurchaseFailed: ((String) -> Void)?
    public var onCurrencyUpdated: ((PlayerDTO) -> Void)?
    
    public init(activePlayer: PlayerDTO) {
        self.activePlayer = activePlayer
    }
    
    /// Purchase a loot box and pull dynamic rewards
    public func buyLootBox(box: LootBoxDTO) {
        // Validate costs
        if box.costGems > 0 {
            guard activePlayer.gems >= box.costGems else {
                onStorePurchaseFailed?("Not enough gems!")
                return
            }
            activePlayer.gems -= box.costGems
        } else {
            guard activePlayer.cash >= box.costCash else {
                onStorePurchaseFailed?("Not enough cash!")
                return
            }
            activePlayer.cash -= box.costCash
        }
        
        GachaService.shared.openLootBox(box: box) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let weapon):
                self.onStorePurchaseSuccess?("OPENED CASE: Obtained \(weapon.name) (Lv. \(weapon.tier.rawValue))!")
                self.onCurrencyUpdated?(self.activePlayer)
                // Firebase sync
                FirebaseManager.shared.updatePlayerCurrency(playerUid: self.activePlayer.uid, cash: self.activePlayer.cash, gems: self.activePlayer.gems) { _ in }
            case .failure(let error):
                // Revert currency if opening failed
                if box.costGems > 0 {
                    self.activePlayer.gems += box.costGems
                } else {
                    self.activePlayer.cash += box.costCash
                }
                self.onStorePurchaseFailed?("Open failed: \(error.localizedDescription)")
            }
        }
    }
    
    /// Deploys defender on dynamic client triggers
    public func buyDefender(type: DefenderType, building: BuildingItem) {
        let result = DefenderManager.shared.deployDefender(type: type, near: building, playerCurrency: &activePlayer)
        switch result {
        case .success(let defender):
            onStorePurchaseSuccess?("DEPLOYED: Deployed \(defender.name) to guard \(building.name)!")
            onCurrencyUpdated?(activePlayer)
        case .failure(let err):
            onStorePurchaseFailed?("Deployment failed: \(err.localizedDescription)")
        }
    }
}
