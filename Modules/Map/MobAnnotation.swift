import Foundation
import MapKit

public final class MobAnnotation: NSObject, MKAnnotation {
    public dynamic var coordinate: CLLocationCoordinate2D
    public var mobDTO: MobDTO
    
    public var title: String? {
        return "\(mobDTO.type.rawValue) (Lv. \(mobDTO.level))"
    }
    
    public var subtitle: String? {
        return "HP: \(mobDTO.currentHP)/\(mobDTO.maxHP) | DMG: \(mobDTO.damage)"
    }
    
    public init(coordinate: CLLocationCoordinate2D, mobDTO: MobDTO) {
        self.coordinate = coordinate
        self.mobDTO = mobDTO
        super.init()
    }
}
