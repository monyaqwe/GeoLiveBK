import UIKit
import MapKit

// MARK: - Skull Annotation Model
public final class SkullAnnotation: NSObject, MKAnnotation {
    public dynamic var coordinate: CLLocationCoordinate2D
    public var title: String? { "REMAINS 💀" }
    public var subtitle: String? { "Tap to collect remains for +1 XP!" }
    
    public init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

// MARK: - Skull Annotation View
public final class SkullAnnotationView: MKAnnotationView {
    public static let reuseIdentifier = "SkullAnnotationView"
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.text = "💀"
        label.font = .systemFont(ofSize: 32)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    private func setupView() {
        frame = CGRect(x: 0, y: 0, width: 40, height: 40)
        centerOffset = CGPoint(x: 0, y: -20)
        addSubview(emojiLabel)
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            emojiLabel.widthAnchor.constraint(equalToConstant: 40),
            emojiLabel.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        layer.shadowColor = UIColor.red.cgColor
        layer.shadowRadius = 6.0
        layer.shadowOpacity = 0.8
        layer.shadowOffset = .zero
    }
}

// MARK: - MKMapViewDelegate
extension MainMapViewController: MKMapViewDelegate {

    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        // Hide the native blue dot
        if annotation is MKUserLocation {
            let id = "InvisibleUserLocation"
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: id)
                ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
            view.frame   = .zero
            view.isEnabled = false
            return view
        }

        if let skullAnn = annotation as? SkullAnnotation {
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: SkullAnnotationView.reuseIdentifier)
                        as? SkullAnnotationView)
                       ?? SkullAnnotationView(annotation: skullAnn, reuseIdentifier: SkullAnnotationView.reuseIdentifier)
            view.annotation = skullAnn
            return view
        }

        if let mobAnn = annotation as? MobAnnotation {
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: MobAnnotationView.reuseIdentifier)
                        as? MobAnnotationView)
                       ?? MobAnnotationView(annotation: mobAnn, reuseIdentifier: MobAnnotationView.reuseIdentifier)
            view.annotation = mobAnn
            view.configure(with: mobAnn.mobDTO)
            return view
        }

        if let building = annotation as? BuildingAnnotation {
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: BuildingAnnotationView.reuseID)
                        as? BuildingAnnotationView)
                       ?? BuildingAnnotationView(annotation: building, reuseIdentifier: BuildingAnnotationView.reuseID)
            view.annotation = building
            view.configure(with: building.buildingItem)
            view.tapHandler = nil
            return view
        }

        guard let avatarAnn = annotation as? AvatarAnnotation else { return nil }
        let view = (mapView.dequeueReusableAnnotationView(withIdentifier: AvatarAnnotationView.reuseID)
                    as? AvatarAnnotationView)
                   ?? AvatarAnnotationView(annotation: avatarAnn, reuseIdentifier: AvatarAnnotationView.reuseID)
         view.annotation = avatarAnn
         view.configure(with: avatarAnn.avatarImage)
         return view
    }

    // MARK: Overlay rendering
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if let zonesOverlay = overlay as? BuildingExclusionZonesOverlay {
            return BuildingExclusionZonesRenderer(overlay: zonesOverlay)
        }

        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            if circle.radius >= 500 {
                // 500m attack-wave ring
                renderer.fillColor   = UIColor.white.withAlphaComponent(0.01)
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.12)
                renderer.lineWidth   = 1.2
                renderer.lineDashPattern = [4, 6]
            } else if circle.radius == 150 {
                // 150m build-range ring
                renderer.fillColor   = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.06)
                renderer.strokeColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.28)
                renderer.lineWidth   = 1.5
                renderer.lineDashPattern = [6, 4]
            } else {
                // 100m building exclusion ring
                renderer.fillColor   = UIColor(red: 1.0, green: 0.35, blue: 0.10, alpha: 0.12)
                renderer.strokeColor = UIColor(red: 1.0, green: 0.45, blue: 0.10, alpha: 0.55)
                renderer.lineWidth   = 1.5
                renderer.lineDashPattern = [5, 4]
            }
            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    // MARK: Tap a building or mob annotation
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let skullAnn = view.annotation as? SkullAnnotation {
            self.collectSkull(skullAnn)
            mapView.deselectAnnotation(skullAnn, animated: false)
            return
        }

        if let mobAnn = view.annotation as? MobAnnotation {
            self.targetMob(mobAnn)
            mapView.deselectAnnotation(mobAnn, animated: false)
            return
        }

        guard let buildingView = view as? BuildingAnnotationView,
              let annotation   = view.annotation as? BuildingAnnotation else {
            mapView.deselectAnnotation(view.annotation, animated: false)
            return
        }

        // Bounce feedback
        let targetScale = 1.0 + CGFloat(annotation.buildingItem.level / 10) * 0.03
        UIView.animate(withDuration: 0.05) {
            buildingView.transform = CGAffineTransform(scaleX: targetScale * 0.90, y: targetScale * 0.90)
        } completion: { _ in
            UIView.animate(withDuration: 0.08) {
                buildingView.transform = CGAffineTransform(scaleX: targetScale, y: targetScale)
            }
        }

        // Auto-collect if pending >= 1 hr income
        let pending = annotation.buildingItem.pendingIncome
        if pending >= annotation.buildingItem.totalIncome {
            collectIncomeFromAnnotation(annotation)
        }

        mapView.deselectAnnotation(annotation, animated: false)
        showBuildingInspectionPanel(for: annotation)
    }
}
