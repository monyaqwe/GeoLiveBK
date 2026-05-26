import UIKit
import MapKit
import CoreLocation

// MARK: - Building Type
public enum BuildingType: String {
    case kiosk = "Kiosk"
    case cafe  = "Cafe"
    case bar   = "Bar"

    public var cost: Int {
        switch self {
        case .kiosk: return 10000
        case .cafe:  return 20000
        case .bar:   return 30000
        }
    }

    public var emoji: String {
        switch self {
        case .kiosk: return "🏪"
        case .cafe:  return "☕"
        case .bar:   return "🍺"
        }
    }

    /// Minimum build-exclusion radius in metres around an existing building
    public static let exclusionRadius: Double = 100.0
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

    /// Accumulated income (in-game $) waiting to be collected
    public var accumulatedIncome: Int = 0
    /// Timestamp of the last income collection (or placement time)
    public var lastCollectedDate: Date = Date()

    public var name: String  { type.rawValue }
    public var cost: Int     { type.cost }
    public var capacity: Int { level }
    public var emoji: String { type.emoji }

    public var maxHP: Int {
        return 100 + (staffLevel * 20) + (equipLevel * 30)
    }

    /// Income per hour for this building
    public var totalIncome: Int {
        let base: Int
        switch type {
        case .kiosk: base = level * 250
        case .cafe:  base = level * 600
        case .bar:   base = level * 1000
        }
        return base + (staffLevel * 150) + (equipLevel * 250)
    }

    /// Income accumulated since last collection, capped at 8 hours
    public var pendingIncome: Int {
        let elapsed = Date().timeIntervalSince(lastCollectedDate)
        let hours   = min(elapsed / 3600.0, 8.0)   // cap at 8 hrs
        return Int(Double(totalIncome) * hours) + accumulatedIncome
    }

    /// Consume all pending income and return the amount collected
    public mutating func collectIncome() -> Int {
        let amount = pendingIncome
        accumulatedIncome  = 0
        lastCollectedDate  = Date()
        return amount
    }

    public init(type: BuildingType, coordinate: CLLocationCoordinate2D) {
        self.type              = type
        self.coordinate        = coordinate
        self.currentHP         = 100
        self.lastCollectedDate = Date()
    }
}

// MARK: - Building Annotation
public final class BuildingAnnotation: NSObject, MKAnnotation {
    public dynamic var coordinate: CLLocationCoordinate2D
    public var buildingItem: BuildingItem

    public var title: String? { "\(buildingItem.name) (Lv. \(buildingItem.level))" }
    public var subtitle: String? {
        "HP: \(buildingItem.currentHP)/\(buildingItem.maxHP) | Income: $\(buildingItem.totalIncome)/hr"
    }

    public init(coordinate: CLLocationCoordinate2D, buildingItem: BuildingItem) {
        self.coordinate   = coordinate
        self.buildingItem = buildingItem
        super.init()
    }
}


