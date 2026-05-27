import Foundation
import CoreLocation

/// ViewModel managing spatial game state, dynamic currencies, and spawner intervals
public final class MapViewModel {
    
    public var activePlayer: PlayerDTO
    public var placedBuildings: [BuildingItem] = []
    
    // Callbacks to notify view layer
    public var onPlayerStatsChanged: ((PlayerDTO) -> Void)?
    public var onBuildingsUpdated: (([BuildingItem]) -> Void)?
    
    public init(initialPlayer: PlayerDTO) {
        self.activePlayer = initialPlayer
    }
    
    /// Collect cash manually or passively from a specific building
    public func collectCash(from buildingId: UUID) -> Int {
        guard let index = placedBuildings.firstIndex(where: { $0.id == buildingId }) else { return 0 }
        
        var building = placedBuildings[index]
        let amount = building.collectIncome()
        
        // Update in-memory building stats
        placedBuildings[index] = building
        
        // Add to player soft currency balance
        activePlayer.cash += amount
        
        // Persist to database
        FirebaseManager.shared.updatePlayerCurrency(playerUid: activePlayer.uid, cash: activePlayer.cash, gems: activePlayer.gems) { _ in }
        FirebaseManager.shared.savePlacedBuilding(playerUid: activePlayer.uid, building: building) { _ in }
        
        onPlayerStatsChanged?(activePlayer)
        onBuildingsUpdated?(placedBuildings)
        
        return amount
    }
    
    /// Triggered passively to gather generated currencies across all buildings
    public func collectAllPassiveCash() -> Int {
        var totalCollected = 0
        for building in placedBuildings {
            totalCollected += collectCash(from: building.id)
        }
        return totalCollected
    }
    
    /// Upgrade building parameters and register with Firebase
    public func upgradeBuilding(buildingId: UUID) {
        guard let index = placedBuildings.firstIndex(where: { $0.id == buildingId }) else { return }
        
        var building = placedBuildings[index]
        let currentLevel = building.level
        let upgradeCost = StatCalculationService.shared.calculateUpgradeCost(currentLevel: currentLevel)
        
        if activePlayer.cash >= upgradeCost {
            activePlayer.cash -= upgradeCost
            building.level += 1
            
            // Level up grants +500 coins and increases max HP
            activePlayer.cash += 500
            
            placedBuildings[index] = building
            
            FirebaseManager.shared.updatePlayerCurrency(playerUid: activePlayer.uid, cash: activePlayer.cash, gems: activePlayer.gems) { _ in }
            FirebaseManager.shared.upgradeBuildingInDatabase(playerUid: activePlayer.uid, buildingId: building.id, newLevel: building.level) { _ in }
            
            onPlayerStatsChanged?(activePlayer)
            onBuildingsUpdated?(placedBuildings)
        }
    }
}
