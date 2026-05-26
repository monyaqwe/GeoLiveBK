import UIKit
import MapKit

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

        if let building = annotation as? BuildingAnnotation {
            let view = (mapView.dequeueReusableAnnotationView(withIdentifier: BuildingAnnotationView.reuseID)
                        as? BuildingAnnotationView)
                       ?? BuildingAnnotationView(annotation: building, reuseIdentifier: BuildingAnnotationView.reuseID)
            view.annotation = building
            view.configure(with: building.buildingItem)
            // tapHandler is kept nil – didSelect handles everything instantly
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

        // Square exclusion barrier
        if let exclusion = overlay as? BuildingExclusionOverlay {
            let renderer = MKPolygonRenderer(polygon: squarePolygon(from: exclusion))
            renderer.fillColor   = UIColor(red: 1.0, green: 0.35, blue: 0.10, alpha: 0.12)
            renderer.strokeColor = UIColor(red: 1.0, green: 0.45, blue: 0.10, alpha: 0.55)
            renderer.lineWidth   = 1.5
            renderer.lineDashPattern = [5, 4]
            return renderer
        }

        if let circle = overlay as? MKCircle {
            let renderer = MKCircleRenderer(circle: circle)
            if circle.radius > 500 {
                // 800m attack-wave ring
                renderer.fillColor   = UIColor.white.withAlphaComponent(0.01)
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.12)
                renderer.lineWidth   = 1.2
                renderer.lineDashPattern = [4, 6]
            } else {
                // 350m build-range ring
                renderer.fillColor   = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.06)
                renderer.strokeColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.28)
                renderer.lineWidth   = 1.5
                renderer.lineDashPattern = [6, 4]
            }
            return renderer
        }

        return MKOverlayRenderer(overlay: overlay)
    }

    // MARK: Tap a building annotation
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let buildingView = view as? BuildingAnnotationView,
              let annotation   = view.annotation as? BuildingAnnotation else {
            mapView.deselectAnnotation(view.annotation, animated: false)
            return
        }

        // Bounce feedback
        UIView.animate(withDuration: 0.05) {
            buildingView.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
        } completion: { _ in
            UIView.animate(withDuration: 0.08) {
                buildingView.transform = .identity
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

    // MARK: - Helpers

    /// Build a square MKPolygon from an exclusion overlay (for rendering)
    private func squarePolygon(from exclusion: BuildingExclusionOverlay) -> MKPolygon {
        let rect   = exclusion.boundingMapRect
        let points = [
            MKMapPoint(x: rect.minX, y: rect.minY),
            MKMapPoint(x: rect.maxX, y: rect.minY),
            MKMapPoint(x: rect.maxX, y: rect.maxY),
            MKMapPoint(x: rect.minX, y: rect.maxY),
        ]
        return MKPolygon(points: points, count: 4)
    }
}
