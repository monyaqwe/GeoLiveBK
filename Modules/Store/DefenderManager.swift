import Foundation
import CoreLocation

/// Protocol for controlling AI defenders
public protocol DefenderManagerProtocol {
    var activeDefenders: [DefenderDTO] { get }
    func deployDefender(type: DefenderType, near building: BuildingItem, playerCurrency: inout PlayerDTO) -> Result<DefenderDTO, Error>
    func updateDefenders(completion: @escaping ([DefenderDTO]) -> Void)
}

public enum DefenderError: Error {
    case insufficientFunds
    case maxDefendersReached
}

/// Deploys AI defense units around building nodes to ward off hostiles
public final class DefenderManager: DefenderManagerProtocol {
    public static let shared = DefenderManager()
    
    private var _defenders: [DefenderDTO] = []
    
    public var activeDefenders: [DefenderDTO] {
        return _defenders
    }
    
    private init() {}
    
    public func deployDefender(type: DefenderType, near building: BuildingItem, playerCurrency: inout PlayerDTO) -> Result<DefenderDTO, Error> {
        // Check funds
        if type.costGems > 0 {
            guard playerCurrency.gems >= type.costGems else {
                return .failure(DefenderError.insufficientFunds)
            }
            playerCurrency.gems -= type.costGems
        } else {
            guard playerCurrency.cash >= type.costCash else {
                return .failure(DefenderError.insufficientFunds)
            }
            playerCurrency.cash -= type.costCash
        }
        
        // Spawn slightly offset from the building marker (~5m)
        let latOffset = Double.random(in: -0.00005...0.00005)
        let lonOffset = Double.random(in: -0.00005...0.00005)
        
        let defCoord = CLLocationCoordinate2D(
            latitude: building.coordinate.latitude + latOffset,
            longitude: building.coordinate.longitude + lonOffset
        )
        
        let defender = DefenderDTO(
            type: type,
            buildingId: building.id,
            latitude: defCoord.latitude,
            longitude: defCoord.longitude
        )
        
        _defenders.append(defender)
        print("Defenders: Placed \(type.rawValue) defender guarding building \(building.name)")
        
        FirebaseManager.shared.updatePlayerCurrency(playerUid: playerCurrency.uid, cash: playerCurrency.cash, gems: playerCurrency.gems) { _ in }
        
        return .success(defender)
    }
    
    public func updateDefenders(completion: @escaping ([DefenderDTO]) -> Void) {
        // Regenerate defender HP or track defensive hits passively
        completion(_defenders)
    }
}
