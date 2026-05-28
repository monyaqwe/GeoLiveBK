import UIKit
import MapKit

// MARK: - Building Annotation View
public final class BuildingAnnotationView: MKAnnotationView {
    public static let reuseID = "BuildingAnnotationView"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.12, alpha: 0.88)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        view.sendSubviewToBack(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 22)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 9, weight: .black)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(red: 0.15, green: 0.55, blue: 0.95, alpha: 1.0)
        label.layer.cornerRadius = 7
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let groundShadowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        view.layer.cornerRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public var tapHandler: (() -> Void)?
    
    private func setupView() {
        canShowCallout = false
        backgroundColor = .clear
        
        frame = CGRect(x: 0, y: 0, width: 56, height: 62)
        centerOffset = CGPoint(x: 0, y: -24)
        
        containerView.clipsToBounds = true // Clip any emoji/building model overflow inside the square
        
        addSubview(groundShadowView)
        addSubview(containerView)
        containerView.addSubview(emojiLabel)
        addSubview(badgeLabel) // Add to self so it doesn't get clipped by containerView!
        
        NSLayoutConstraint.activate([
            groundShadowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 2),
            groundShadowView.centerXAnchor.constraint(equalTo: centerXAnchor),
            groundShadowView.widthAnchor.constraint(equalToConstant: 30),
            groundShadowView.heightAnchor.constraint(equalToConstant: 10),
            
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            emojiLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -2),
            
            badgeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -4),
            badgeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 4),
            badgeLabel.widthAnchor.constraint(equalToConstant: 24),
            badgeLabel.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    private var isAnimated = false
    
    public func configure(with building: BuildingItem) {
        emojiLabel.text = building.emoji
        badgeLabel.text = "L\(building.level)"
        
        let scale = 1.0 + CGFloat(building.level / 10) * 0.03
        if !isAnimated {
            isAnimated = true
            // Premium bounce animation on first load
            transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                self.transform = CGAffineTransform(scaleX: scale, y: scale)
            }, completion: nil)
        } else {
            self.transform = CGAffineTransform(scaleX: scale, y: scale)
        }
    }
    
    override public func prepareForReuse() {
        super.prepareForReuse()
        isAnimated = false
    }
}

// MARK: - Store Card View
public final class StoreCardView: UIView {
    public let buildingType: BuildingType
    
    public init(type: BuildingType) {
        self.buildingType = type
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
