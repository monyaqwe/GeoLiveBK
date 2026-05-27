import UIKit

/// Tactical loot banner overlay rendering XP skulls and rare weapons collection events
public final class LootAlertNotification: UIView {
    
    private let container: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.10, alpha: 0.85)
        v.layer.cornerRadius = 18
        v.layer.borderWidth = 1.0
        v.layer.borderColor = UIColor(red: 0.25, green: 0.85, blue: 0.45, alpha: 0.35).cgColor
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "LOOT SECURED 📦"
        label.textColor = UIColor(red: 0.25, green: 0.85, blue: 0.45, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 12, weight: .black)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let detailLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        label.numberOfLines = 2
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
        container.addSubview(titleLabel)
        container.addSubview(detailLabel)
        
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
            titleLabel.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            
            detailLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            detailLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            detailLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -16),
            detailLabel.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -10)
        ])
    }
    
    /// Spawns and animates a loot notification HUD on top of parent window
    public static func show(message: String, in view: UIView) {
        let hud = LootAlertNotification(message: message)
        view.addSubview(hud)
        
        NSLayoutConstraint.activate([
            hud.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            hud.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 64),
            hud.widthAnchor.constraint(equalToConstant: 280)
        ])
        
        hud.alpha = 0.0
        hud.transform = CGAffineTransform(scaleX: 0.85, y: 0.85).translatedBy(x: 0, y: -20)
        
        // Premium scale-in slide animation
        UIView.animate(withDuration: 0.4, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.4, options: .curveEaseOut) {
            hud.alpha = 1.0
            hud.transform = .identity
        } completion: { _ in
            UIView.animate(withDuration: 0.35, delay: 2.2, options: .curveEaseIn) {
                hud.alpha = 0.0
                hud.transform = CGAffineTransform(scaleX: 0.90, y: 0.90).translatedBy(x: 0, y: -15)
            } completion: { _ in
                hud.removeFromSuperview()
            }
        }
    }
}
