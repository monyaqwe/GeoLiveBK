import Foundation
import CoreLocation

/// Represents a Defender type purchaseable in the Store
public enum DefenderType: String, Codable, CaseIterable {
    case scout   = "Scout Guard"
    case enforcer = "Enforcer Sentry"
    case heavy    = "Heavy Sentinel"
    
    public var costCash: Int {
        switch self {
        case .scout:    return 3000
        case .enforcer: return 8000
        case .heavy:    return 15000
        }
    }
    
    public var costGems: Int {
        switch self {
        case .scout:    return 0
        case .enforcer: return 5
        case .heavy:    return 12
        }
    }
    
    public var damage: Int {
        switch self {
        case .scout:    return 12
        case .enforcer: return 28
        case .heavy:    return 65
        }
    }
    
    public var maxHP: Int {
        switch self {
        case .scout:    return 150
        case .enforcer: return 350
        case .heavy:    return 800
        }
    }
    
    public var fireRate: Double {
        switch self {
        case .scout:    return 1.5
        case .enforcer: return 3.0
        case .heavy:    return 0.8
        }
    }
}

/// DTO representing an active AI defender deployed near building markers
public struct DefenderDTO: Codable {
    public let id: UUID
    public let type: DefenderType
    public var name: String
    
    // Position tied to a building marker
    public var buildingId: UUID
    public var latitude: Double
    public var longitude: Double
    
    // Status stats
    public var currentHP: Int
    public var maxHP: Int
    public var level: Int
    
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    public init(id: UUID = UUID(), type: DefenderType, buildingId: UUID, latitude: Double, longitude: Double, level: Int = 1) {
        self.id = id
        self.type = type
        self.name = type.rawValue
        self.buildingId = buildingId
        self.latitude = latitude
        self.longitude = longitude
        self.maxHP = type.maxHP + (level - 1) * 50
        self.currentHP = self.maxHP
        self.level = level
    }
}
