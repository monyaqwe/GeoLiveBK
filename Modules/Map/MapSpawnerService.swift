import Foundation
import CoreLocation

/// Protocol for real-world mob spawning engine
public protocol MapSpawnerServiceProtocol {
    func spawnMobsAroundLocation(playerCoordinate: CLLocationCoordinate2D, dangerLevel: Int, count: Int, forcedType: MobType?, completion: @escaping ([MobDTO]) -> Void)
    func spawnRevengeWave(playerCoordinate: CLLocationCoordinate2D, dangerLevel: Int, sessionKills: Int, mobType: MobType, completion: @escaping ([MobDTO]) -> Void)
    func startProximitySpawnTimer(intervalSeconds: Double, playerLocationProvider: @escaping () -> CLLocationCoordinate2D)
    func stopSpawning()
}

/// Spawns hostile entities in real-world vicinity using scaled difficulty metrics
public final class MapSpawnerService: MapSpawnerServiceProtocol {
    public static let shared = MapSpawnerService()
    
    private var spawnTimer: Timer?
    public var onNewMobsSpawned: (([MobDTO]) -> Void)?
    
    private init() {}
    
    public func spawnMobsAroundLocation(playerCoordinate: CLLocationCoordinate2D, dangerLevel: Int, count: Int = 1, forcedType: MobType? = nil, completion: @escaping ([MobDTO]) -> Void) {
        var spawnedMobs: [MobDTO] = []
        let waveGroupId = UUID()
        
        for _ in 0..<count {
            let type: MobType
            if let forced = forcedType {
                type = forced
            } else {
                // Pick Mob Type based on danger level weightings
                let typeRoll = Int.random(in: 1...100) + (dangerLevel * 5)
                if typeRoll < 45 {
                    type = .necroRats
                } else if typeRoll < 85 {
                    type = .bandits
                } else {
                    type = .police
                }
            }
            
            // Spawn distance: around the edge of the 500m circle or slightly beyond (480 - 650 meters)
            let distance = Double.random(in: 480.0...650.0)
            let angle = Double.random(in: 0.0...(2.0 * .pi))
            
            // 1 degree latitude ~ 111,000 meters
            // 1 degree longitude ~ 111,000 meters * cos(latitude)
            let latOffset = (distance * cos(angle)) / 111000.0
            let lonOffset = (distance * sin(angle)) / (111000.0 * Swift.max(cos(playerCoordinate.latitude * .pi / 180.0), 0.1))
            
            let mobLat = playerCoordinate.latitude + latOffset
            let mobLon = playerCoordinate.longitude + lonOffset
            
            let specificTypeLevel = DangerLevelManager.shared.level(for: type)
            let mob = MobDTO(groupId: waveGroupId, type: type, latitude: mobLat, longitude: mobLon, dangerLevel: specificTypeLevel)
            spawnedMobs.append(mob)
        }
        
        completion(spawnedMobs)
    }
    
    public func startProximitySpawnTimer(intervalSeconds: Double, playerLocationProvider: @escaping () -> CLLocationCoordinate2D) {
        stopSpawning()
        
        // Exact 1-minute timer (60 seconds) for 1 passive mob
        spawnTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let coord = playerLocationProvider()
            self.spawnMobsAroundLocation(playerCoordinate: coord, dangerLevel: DangerLevelManager.shared.currentDangerLevel, count: 1) { [weak self] mobs in
                self?.onNewMobsSpawned?(mobs)
            }
        }
    }
    
    public func spawnRevengeWave(playerCoordinate: CLLocationCoordinate2D, dangerLevel: Int, sessionKills: Int, mobType: MobType, completion: @escaping ([MobDTO]) -> Void) {
        let spawnCount: Int
        if sessionKills <= 3 {
            spawnCount = 1
        } else if sessionKills <= 7 {
            spawnCount = 2
        } else {
            spawnCount = 3
        }
        
        spawnMobsAroundLocation(playerCoordinate: playerCoordinate, dangerLevel: dangerLevel, count: spawnCount, forcedType: mobType, completion: completion)
    }
    
    public func stopSpawning() {
        spawnTimer?.invalidate()
        spawnTimer = nil
    }
}
