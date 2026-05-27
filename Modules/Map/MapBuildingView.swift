import UIKit
import MapKit

/// Futuristic, premium building annotation view that solves the icon overflow issue.
/// Features a strict 40x40 bounding box with dual-layer clipping boundaries.
public final class MapBuildingView: MKAnnotationView {
    
    public static let reuseIdentifier = "MapBuildingView"
    
    // Core structural container to enforce 40x40 clipping boundaries
    private let iconContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.12, alpha: 0.90)
        view.layer.cornerRadius = 10
        view.layer.borderWidth = 1.2
        view.layer.borderColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.40).cgColor
        
        // CRITICAL FIX: The container MUST clip all subviews and overflow content
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Subview for displaying high-tech building vector assets or custom icons
    private let buildingImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.tintColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        
        // CRITICAL FIX: The UIImageView must also clip its bounds so the icon never overflows
        iv.clipsToBounds = true
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private let levelBadge: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 8, weight: .black)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Decorative subtle shadow to anchor the building to the tactical grid
    private let bottomShadow: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.40)
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // MARK: - Init
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupLayout()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayout() {
        canShowCallout = false
        backgroundColor = .clear
        
        // Setup visual hierarchy
        addSubview(bottomShadow)
        addSubview(iconContainer)
        iconContainer.addSubview(buildingImageView)
        addSubview(levelBadge)
        
        // CRITICAL Auto Layout fixes to guarantee exact 40x40 dimension
        NSLayoutConstraint.activate([
            // Shadow anchor constraints
            bottomShadow.centerXAnchor.constraint(equalTo: centerXAnchor),
            bottomShadow.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4),
            bottomShadow.widthAnchor.constraint(equalToConstant: 24),
            bottomShadow.heightAnchor.constraint(equalToConstant: 8),
            
            // Enforce EXACT 40x40 sizing on container view
            iconContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            iconContainer.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),
            
            // UIImageView must match parent container constraints exactly
            buildingImageView.topAnchor.constraint(equalTo: iconContainer.topAnchor),
            buildingImageView.leadingAnchor.constraint(equalTo: iconContainer.leadingAnchor),
            buildingImageView.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor),
            buildingImageView.bottomAnchor.constraint(equalTo: iconContainer.bottomAnchor),
            
            // Level badge top right anchor
            levelBadge.topAnchor.constraint(equalTo: iconContainer.topAnchor, constant: -4),
            levelBadge.trailingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 4),
            levelBadge.widthAnchor.constraint(equalToConstant: 16),
            levelBadge.heightAnchor.constraint(equalToConstant: 12)
        ])
    }
    
    // MARK: - Configuration
    public func configure(with building: BuildingItem) {
        levelBadge.text = "\(building.level)"
        
        // Dynamic icon association based on building types
        let config = UIImage.SymbolConfiguration(pointSize: 22, weight: .bold)
        let icon: UIImage?
        
        switch building.type {
        case .kiosk:
            icon = UIImage(systemName: "cart.fill", withConfiguration: config)
        case .cafe:
            icon = UIImage(systemName: "cup.and.saucer.fill", withConfiguration: config)
        case .bar:
            icon = UIImage(systemName: "wineglass.fill", withConfiguration: config)
        }
        
        buildingImageView.image = icon
        
        // Gentle premium scale animation on config
        transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            self.transform = .identity
        }
    }
}
