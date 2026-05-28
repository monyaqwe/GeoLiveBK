import UIKit

public final class StatsInventoryViewController: UIViewController {
    
    public var coins: Int = 0
    public var gems: Int = 0
    public var level: Int = 1
    public var xp: Int = 0
    public var maxXP: Int = 1000
    public var hp: Int = 100
    public var maxHP: Int = 100
    public var baseDamage: Int = 30
    
    private let containerView: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(white: 0.08, alpha: 0.98)
        v.layer.cornerRadius = 28
        v.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        v.clipsToBounds = true
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let blurView: UIVisualEffectView = {
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        return blur
    }()
    
    private let dragHandle: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.40)
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "OPERATIVE PROTOCOL 🧬"
        l.font = UIFont.systemFont(ofSize: 22, weight: .black)
        l.textColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private let closeButton: UIButton = {
        let btn = UIButton(type: .system)
        let cfg = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        btn.setImage(UIImage(systemName: "xmark.circle.fill", withConfiguration: cfg), for: .normal)
        btn.tintColor = UIColor.white.withAlphaComponent(0.35)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let contentStack: UIStackView = {
        let s = UIStackView()
        s.axis = .vertical
        s.spacing = 20
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupView()
        refreshUI()
        setupGestures()
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }
    
    private func setupView() {
        view.addSubview(containerView)
        containerView.addSubview(blurView)
        containerView.addSubview(dragHandle)
        containerView.addSubview(titleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(scrollView)
        scrollView.addSubview(contentStack)
        
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        
        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 120),
            
            blurView.topAnchor.constraint(equalTo: containerView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
            
            dragHandle.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 10),
            dragHandle.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 40),
            dragHandle.heightAnchor.constraint(equalToConstant: 5),
            
            titleLabel.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 18),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 22),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),
            
            scrollView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40)
        ])
    }
    
    private func refreshUI() {
        if let equipped = InventoryManager.shared.getEquippedWeapon() {
            baseDamage = equipped.damage
        } else {
            baseDamage = 30
        }
        
        for subview in contentStack.arrangedSubviews {
            subview.removeFromSuperview()
        }
        setupStatsAndInventory()
    }
    
    private func setupStatsAndInventory() {
        // 1. Stats Section Header
        contentStack.addArrangedSubview(makeSectionHeader(title: "⚙️  OPERATIVE ATTRIBUTES"))
        
        // 2. Stats Cards
        let statsView = UIView()
        statsView.backgroundColor = UIColor.white.withAlphaComponent(0.02)
        statsView.layer.cornerRadius = 16
        statsView.layer.borderWidth = 1.0
        statsView.layer.borderColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.15).cgColor
        statsView.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(statsView)
        
        let statsStack = UIStackView()
        statsStack.axis = .vertical
        statsStack.spacing = 12
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        statsView.addSubview(statsStack)
        
        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: statsView.topAnchor, constant: 16),
            statsStack.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 16),
            statsStack.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -16),
            statsStack.bottomAnchor.constraint(equalTo: statsView.bottomAnchor, constant: -16)
        ])
        
        // Top general stats bar: Level, XP, Cash, Gems
        let metaStack = UIStackView()
        metaStack.axis = .horizontal
        metaStack.spacing = 8
        metaStack.distribution = .fillEqually
        metaStack.translatesAutoresizingMaskIntoConstraints = false
        
        func makeMetaLabel(title: String, val: String) -> UIView {
            let container = UIView()
            container.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            container.layer.cornerRadius = 8
            container.translatesAutoresizingMaskIntoConstraints = false
            
            let nameL = UILabel()
            nameL.text = title
            nameL.textColor = .white.withAlphaComponent(0.4)
            nameL.font = .systemFont(ofSize: 8, weight: .bold)
            nameL.textAlignment = .center
            nameL.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(nameL)
            
            let valL = UILabel()
            valL.text = val
            valL.textColor = .white
            valL.font = .systemFont(ofSize: 10, weight: .black)
            valL.textAlignment = .center
            valL.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(valL)
            
            NSLayoutConstraint.activate([
                nameL.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
                nameL.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                valL.topAnchor.constraint(equalTo: nameL.bottomAnchor, constant: 2),
                valL.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                valL.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
            ])
            return container
        }
        
        metaStack.addArrangedSubview(makeMetaLabel(title: "LEVEL", val: "\(level)"))
        metaStack.addArrangedSubview(makeMetaLabel(title: "XP MATRIX", val: "\(xp)/\(maxXP)"))
        metaStack.addArrangedSubview(makeMetaLabel(title: "CASH", val: "$\(coins)"))
        metaStack.addArrangedSubview(makeMetaLabel(title: "GEMS", val: "\(gems)"))
        
        statsStack.addArrangedSubview(metaStack)
        
        // Custom HP & Recovery Circle Widgets + 2 progress lines
        func makeProgressCircle(title: String, val: String, progress: CGFloat, color: UIColor) -> UIView {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            container.layer.cornerRadius = 36
            
            let trackLayer = CAShapeLayer()
            trackLayer.fillColor = UIColor.clear.cgColor
            trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.1).cgColor
            trackLayer.lineWidth = 3
            
            let progressLayer = CAShapeLayer()
            progressLayer.fillColor = UIColor.clear.cgColor
            progressLayer.strokeColor = color.cgColor
            progressLayer.lineWidth = 3
            progressLayer.strokeEnd = progress
            progressLayer.lineCap = .round
            
            let center = CGPoint(x: 36, y: 36)
            let path = UIBezierPath(arcCenter: center, radius: 34.5, startAngle: -CGFloat.pi/2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
            trackLayer.path = path.cgPath
            progressLayer.path = path.cgPath
            
            container.layer.addSublayer(trackLayer)
            container.layer.addSublayer(progressLayer)
            
            let titleL = UILabel()
            titleL.text = title
            titleL.textColor = .white.withAlphaComponent(0.6)
            titleL.font = .systemFont(ofSize: 8, weight: .bold)
            titleL.textAlignment = .center
            titleL.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(titleL)
            
            let valL = UILabel()
            valL.text = val
            valL.textColor = .white
            valL.font = .systemFont(ofSize: 11, weight: .black)
            valL.textAlignment = .center
            valL.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(valL)
            
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 72),
                container.heightAnchor.constraint(equalToConstant: 72),
                titleL.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                titleL.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -10),
                valL.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                valL.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 8)
            ])
            return container
        }
        
        let hpPct = CGFloat(hp) / CGFloat(max(1, maxHP))
        let hpCircle = makeProgressCircle(title: "LIFE", val: "\(hp)", progress: hpPct, color: .systemGreen)
        let regenCircle = makeProgressCircle(title: "REGEN", val: "+2/s", progress: 1.0, color: .systemGreen)
        
        let barsStack = UIStackView()
        barsStack.axis = .vertical
        barsStack.spacing = 8
        barsStack.distribution = .fillEqually
        barsStack.translatesAutoresizingMaskIntoConstraints = false
        
        func makeStatProgressBar(name: String, valueText: String, progress: Float) -> UIView {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            
            let label = UILabel()
            label.text = "\(name): \(valueText)"
            label.textColor = .white
            label.font = .systemFont(ofSize: 9, weight: .bold)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            
            let bgTrack = UIView()
            bgTrack.backgroundColor = UIColor.white.withAlphaComponent(0.10)
            bgTrack.layer.cornerRadius = 3
            bgTrack.clipsToBounds = true
            bgTrack.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(bgTrack)
            
            let fill = UIView()
            fill.backgroundColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0)
            fill.layer.cornerRadius = 3
            fill.translatesAutoresizingMaskIntoConstraints = false
            bgTrack.addSubview(fill)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: container.topAnchor),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                
                bgTrack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
                bgTrack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                bgTrack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                bgTrack.heightAnchor.constraint(equalToConstant: 6),
                bgTrack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                
                fill.topAnchor.constraint(equalTo: bgTrack.topAnchor),
                fill.bottomAnchor.constraint(equalTo: bgTrack.bottomAnchor),
                fill.leadingAnchor.constraint(equalTo: bgTrack.leadingAnchor),
                fill.widthAnchor.constraint(equalTo: bgTrack.widthAnchor, multiplier: CGFloat(max(0.05, min(1.0, progress))))
            ])
            return container
        }
        
        let activeWeaponRate = Double(InventoryManager.shared.getEquippedWeapon()?.fireRate ?? 2.0)
        barsStack.addArrangedSubview(makeStatProgressBar(name: "DAMAGE", valueText: "\(baseDamage)", progress: Float(baseDamage) / 100.0))
        barsStack.addArrangedSubview(makeStatProgressBar(name: "SPEED", valueText: "\(activeWeaponRate)/s", progress: Float(activeWeaponRate) / 10.0))
        
        let statsRowContainer = UIStackView(arrangedSubviews: [hpCircle, regenCircle, barsStack])
        statsRowContainer.axis = .horizontal
        statsRowContainer.spacing = 14
        statsRowContainer.alignment = .center
        statsRowContainer.distribution = .fill
        statsRowContainer.translatesAutoresizingMaskIntoConstraints = false
        statsStack.addArrangedSubview(statsRowContainer)
        
        // 3. Inventory Section Header
        contentStack.addArrangedSubview(makeSectionHeader(title: "🎒  ACTIVE BACKPACK / EQUIPMENT (TAP WEAPON TO EQUIP)"))
        
        // 4. Inventory Grid/List
        let realItems = InventoryManager.shared.items
        if realItems.isEmpty {
            let emptyCard = UIView()
            emptyCard.backgroundColor = UIColor.white.withAlphaComponent(0.01)
            emptyCard.layer.cornerRadius = 14
            emptyCard.layer.borderWidth = 1.0
            emptyCard.layer.borderColor = UIColor.white.withAlphaComponent(0.04).cgColor
            emptyCard.translatesAutoresizingMaskIntoConstraints = false
            
            let emptyL = UILabel()
            emptyL.text = "BACKPACK EMPTY // PURCHASE GEAR IN SHOP"
            emptyL.font = UIFont.systemFont(ofSize: 10, weight: .bold)
            emptyL.textColor = UIColor.white.withAlphaComponent(0.25)
            emptyL.textAlignment = .center
            emptyL.translatesAutoresizingMaskIntoConstraints = false
            emptyCard.addSubview(emptyL)
            contentStack.addArrangedSubview(emptyCard)
            
            NSLayoutConstraint.activate([
                emptyCard.heightAnchor.constraint(equalToConstant: 50),
                emptyL.centerXAnchor.constraint(equalTo: emptyCard.centerXAnchor),
                emptyL.centerYAnchor.constraint(equalTo: emptyCard.centerYAnchor)
            ])
        } else {
            for item in realItems {
                let emoji: String
                let sub: String
                var isEquipped = false
                
                if let weapon = item as? WeaponDTO {
                    emoji = weapon.type == .pistol ? "🔫" : (weapon.type == .smg ? "🎒" : "⚙️")
                    isEquipped = InventoryManager.shared.equippedWeaponId == weapon.id
                    sub = isEquipped
                        ? "\(weapon.tier.name) Tier - \(weapon.damage) DMG [ACTIVE GEAR ⚡]"
                        : "\(weapon.tier.name) Tier - \(weapon.damage) DMG"
                } else if let mod = item as? ModDTO {
                    emoji = "🔌"
                    sub = "\(mod.statAffected) Boost +\(Int(mod.multiplierBoost * 10))%"
                } else {
                    emoji = "📦"
                    sub = item.description
                }
                
                let itemCard = UIView()
                itemCard.backgroundColor = isEquipped
                    ? UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.06)
                    : UIColor.white.withAlphaComponent(0.03)
                itemCard.layer.cornerRadius = 14
                itemCard.layer.borderWidth = 1.0
                itemCard.layer.borderColor = isEquipped
                    ? UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.50).cgColor
                    : UIColor.white.withAlphaComponent(0.08).cgColor
                itemCard.translatesAutoresizingMaskIntoConstraints = false
                
                let emojiL = UILabel()
                emojiL.text = emoji
                emojiL.font = .systemFont(ofSize: 24)
                emojiL.translatesAutoresizingMaskIntoConstraints = false
                itemCard.addSubview(emojiL)
                
                let titleL = UILabel()
                titleL.text = item.name
                titleL.font = .systemFont(ofSize: 13, weight: .bold)
                titleL.textColor = isEquipped ? UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0) : .white
                titleL.translatesAutoresizingMaskIntoConstraints = false
                itemCard.addSubview(titleL)
                
                let subL = UILabel()
                subL.text = sub
                subL.font = .systemFont(ofSize: 10, weight: .semibold)
                subL.textColor = isEquipped
                    ? UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.70)
                    : UIColor.white.withAlphaComponent(0.40)
                subL.translatesAutoresizingMaskIntoConstraints = false
                itemCard.addSubview(subL)
                
                var equipSwitch: UISwitch?
                if let weapon = item as? WeaponDTO {
                    let sw = UISwitch()
                    sw.isOn = isEquipped
                    sw.onTintColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
                    sw.translatesAutoresizingMaskIntoConstraints = false
                    sw.addTarget(self, action: #selector(weaponSwitchToggled(_:)), for: .valueChanged)
                    sw.accessibilityIdentifier = weapon.id.uuidString
                    itemCard.addSubview(sw)
                    equipSwitch = sw
                }
                
                contentStack.addArrangedSubview(itemCard)
                
                NSLayoutConstraint.activate([
                    itemCard.heightAnchor.constraint(equalToConstant: 60),
                    emojiL.leadingAnchor.constraint(equalTo: itemCard.leadingAnchor, constant: 14),
                    emojiL.centerYAnchor.constraint(equalTo: itemCard.centerYAnchor),
                    
                    titleL.leadingAnchor.constraint(equalTo: emojiL.trailingAnchor, constant: 12),
                    titleL.trailingAnchor.constraint(equalTo: itemCard.trailingAnchor, constant: -80),
                    titleL.topAnchor.constraint(equalTo: itemCard.topAnchor, constant: 12),
                    
                    subL.leadingAnchor.constraint(equalTo: titleL.leadingAnchor),
                    subL.trailingAnchor.constraint(equalTo: itemCard.trailingAnchor, constant: -80),
                    subL.topAnchor.constraint(equalTo: titleL.bottomAnchor, constant: 2)
                ])
                
                if let sw = equipSwitch {
                    NSLayoutConstraint.activate([
                        sw.trailingAnchor.constraint(equalTo: itemCard.trailingAnchor, constant: -14),
                        sw.centerYAnchor.constraint(equalTo: itemCard.centerYAnchor)
                    ])
                }
            }
        }
    }
    
    private func makeSectionHeader(title: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 12, weight: .black)
        label.textColor = UIColor.white.withAlphaComponent(0.60)
        label.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            container.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        return container
    }
    
    private func makeStatRow(icon: String, name: String, value: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let iconL = UILabel()
        iconL.text = icon
        iconL.font = .systemFont(ofSize: 14)
        iconL.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(iconL)
        
        let nameL = UILabel()
        nameL.text = name
        nameL.font = .systemFont(ofSize: 12, weight: .bold)
        nameL.textColor = UIColor.white.withAlphaComponent(0.50)
        nameL.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(nameL)
        
        let valueL = UILabel()
        valueL.text = value
        valueL.font = .systemFont(ofSize: 13, weight: .black)
        valueL.textColor = .white
        valueL.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(valueL)
        
        NSLayoutConstraint.activate([
            container.heightAnchor.constraint(equalToConstant: 24),
            iconL.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconL.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            nameL.leadingAnchor.constraint(equalTo: iconL.trailingAnchor, constant: 8),
            nameL.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            
            valueL.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            valueL.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    private func setupGestures() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(closeTapped))
        swipeDown.direction = .down
        containerView.addGestureRecognizer(swipeDown)
        
        let bgTap = UITapGestureRecognizer(target: self, action: #selector(bgTapped(_:)))
        view.addGestureRecognizer(bgTap)
    }
    
    private func animateIn() {
        containerView.transform = CGAffineTransform(translationX: 0, y: view.bounds.height)
        view.backgroundColor = .clear
        UIView.animate(withDuration: 0.42, delay: 0, usingSpringWithDamping: 0.82,
                       initialSpringVelocity: 0.6, options: .curveEaseOut) {
            self.containerView.transform = .identity
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.55)
        }
    }
    
    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.30, delay: 0, options: .curveEaseIn) {
            self.containerView.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
            self.view.backgroundColor = .clear
        } completion: { _ in completion?() }
    }
    
    @objc private func closeTapped() {
        animateOut { [weak self] in self?.dismiss(animated: false) }
    }
    
    @objc private func bgTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) { closeTapped() }
    }
    
    @objc private func weaponSwitchToggled(_ sender: UISwitch) {
        guard let wIdStr = sender.accessibilityIdentifier, let wId = UUID(uuidString: wIdStr) else { return }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if sender.isOn {
            InventoryManager.shared.equipWeapon(id: wId)
        } else {
            InventoryManager.shared.equipWeapon(id: nil)
        }
        
        refreshUI()
    }
}

// Custom Gesture Recognizer subclass to track weapon selection ID
public final class WeaponTapGestureRecognizer: UITapGestureRecognizer {
    public var weaponId: UUID?
}
