import UIKit
import MapKit

// MARK: - MKMapViewDelegate
extension MainMapViewController: MKMapViewDelegate {
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            // Defensively force hide the Apple blue dot by returning a completely invisible, zero-sized view
            let identifier = "InvisibleUserLocation"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.frame = .zero
                view?.isEnabled = false
            }
            return view
        }
        
        if let buildingAnnotation = annotation as? BuildingAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: BuildingAnnotationView.reuseID) as? BuildingAnnotationView
                ?? BuildingAnnotationView(annotation: buildingAnnotation, reuseIdentifier: BuildingAnnotationView.reuseID)
            view.annotation = buildingAnnotation
            view.configure(with: buildingAnnotation.buildingItem)
            
            // Hook up instant selection touch callback (retained for safety, though didSelect takes precedence)
            view.tapHandler = { [weak self] in
                self?.showBuildingInspectionPanel(for: buildingAnnotation)
            }
            return view
        }
        
        guard let avatarAnnotation = annotation as? AvatarAnnotation else { return nil }
        
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: AvatarAnnotationView.reuseID) as? AvatarAnnotationView
            ?? AvatarAnnotationView(annotation: annotation, reuseIdentifier: AvatarAnnotationView.reuseID)
        
        view.annotation = avatarAnnotation
        view.configure(with: avatarAnnotation.avatarImage)
        return view
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            if circleOverlay.radius > 500 {
                // Interactive 800m attack range wave overlay (soft white wave)
                let renderer = MKCircleRenderer(circle: circleOverlay)
                renderer.fillColor = UIColor.white.withAlphaComponent(0.01)
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.12)
                renderer.lineWidth = 1.2
                renderer.lineDashPattern = [4, 6] // Thin white wave pattern
                return renderer
            } else {
                // Interactive 350m build range circle overlay (clearly read but elegant electric blue)
                let renderer = MKCircleRenderer(circle: circleOverlay)
                renderer.fillColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.06)
                renderer.strokeColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.28)
                renderer.lineWidth = 1.5
                renderer.lineDashPattern = [6, 4] // Dashed outline
                return renderer
            }
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if let buildingView = view as? BuildingAnnotationView,
           let buildingAnnotation = view.annotation as? BuildingAnnotation {
            // Snappy premium bounce animation on tap
            UIView.animate(withDuration: 0.05, animations: {
                buildingView.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
            }) { _ in
                UIView.animate(withDuration: 0.05) {
                    buildingView.transform = .identity
                }
            }
            self.showBuildingInspectionPanel(for: buildingAnnotation)
        }
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
}
