import Foundation
import CoreLocation

/// Protocol for real-world mob spawning engine
public protocol MapSpawnerServiceProtocol {
    func spawnMobsAroundLocation(playerCoordinate: CLLocationCoordinate2D, dangerLevel: Int, completion: @escaping ([MobDTO]) -> Void)
    func startProximitySpawnTimer(intervalSeconds: Double, playerLocationProvider: @escaping () -> CLLocationCoordinate2D)
    func stopSpawning()
}

/// Spawns hostile entities in real-world vicinity using scaled difficulty metrics
public final class MapSpawnerService: MapSpawnerServiceProtocol {
    public static let shared = MapSpawnerService()
    
    private var spawnTimer: Timer?
    public var onNewMobsSpawned: (([MobDTO]) -> Void)?
    
    private init() {}
    
    public func spawnMobsAroundLocation(playerCoordinate: CLLocationCoordinate2D, dangerLevel: Int, completion: @escaping ([MobDTO]) -> Void) {
        // High danger levels trigger slightly more mobs (up to 6), faster spawning, and tougher types
        let baseCount = 2
        let extraCount = dangerLevel / 4
        let spawnCount = min(baseCount + extraCount, 6)
        
        var spawnedMobs: [MobDTO] = []
        
        for i in 0..<spawnCount {
            // Pick Mob Type based on danger level weightings
            let type: MobType
            let typeRoll = Int.random(in: 1...100) + (dangerLevel * 5)
            
            if typeRoll < 45 {
                type = .necroRats
            } else if typeRoll < 85 {
                type = .bandits
            } else {
                type = .police
            }
            
            // Truly random distance: between 50 and 1200 meters (reaching far beyond 150m/500m circles)
            let distance = Double.random(in: 50.0...1200.0)
            let angle = Double.random(in: 0.0...(2.0 * .pi))
            
            // 1 degree latitude ~ 111,000 meters
            // 1 degree longitude ~ 111,000 meters * cos(latitude)
            let latOffset = (distance * cos(angle)) / 111000.0
            let lonOffset = (distance * sin(angle)) / (111000.0 * Swift.max(cos(playerCoordinate.latitude * .pi / 180.0), 0.1))
            
            let mobLat = playerCoordinate.latitude + latOffset
            let mobLon = playerCoordinate.longitude + lonOffset
            
            let mob = MobDTO(type: type, latitude: mobLat, longitude: mobLon, dangerLevel: dangerLevel)
            spawnedMobs.append(mob)
        }
        
        completion(spawnedMobs)
    }
    
    public func startProximitySpawnTimer(intervalSeconds: Double, playerLocationProvider: @escaping () -> CLLocationCoordinate2D) {
        stopSpawning()
        
        // Base dynamic interval gets shortened as dangerLevel rises
        let currentDanger = DangerLevelManager.shared.currentDangerLevel
        let adjustedInterval = max(intervalSeconds - Double(currentDanger * 2), 5.0)
        
        spawnTimer = Timer.scheduledTimer(withTimeInterval: adjustedInterval, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 40% chance to actually trigger a spawn tick (slightly less frequent spawning)
            guard Double.random(in: 0...1) < 0.40 else { return }
            
            let coord = playerLocationProvider()
            self.spawnMobsAroundLocation(playerCoordinate: coord, dangerLevel: DangerLevelManager.shared.currentDangerLevel) { [weak self] mobs in
                self?.onNewMobsSpawned?(mobs)
            }
        }
    }
    
    public func stopSpawning() {
        spawnTimer?.invalidate()
        spawnTimer = nil
    }
}
