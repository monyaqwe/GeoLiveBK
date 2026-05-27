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
        setupStatsAndInventory()
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
        
        statsStack.addArrangedSubview(makeStatRow(icon: "🔮", name: "LEVEL", value: "\(level)"))
        statsStack.addArrangedSubview(makeStatRow(icon: "❤️", name: "HEALTH", value: "\(hp) / \(maxHP)"))
        statsStack.addArrangedSubview(makeStatRow(icon: "⚡", name: "XP MATRIX", value: "\(xp) / \(maxXP)"))
        statsStack.addArrangedSubview(makeStatRow(icon: "💥", name: "FIREPOWER", value: "\(baseDamage) DMG"))
        statsStack.addArrangedSubview(makeStatRow(icon: "💰", name: "LIQUID CASH", value: "$\(coins)"))
        statsStack.addArrangedSubview(makeStatRow(icon: "💎", name: "PREMIUM GEMS", value: "\(gems)"))
        
        // 3. Inventory Section Header
        contentStack.addArrangedSubview(makeSectionHeader(title: "🎒  ACTIVE BACKPACK / EQUIPMENT"))
        
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
                if let weapon = item as? WeaponDTO {
                    emoji = weapon.type == .pistol ? "🔫" : (weapon.type == .smg ? "🎒" : "⚙️")
                    sub = "\(weapon.tier.name) Tier - \(weapon.damage) DMG"
                } else if let mod = item as? ModDTO {
                    emoji = "🔌"
                    sub = "\(mod.statAffected) Boost +\(Int(mod.multiplierBoost * 10))%"
                } else {
                    emoji = "📦"
                    sub = item.description
                }
                
                let itemCard = UIView()
                itemCard.backgroundColor = UIColor.white.withAlphaComponent(0.03)
                itemCard.layer.cornerRadius = 14
                itemCard.layer.borderWidth = 1.0
                itemCard.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
                itemCard.translatesAutoresizingMaskIntoConstraints = false
                
                let emojiL = UILabel()
                emojiL.text = emoji
                emojiL.font = .systemFont(ofSize: 24)
                emojiL.translatesAutoresizingMaskIntoConstraints = false
                itemCard.addSubview(emojiL)
                
                let titleL = UILabel()
                titleL.text = item.name
                titleL.font = .systemFont(ofSize: 13, weight: .bold)
                titleL.textColor = .white
                titleL.translatesAutoresizingMaskIntoConstraints = false
                itemCard.addSubview(titleL)
                
                let subL = UILabel()
                subL.text = sub
                subL.font = .systemFont(ofSize: 10, weight: .semibold)
                subL.textColor = UIColor.white.withAlphaComponent(0.40)
                subL.translatesAutoresizingMaskIntoConstraints = false
                itemCard.addSubview(subL)
                
                contentStack.addArrangedSubview(itemCard)
                
                NSLayoutConstraint.activate([
                    itemCard.heightAnchor.constraint(equalToConstant: 60),
                    emojiL.leadingAnchor.constraint(equalTo: itemCard.leadingAnchor, constant: 14),
                    emojiL.centerYAnchor.constraint(equalTo: itemCard.centerYAnchor),
                    
                    titleL.leadingAnchor.constraint(equalTo: emojiL.trailingAnchor, constant: 12),
                    titleL.topAnchor.constraint(equalTo: itemCard.topAnchor, constant: 12),
                    
                    subL.leadingAnchor.constraint(equalTo: titleL.leadingAnchor),
                    subL.topAnchor.constraint(equalTo: titleL.bottomAnchor, constant: 2)
                ])
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
}
