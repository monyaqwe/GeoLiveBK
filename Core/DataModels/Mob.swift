import Foundation
import CoreLocation

/// Represents types of hostile mobs roaming the real-world vicinity
public enum MobType: String, Codable, CaseIterable {
    case police     = "Police"
    case bandits    = "Bandits"
    case necroRats  = "Necro-Rats"
    
    public var baseHP: Int {
        switch self {
        case .necroRats: return 40
        case .bandits:   return 80
        case .police:    return 150
        }
    }
    
    public var baseDamage: Int {
        switch self {
        case .necroRats: return 8
        case .bandits:   return 15
        case .police:    return 25
        }
    }
    
    public var baseXP: Int {
        switch self {
        case .necroRats: return 50
        case .bandits:   return 120
        case .police:    return 250
        }
    }
}

/// Dynamic Data Transfer Object for Mobs spawned on the map
public struct MobDTO: Codable {
    public let id: UUID
    public var groupId: UUID?
    public let type: MobType
    public var latitude: Double
    public var longitude: Double
    
    // Dynamic Scaled Stats based on Danger Level
    public var currentHP: Int
    public var maxHP: Int
    public var damage: Int
    public var level: Int
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public init(id: UUID = UUID(), groupId: UUID? = nil, type: MobType, latitude: Double, longitude: Double, dangerLevel: Int) {
        self.id = id
        self.groupId = groupId
        self.type = type
        self.latitude = latitude
        self.longitude = longitude
        self.level = dangerLevel
        
        // Scale HP and damage with danger level (e.g., +15% per danger level)
        let multiplier = 1.0 + (Double(dangerLevel - 1) * 0.15)
        let scaledHP = Int(Double(type.baseHP) * multiplier)
        self.maxHP = scaledHP
        self.currentHP = scaledHP
        self.damage = Int(Double(type.baseDamage) * multiplier)
    }
}
