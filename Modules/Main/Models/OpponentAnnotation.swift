import Foundation
import MapKit

public final class OpponentAnnotation: NSObject, MKAnnotation {
    public let id: String
    public let nickname: String
    public dynamic var coordinate: CLLocationCoordinate2D
    public var hp: Int
    public var maxHP: Int
    public var level: Int
    
    public var title: String? { "\(nickname)" }
    public var subtitle: String? { "LVL \(level) • HP \(hp)/\(maxHP)" }
    
    public init(id: String, nickname: String, coordinate: CLLocationCoordinate2D, hp: Int, maxHP: Int, level: Int) {
        self.id = id
        self.nickname = nickname
        self.coordinate = coordinate
        self.hp = hp
        self.maxHP = maxHP
        self.level = level
        super.init()
    }
}
