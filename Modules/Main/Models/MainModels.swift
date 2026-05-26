import UIKit
import MapKit
import CoreLocation

// MARK: - Avatar Annotation
/// Custom annotation that holds the user's avatar image to display on the map.
public final class AvatarAnnotation: NSObject, MKAnnotation {
    public dynamic var coordinate: CLLocationCoordinate2D
    public var avatarImage: UIImage?
    
    public init(coordinate: CLLocationCoordinate2D, avatarImage: UIImage?) {
        self.coordinate = coordinate
        super.init()
        self.avatarImage = avatarImage
    }
}

// MARK: - Game Quest
/// Represents an achievement/quest that can be completed to earn gems.
public struct GameQuest {
    public let id: String
    public let title: String
    public let requiredCount: Int
    public let rewardGems: Int // Changed from rewardCoins to give gems
    public var isClaimed: Bool
    
    public init(id: String, title: String, requiredCount: Int, rewardGems: Int, isClaimed: Bool) {
        self.id = id
        self.title = title
        self.requiredCount = requiredCount
        self.rewardGems = rewardGems
        self.isClaimed = isClaimed
    }
}
