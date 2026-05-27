import UIKit
import MapKit

// MARK: - Avatar Annotation View
/// Renders the user's character standing directly on the map with a soft ground shadow in a premium Snapchat style.
public final class AvatarAnnotationView: MKAnnotationView {
    
    public static let reuseID = "AvatarAnnotationView"
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Floating tactical HP Bar overlay above head
    private let hpContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.70)
        view.layer.cornerRadius = 2.5
        view.layer.borderWidth = 0.5
        view.layer.borderColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.30).cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()
    
    private let hpBarFill: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let groundShadowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        view.layer.cornerRadius = 7 // Perfect half of height (14)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var hpFillWidthConstraint: NSLayoutConstraint?
    private var hpBarHideTimer: Timer?
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        canShowCallout = false
        backgroundColor = .clear
        
        let annotationWidth: CGFloat = 110
        let annotationHeight: CGFloat = 110
        
        frame = CGRect(x: 0, y: 0, width: annotationWidth, height: annotationHeight)
        centerOffset = CGPoint(x: 0, y: -annotationHeight / 2)
        
        addSubview(groundShadowView)
        addSubview(avatarImageView)
        
        // Mount HP bar
        addSubview(hpContainer)
        hpContainer.addSubview(hpBarFill)
        
        hpFillWidthConstraint = hpBarFill.widthAnchor.constraint(equalTo: hpContainer.widthAnchor, multiplier: 1.0)
        
        NSLayoutConstraint.activate([
            // Soft ground shadow centered exactly at the bottom under the feet
            groundShadowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4),
            groundShadowView.centerXAnchor.constraint(equalTo: centerXAnchor),
            groundShadowView.widthAnchor.constraint(equalToConstant: 56),
            groundShadowView.heightAnchor.constraint(equalToConstant: 14),
            
            // Standing avatar completely filling the square view, aligning its feet precisely with the shadow
            avatarImageView.topAnchor.constraint(equalTo: topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            // Floating HP bar constraints
            hpContainer.bottomAnchor.constraint(equalTo: avatarImageView.topAnchor, constant: -4),
            hpContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            hpContainer.widthAnchor.constraint(equalToConstant: 44),
            hpContainer.heightAnchor.constraint(equalToConstant: 5),
            
            hpBarFill.leadingAnchor.constraint(equalTo: hpContainer.leadingAnchor),
            hpBarFill.topAnchor.constraint(equalTo: hpContainer.topAnchor),
            hpBarFill.bottomAnchor.constraint(equalTo: hpContainer.bottomAnchor),
            hpFillWidthConstraint!
        ])
        
        // Premium spring-bounce entrance animation when character appears
        transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        alpha = 0.0
        UIView.animate(withDuration: 0.65, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.transform = .identity
            self.alpha = 1.0
        }, completion: nil)
    }
    
    public func configure(with image: UIImage?) {
        avatarImageView.image = image
    }
    
    // Updates HP value dynamically and triggers the floating visual bar
    public func updateHP(current: Int, max: Int) {
        hpBarHideTimer?.invalidate()
        
        let ratio = max > 0 ? CGFloat(current) / CGFloat(max) : 0.0
        hpContainer.isHidden = false
        
        // Colors scaling with health level
        if ratio > 0.5 {
            hpBarFill.backgroundColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0) // Neon Cyan
        } else if ratio > 0.25 {
            hpBarFill.backgroundColor = UIColor(red: 1.00, green: 0.60, blue: 0.10, alpha: 1.0) // Alert Orange
        } else {
            hpBarFill.backgroundColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0) // Warning Red
        }
        
        UIView.animate(withDuration: 0.20) {
            self.hpFillWidthConstraint?.isActive = false
            self.hpFillWidthConstraint = self.hpBarFill.widthAnchor.constraint(equalTo: self.hpContainer.widthAnchor, multiplier: ratio)
            self.hpFillWidthConstraint?.isActive = true
            self.layoutIfNeeded()
        }
        
        // Fade out HP view after 3 seconds of peace
        hpBarHideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { [weak self] _ in
            UIView.animate(withDuration: 0.30) {
                self?.hpContainer.alpha = 0.0
            } completion: { _ in
                self?.hpContainer.isHidden = true
                self?.hpContainer.alpha = 1.0
            }
        }
    }
    
    // Triggers damage feedback effects
    public func triggerDamageFlash() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        UIView.animate(withDuration: 0.08, animations: {
            self.avatarImageView.alpha = 0.6
            self.avatarImageView.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
        }) { _ in
            UIView.animate(withDuration: 0.12) {
                self.avatarImageView.alpha = 1.0
                self.avatarImageView.transform = .identity
            }
        }
    }
}
