import UIKit

/// High-intensity warning banner triggered on threat increments or boss spawns
public final class DangerAlertNotification: UIView {
    
    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.08, alpha: 0.90)
        v.layer.cornerRadius = 18
        v.layer.borderWidth = 1.2
        v.layer.borderColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 0.55).cgColor
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        v.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: v.topAnchor),
            blur.leadingAnchor.constraint(equalTo: v.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: v.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: v.bottomAnchor)
        ])
        return v
    }()
    
    private let warningLabel: UILabel = {
        let label = UILabel()
        label.text = "⚠️ THREAT LEVEL INCREMENT"
        label.textColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 12, weight: .black)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.numberOfLines = 2
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public init(message: String) {
        super.init(frame: .zero)
        self.detailLabel.text = message
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        translatesAutoresizingMaskIntoConstraints = false
        addSubview(container)
        container.addSubview(warningLabel)
        container.addSubview(detailLabel)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            warningLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 12),
            warningLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            detailLabel.topAnchor.constraint(equalTo: warningLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            detailLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            detailLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -12)
        ])
    }
    
    /// Spawns and shakes a danger notification HUD
    public static func show(message: String, in view: UIView) {
        let hud = DangerAlertNotification(message: message)
        view.addSubview(hud)
        
        NSLayoutConstraint.activate([
            hud.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hud.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 120),
            hud.widthAnchor.constraint(equalToConstant: 300)
        ])
        
        hud.alpha = 0.0
        hud.transform = CGAffineTransform(scaleX: 0.80, y: 0.80).translatedBy(x: 0, y: -30)
        
        // Dynamic impact haptics
        let haptics = UINotificationFeedbackGenerator()
        haptics.notificationOccurred(.warning)
        
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.70, initialSpringVelocity: 0.5, options: .curveEaseOut) {
            hud.alpha = 1.0
            hud.transform = .identity
        } completion: { _ in
            // Subtle alarm pulsing animation
            UIView.animate(withDuration: 0.5, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction]) {
                hud.layer.borderColor = UIColor(red: 1.00, green: 0.10, blue: 0.10, alpha: 1.0).cgColor
                hud.transform = CGAffineTransform(scaleX: 1.03, y: 1.03)
            }
            
            // Dismissal
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                hud.layer.removeAllAnimations()
                UIView.animate(withDuration: 0.3, animations: {
                    hud.alpha = 0.0
                    hud.transform = CGAffineTransform(scaleX: 0.85, y: 0.85).translatedBy(x: 0, y: -20)
                }) { _ in
                    hud.removeFromSuperview()
                }
            }
        }
    }
}
