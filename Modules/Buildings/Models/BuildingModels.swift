import UIKit
import MapKit
import CoreLocation

// MARK: - Building Type
public enum BuildingType: String {
    case kiosk = "Kiosk"
    case cafe = "Cafe"
    case bar = "Bar"
    
    public var cost: Int {
        switch self {
        case .kiosk: return 10000
        case .cafe: return 20000
        case .bar: return 30000
        }
    }
    
    public var emoji: String {
        switch self {
        case .kiosk: return "🏪"
        case .cafe: return "☕"
        case .bar: return "🍺"
        }
    }
}

// MARK: - Building Item
public struct BuildingItem {
    public let id = UUID()
    public let type: BuildingType
    public var coordinate: CLLocationCoordinate2D
    public var level: Int = 1
    public var staffLevel: Int = 0
    public var equipLevel: Int = 0
    public var currentHP: Int = 100
    
    public var name: String { type.rawValue }
    public var cost: Int { type.cost }
    public var capacity: Int { level }
    public var emoji: String { type.emoji }
    
    public var maxHP: Int {
        return 100 + (staffLevel * 20) + (equipLevel * 30)
    }
    
    public var totalIncome: Int {
        let baseIncome: Int
        switch type {
        case .kiosk: baseIncome = level * 250
        case .cafe: baseIncome = level * 600
        case .bar: baseIncome = level * 1000
        }
        return baseIncome + (staffLevel * 150) + (equipLevel * 250)
    }
    
    public init(type: BuildingType, coordinate: CLLocationCoordinate2D) {
        self.type = type
        self.coordinate = coordinate
        self.currentHP = 100
    }
}

// MARK: - Building Annotation
public final class BuildingAnnotation: NSObject, MKAnnotation {
    public dynamic var coordinate: CLLocationCoordinate2D
    public var buildingItem: BuildingItem
    
    public var title: String? { "\(buildingItem.name) (Lv. \(buildingItem.level))" }
    public var subtitle: String? {
        return "HP: \(buildingItem.currentHP)/\(buildingItem.maxHP) | Income: $\(buildingItem.totalIncome)/hr"
    }
    
    public init(coordinate: CLLocationCoordinate2D, buildingItem: BuildingItem) {
        self.coordinate = coordinate
        self.buildingItem = buildingItem
        super.init()
    }
}
