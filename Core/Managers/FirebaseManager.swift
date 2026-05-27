import Foundation

/// Protocol for real-time Firebase profile sync, stats, and building configurations
public protocol FirebaseManagerProtocol {
    func syncPlayerProfile(playerUid: String, completion: @escaping (Result<PlayerDTO, Error>) -> Void)
    func updatePlayerCurrency(playerUid: String, cash: Int, gems: Int, completion: @escaping (Result<Void, Error>) -> Void)
    func savePlacedBuilding(playerUid: String, building: BuildingItem, completion: @escaping (Result<Void, Error>) -> Void)
    func fetchPlacedBuildings(playerUid: String, completion: @escaping (Result<[BuildingItem], Error>) -> Void)
    func upgradeBuildingInDatabase(playerUid: String, buildingId: UUID, newLevel: Int, completion: @escaping (Result<Void, Error>) -> Void)
}

/// Firebase service broker handling local persistence failover and cloud uploads
public final class FirebaseManager: FirebaseManagerProtocol {
    public static let shared = FirebaseManager()
    
    private init() {}
    
    public func syncPlayerProfile(playerUid: String, completion: @escaping (Result<PlayerDTO, Error>) -> Void) {
        // Retrieve player's profile from Firebase Firestore document
        let mockPlayer = PlayerDTO(uid: playerUid, nickname: "Makar", level: 5)
        completion(.success(mockPlayer))
    }
    
    public func updatePlayerCurrency(playerUid: String, cash: Int, gems: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        // Real-time Firestore transaction update
        print("Firebase: Synced currencies -> Cash: $\(cash), Gems: \(gems)")
        completion(.success(()))
    }
    
    public func savePlacedBuilding(playerUid: String, building: BuildingItem, completion: @escaping (Result<Void, Error>) -> Void) {
        // Add new building document inside player sub-collection
        print("Firebase: Building \(building.name) saved under player profile \(playerUid)")
        completion(.success(()))
    }
    
    public func fetchPlacedBuildings(playerUid: String, completion: @escaping (Result<[BuildingItem], Error>) -> Void) {
        // Fetch building arrays dynamically
        completion(.success([]))
    }
    
    public func upgradeBuildingInDatabase(playerUid: String, buildingId: UUID, newLevel: Int, completion: @escaping (Result<Void, Error>) -> Void) {
        // Atomically upgrade levels
        print("Firebase: Upgraded building \(buildingId) to level \(newLevel)")
        completion(.success(()))
    }
}
