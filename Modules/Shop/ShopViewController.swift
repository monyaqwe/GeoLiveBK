import UIKit

// MARK: - Expanded Shop Item Model
struct ShopItem {
    let id: String
    let icon: String
    let title: String
    let subtitle: String
    let price: String
    let accentColor: UIColor
    let tag: ShopItemTag
}

enum ShopItemTag {
    case gems, gacha, defender, economyBoost
}

// MARK: - ShopViewController
final class ShopViewController: UIViewController {

    // MARK: - UI Outlets
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
        l.text = "BLACK MARKET 🛒"
        l.font = UIFont.systemFont(ofSize: 22, weight: .black)
        l.textColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Acquire military-grade gacha cases, sentinel guards, and business boosters."
        l.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        l.textColor = UIColor.white.withAlphaComponent(0.45)
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
        s.spacing = 18
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Extended High-Tech Store Inventory
    private let casesList: [ShopItem] = [
        ShopItem(id: "case_standard", icon: "📦", title: "Standard Tactical Case", subtitle: "Guaranteed Common or Uncommon firearm", price: "$5,000", accentColor: UIColor(red: 0.25, green: 0.85, blue: 0.45, alpha: 1.0), tag: .gacha),
        ShopItem(id: "case_premium",  icon: "🎒", title: "Premium Operations Case",  subtitle: "High probability of Epic & Legendary drops", price: "15 💎",  accentColor: UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0), tag: .gacha),
    ]

    private let defendersList: [ShopItem] = [
        ShopItem(id: "def_scout",    icon: "🤖", title: "Scout Guard",       subtitle: "Mobile visual reconnaissance sentry",      price: "$3,000", accentColor: UIColor(red: 0.45, green: 0.65, blue: 1.00, alpha: 1.0), tag: .defender),
        ShopItem(id: "def_enforcer", icon: "🛡️", title: "Enforcer Sentry",   subtitle: "Fires localized shockwaves at Necro-Rats",   price: "5 💎",   accentColor: UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0), tag: .defender),
        ShopItem(id: "def_heavy",    icon: "🌋", title: "Heavy Sentinel",    subtitle: "Ultimate high-armor neighborhood defender", price: "12 💎",  accentColor: UIColor(red: 1.00, green: 0.35, blue: 0.35, alpha: 1.0), tag: .defender),
    ]

    private let boostersList: [ShopItem] = [
        ShopItem(id: "boost_chef",      icon: "👨‍🍳", title: "Recruit Professional Chef", subtitle: "Multiplies building income generation x1.5", price: "50 💎", accentColor: UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0), tag: .economyBoost),
        ShopItem(id: "boost_equipment", icon: "⚙️", title: "Install Advanced Equipment", subtitle: "Multiplies building income generation x1.8", price: "80 💎", accentColor: UIColor(red: 0.95, green: 0.40, blue: 0.70, alpha: 1.0), tag: .economyBoost),
    ]

    private let gemsList: [ShopItem] = [
        ShopItem(id: "gems_50",   icon: "💎", title: "50 Gems Pack",  subtitle: "Starter operative pack", price: "$0.99", accentColor: UIColor(red: 0.20, green: 0.80, blue: 1.00, alpha: 1.0), tag: .gems),
        ShopItem(id: "gems_200",  icon: "💎", title: "200 Gems Pack", subtitle: "Most popular choice",    price: "$2.99", accentColor: UIColor(red: 0.60, green: 0.40, blue: 1.00, alpha: 1.0), tag: .gems),
    ]

    // MARK: - Integration properties
    public var coins: Int = 0
    public var gems: Int = 0
    public var onPurchaseSuccess: ((String, Int, Int, String) -> Void)? // message, newCoins, newGems, itemId

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupView()
        setupGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh cards list on viewWillAppear to ensure correct bindings
        for view in contentStack.arrangedSubviews {
            view.removeFromSuperview()
        }
        setupSections()
        
        animateIn()
    }

    // MARK: - Setup UI
    private func setupView() {
        view.addSubview(containerView)
        containerView.addSubview(blurView)
        containerView.addSubview(dragHandle)
        containerView.addSubview(titleLabel)
        containerView.addSubview(subtitleLabel)
        containerView.addSubview(closeButton)
        containerView.addSubview(scrollView)
        scrollView.addSubview(contentStack)

        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 100),

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

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 22),
            subtitleLabel.trailingAnchor.constraint(equalTo: closeButton.leadingAnchor, constant: -12),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32),

            scrollView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            scrollView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 20),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -20),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -24),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -40),
        ])
    }

    private func setupSections() {
        // 1. Loot boxes / cases Section
        contentStack.addArrangedSubview(makeSectionHeader(title: "📦  MILITARY GACHA CASES", badge: "NEW"))
        for item in casesList {
            contentStack.addArrangedSubview(makeItemCard(item))
        }

        contentStack.addArrangedSubview(makeDivider())

        // 2. Defenders Section
        contentStack.addArrangedSubview(makeSectionHeader(title: "🛡️  SENTINEL DEFENDERS (AI GUARD)", badge: "CO-OP"))
        for item in defendersList {
            contentStack.addArrangedSubview(makeItemCard(item))
        }

        contentStack.addArrangedSubview(makeDivider())

        // 3. Economy upgrades section
        contentStack.addArrangedSubview(makeSectionHeader(title: "⚡  ECONOMY BOOSTERS (BUILDINGS)", badge: "UPGRADE"))
        for item in boostersList {
            contentStack.addArrangedSubview(makeItemCard(item))
        }

        contentStack.addArrangedSubview(makeDivider())

        // 4. Currency section
        contentStack.addArrangedSubview(makeSectionHeader(title: "💎  OPERATIVE GEMS PACKS", badge: "HOT"))
        for item in gemsList {
            contentStack.addArrangedSubview(makeItemCard(item))
        }

        let disclaimer = UILabel()
        disclaimer.text = "Operative supply transactions are verified on Firebase securely."
        disclaimer.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        disclaimer.textColor = UIColor.white.withAlphaComponent(0.20)
        disclaimer.textAlignment = .center
        disclaimer.numberOfLines = 0
        contentStack.addArrangedSubview(disclaimer)
    }

    // MARK: - Builders
    private func makeSectionHeader(title: String, badge: String?) -> UIView {
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
            container.heightAnchor.constraint(equalToConstant: 28),
        ])

        if let badge = badge {
            let badgeView = UILabel()
            badgeView.text = badge
            badgeView.font = UIFont.systemFont(ofSize: 8, weight: .black)
            badgeView.textColor = UIColor(white: 0.08, alpha: 1.0)
            badgeView.backgroundColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
            badgeView.layer.cornerRadius = 6
            badgeView.clipsToBounds = true
            badgeView.textAlignment = .center
            badgeView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(badgeView)

            NSLayoutConstraint.activate([
                badgeView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
                badgeView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
                badgeView.widthAnchor.constraint(equalToConstant: 48),
                badgeView.heightAnchor.constraint(equalToConstant: 16),
            ])
        }

        return container
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func makeItemCard(_ item: ShopItem) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.03)
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1.0
        card.layer.borderColor = item.accentColor.withAlphaComponent(0.20).cgColor
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let stripe = UIView()
        stripe.backgroundColor = item.accentColor
        stripe.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stripe)

        let iconLabel = UILabel()
        iconLabel.text = item.icon
        iconLabel.font = .systemFont(ofSize: 26)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconLabel)

        let titleL = UILabel()
        titleL.text = item.title
        titleL.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        titleL.textColor = .white
        titleL.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleL)

        let subL = UILabel()
        subL.text = item.subtitle
        subL.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        subL.textColor = UIColor.white.withAlphaComponent(0.40)
        subL.numberOfLines = 2
        subL.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subL)

        let priceBtn = UIButton(type: .custom)
        priceBtn.setTitle(item.price.uppercased(), for: .normal)
        priceBtn.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .black)
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
            config.baseBackgroundColor = item.accentColor
            config.baseForegroundColor = UIColor(white: 0.08, alpha: 1.0)
            priceBtn.configuration = config
        } else {
            priceBtn.setTitleColor(UIColor(white: 0.08, alpha: 1.0), for: .normal)
            priceBtn.backgroundColor = item.accentColor
            priceBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        }
        priceBtn.layer.cornerRadius = 14
        priceBtn.translatesAutoresizingMaskIntoConstraints = false
        priceBtn.addTarget(self, action: #selector(purchaseTapped(_:)), for: .touchUpInside)
        card.addSubview(priceBtn)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 72),

            stripe.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stripe.topAnchor.constraint(equalTo: card.topAnchor),
            stripe.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            stripe.widthAnchor.constraint(equalToConstant: 4),

            iconLabel.leadingAnchor.constraint(equalTo: stripe.trailingAnchor, constant: 14),
            iconLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            titleL.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 12),
            titleL.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            titleL.trailingAnchor.constraint(lessThanOrEqualTo: priceBtn.leadingAnchor, constant: -8),

            subL.leadingAnchor.constraint(equalTo: titleL.leadingAnchor),
            subL.topAnchor.constraint(equalTo: titleL.bottomAnchor, constant: 2),
            subL.trailingAnchor.constraint(lessThanOrEqualTo: priceBtn.leadingAnchor, constant: -8),

            priceBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            priceBtn.centerYAnchor.constraint(equalTo: card.centerYAnchor),
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(cardTapped(_:)))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        card.accessibilityIdentifier = item.id

        return card
    }

    // MARK: - Gestures
    private func setupGestures() {
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(closeTapped))
        swipeDown.direction = .down
        containerView.addGestureRecognizer(swipeDown)

        let bgTap = UITapGestureRecognizer(target: self, action: #selector(bgTapped(_:)))
        view.addGestureRecognizer(bgTap)
    }

    // MARK: - Animations
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

    // MARK: - Actions
    @objc private func closeTapped() {
        animateOut { [weak self] in self?.dismiss(animated: false) }
    }

    @objc private func bgTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: view)
        if !containerView.frame.contains(location) { closeTapped() }
    }

    @objc private func cardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view else { return }
        UIView.animate(withDuration: 0.10) {
            card.transform = CGAffineTransform(scaleX: 0.96, y: 0.96)
        } completion: { _ in
            UIView.animate(withDuration: 0.12) { card.transform = .identity }
        }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    @objc private func purchaseTapped(_ sender: UIButton) {
        guard let card = sender.superview else { return }
        let itemId = card.accessibilityIdentifier ?? ""
        
        let allItems = casesList + defendersList + boostersList + gemsList
        guard let item = allItems.first(where: { $0.id == itemId }) else { return }
        
        // Parse cost from item.price
        let isGemCost = item.price.contains("Gems") || item.price.contains("💎")
        var cost = 0
        
        // Extract numbers from price string
        let numbers = item.price.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()
        if let val = Int(numbers) {
            cost = val
        } else if item.price.contains("0.99") {
            cost = 1 // Mock 1 Gem / 1 Dollar
        } else if item.price.contains("2.99") {
            cost = 3
        }
        
        if isGemCost {
            if gems < cost {
                let alert = UIAlertController(title: "INSUFFICIENT GEMS", message: "You need \(cost) Gems to buy this item!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                return
            }
            gems -= cost
        } else {
            // Cash Cost
            if coins < cost {
                let alert = UIAlertController(title: "INSUFFICIENT CASH", message: "You need $\(cost) to buy this item!", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                present(alert, animated: true)
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
                return
            }
            coins -= cost
        }
        
        UIView.animate(withDuration: 0.08) {
            sender.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
        } completion: { _ in
            UIView.animate(withDuration: 0.12) { sender.transform = .identity }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let alert = UIAlertController(
            title: "SUPPLIES CONFIRMED",
            message: "Successfully purchased \(item.title) for \(item.price)!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.onPurchaseSuccess?("PURCHASED: \(item.title)!", self.coins, self.gems, item.id)
            self.closeTapped()
        })
        present(alert, animated: true)
    }
}
