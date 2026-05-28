import UIKit
import MapKit

public final class MobAnnotationView: MKAnnotationView {
    public static let reuseIdentifier = "MobAnnotationView"
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 40)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let hpContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let hpBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 1.0)
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let levelBadge: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 9, weight: .black)
        label.textColor = .black
        label.backgroundColor = UIColor(red: 1.0, green: 0.9, blue: 0.0, alpha: 1.0)
        label.layer.cornerRadius = 7
        label.clipsToBounds = true
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
        frame = CGRect(x: 0, y: 0, width: 52, height: 62)
        centerOffset = CGPoint(x: 0, y: -26)
        
        addSubview(emojiLabel)
        addSubview(hpContainer)
        hpContainer.addSubview(hpBar)
        addSubview(levelBadge)
        
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            emojiLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            emojiLabel.widthAnchor.constraint(equalToConstant: 40),
            emojiLabel.heightAnchor.constraint(equalToConstant: 40),
            
            hpContainer.topAnchor.constraint(equalTo: topAnchor),
            hpContainer.centerXAnchor.constraint(equalTo: centerXAnchor),
            hpContainer.widthAnchor.constraint(equalToConstant: 40),
            hpContainer.heightAnchor.constraint(equalToConstant: 4),
            
            hpBar.leadingAnchor.constraint(equalTo: hpContainer.leadingAnchor),
            hpBar.topAnchor.constraint(equalTo: hpContainer.topAnchor),
            hpBar.bottomAnchor.constraint(equalTo: hpContainer.bottomAnchor),
            hpBar.widthAnchor.constraint(equalTo: hpContainer.widthAnchor, multiplier: 1.0),
            
            levelBadge.trailingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 4),
            levelBadge.bottomAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 4),
            levelBadge.widthAnchor.constraint(equalToConstant: 14),
            levelBadge.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    public func configure(with mob: MobDTO) {
        switch mob.type {
        case .necroRats:
            emojiLabel.text = "🐀"
            layer.shadowColor = UIColor.systemGreen.cgColor
        case .bandits:
            emojiLabel.text = "👤"
            layer.shadowColor = UIColor.systemOrange.cgColor
        case .police:
            emojiLabel.text = "👮"
            layer.shadowColor = UIColor.systemBlue.cgColor
        }
        
        levelBadge.text = "\(mob.level)"
        
        // Add futuristic glow effect
        layer.shadowRadius = 8.0
        layer.shadowOpacity = 0.8
        layer.shadowOffset = .zero
        
        updateHP(current: mob.currentHP, max: mob.maxHP)
    }
    
    public func updateHP(current: Int, max: Int) {
        let ratio = max > 0 ? CGFloat(current) / CGFloat(max) : 0.0
        UIView.animate(withDuration: 0.2) {
            self.hpBar.transform = CGAffineTransform(scaleX: Swift.max(ratio, 0.001), y: 1.0)
            self.hpBar.layoutIfNeeded()
        }
    }
    
    public func showFloatingDamage(amount: Int) {
        let label = UILabel()
        label.text = "-\(amount)"
        label.textColor = .red
        label.font = UIFont.systemFont(ofSize: 22, weight: .black)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.bottomAnchor.constraint(equalTo: hpContainer.topAnchor, constant: -6)
        ])
        
        // Glow effect
        label.layer.shadowColor = UIColor.black.cgColor
        label.layer.shadowRadius = 3.0
        label.layer.shadowOpacity = 1.0
        label.layer.shadowOffset = .zero
        
        label.transform = .identity
        label.alpha = 1.0
        
        UIView.animate(withDuration: 0.8, delay: 0.0, options: .curveEaseOut, animations: {
            label.transform = CGAffineTransform(translationX: CGFloat.random(in: -12...12), y: -35)
            label.alpha = 0.0
        }) { _ in
            label.removeFromSuperview()
        }
    }
}
