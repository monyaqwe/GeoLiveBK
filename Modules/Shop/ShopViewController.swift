import UIKit

// MARK: - Shop Item Model
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
    case gems, coins, boost, premium
}

// MARK: - ShopViewController
final class ShopViewController: UIViewController {

    // MARK: - UI
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
        v.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "SHOP 🛒"
        l.font = UIFont.systemFont(ofSize: 22, weight: .black)
        l.textColor = .white
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()

    private let subtitleLabel: UILabel = {
        let l = UILabel()
        l.text = "Buy gems, coins and power-ups"
        l.font = UIFont.systemFont(ofSize: 12, weight: .medium)
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
        s.spacing = 20
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()

    // MARK: - Data
    private let gemPacks: [ShopItem] = [
        ShopItem(id: "gems_50",   icon: "💎", title: "50 Gems",    subtitle: "Starter Pack",       price: "$0.99",  accentColor: UIColor(red: 0.20, green: 0.80, blue: 1.00, alpha: 1.0), tag: .gems),
        ShopItem(id: "gems_200",  icon: "💎", title: "200 Gems",   subtitle: "Most Popular",        price: "$2.99",  accentColor: UIColor(red: 0.45, green: 0.65, blue: 1.00, alpha: 1.0), tag: .gems),
        ShopItem(id: "gems_600",  icon: "💎", title: "600 Gems",   subtitle: "Best Value +20%",     price: "$6.99",  accentColor: UIColor(red: 0.60, green: 0.40, blue: 1.00, alpha: 1.0), tag: .gems),
        ShopItem(id: "gems_1500", icon: "💎", title: "1,500 Gems", subtitle: "VIP Bundle +35%",     price: "$14.99", accentColor: UIColor(red: 0.95, green: 0.40, blue: 0.70, alpha: 1.0), tag: .premium),
    ]

    private let boostPacks: [ShopItem] = [
        ShopItem(id: "boost_income", icon: "⚡️", title: "2× Income Boost",   subtitle: "Active for 24 hours",    price: "50 💎",  accentColor: UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0), tag: .boost),
        ShopItem(id: "boost_shield", icon: "🛡️", title: "Territory Shield",  subtitle: "Protected for 12 hours", price: "30 💎",  accentColor: UIColor(red: 0.25, green: 0.85, blue: 0.55, alpha: 1.0), tag: .boost),
        ShopItem(id: "boost_xp",     icon: "🚀", title: "Double XP",         subtitle: "Active for 6 hours",     price: "20 💎",  accentColor: UIColor(red: 1.00, green: 0.50, blue: 0.25, alpha: 1.0), tag: .boost),
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupView()
        setupSections()
        setupGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        animateIn()
    }

    // MARK: - Setup
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
            containerView.topAnchor.constraint(equalTo: view.topAnchor, constant: 80),

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

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 3),
            subtitleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 22),

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
        contentStack.addArrangedSubview(makeSectionHeader(title: "💎  GEM PACKS", badge: "HOT"))
        for item in gemPacks {
            contentStack.addArrangedSubview(makeItemCard(item))
        }

        contentStack.addArrangedSubview(makeDivider())

        contentStack.addArrangedSubview(makeSectionHeader(title: "⚡️  POWER-UPS", badge: nil))
        for item in boostPacks {
            contentStack.addArrangedSubview(makeItemCard(item))
        }

        let legalLabel = UILabel()
        legalLabel.text = "In-app purchases are final. Prices include applicable local taxes."
        legalLabel.font = UIFont.systemFont(ofSize: 10, weight: .regular)
        legalLabel.textColor = UIColor.white.withAlphaComponent(0.25)
        legalLabel.numberOfLines = 0
        legalLabel.textAlignment = .center
        contentStack.addArrangedSubview(legalLabel)
    }

    // MARK: - Builders
    private func makeSectionHeader(title: String, badge: String?) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = title
        label.font = UIFont.systemFont(ofSize: 13, weight: .black)
        label.textColor = UIColor.white.withAlphaComponent(0.55)
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
            badgeView.font = UIFont.systemFont(ofSize: 9, weight: .black)
            badgeView.textColor = UIColor(white: 0.08, alpha: 1.0)
            badgeView.backgroundColor = UIColor(red: 1.0, green: 0.60, blue: 0.10, alpha: 1.0)
            badgeView.layer.cornerRadius = 7
            badgeView.clipsToBounds = true
            badgeView.textAlignment = .center
            badgeView.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(badgeView)

            NSLayoutConstraint.activate([
                badgeView.leadingAnchor.constraint(equalTo: label.trailingAnchor, constant: 8),
                badgeView.centerYAnchor.constraint(equalTo: label.centerYAnchor),
                badgeView.widthAnchor.constraint(equalToConstant: 36),
                badgeView.heightAnchor.constraint(equalToConstant: 18),
            ])
        }

        return container
    }

    private func makeDivider() -> UIView {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.07)
        v.translatesAutoresizingMaskIntoConstraints = false
        v.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return v
    }

    private func makeItemCard(_ item: ShopItem) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1.0
        card.layer.borderColor = item.accentColor.withAlphaComponent(0.25).cgColor
        card.clipsToBounds = true
        card.translatesAutoresizingMaskIntoConstraints = false

        let stripe = UIView()
        stripe.backgroundColor = item.accentColor
        stripe.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(stripe)

        let iconLabel = UILabel()
        iconLabel.text = item.icon
        iconLabel.font = .systemFont(ofSize: 28)
        iconLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(iconLabel)

        let titleL = UILabel()
        titleL.text = item.title
        titleL.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        titleL.textColor = .white
        titleL.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(titleL)

        let subL = UILabel()
        subL.text = item.subtitle
        subL.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        subL.textColor = UIColor.white.withAlphaComponent(0.45)
        subL.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(subL)

        let priceBtn = UIButton(type: .custom)
        priceBtn.setTitle(item.price, for: .normal)
        priceBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .black)
        priceBtn.setTitleColor(UIColor(white: 0.08, alpha: 1.0), for: .normal)
        priceBtn.backgroundColor = item.accentColor
        priceBtn.layer.cornerRadius = 14
        priceBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
        priceBtn.translatesAutoresizingMaskIntoConstraints = false
        priceBtn.addTarget(self, action: #selector(purchaseTapped(_:)), for: .touchUpInside)
        card.addSubview(priceBtn)

        NSLayoutConstraint.activate([
            card.heightAnchor.constraint(equalToConstant: 72),

            stripe.leadingAnchor.constraint(equalTo: card.leadingAnchor),
            stripe.topAnchor.constraint(equalTo: card.topAnchor),
            stripe.bottomAnchor.constraint(equalTo: card.bottomAnchor),
            stripe.widthAnchor.constraint(equalToConstant: 4),

            iconLabel.leadingAnchor.constraint(equalTo: stripe.trailingAnchor, constant: 16),
            iconLabel.centerYAnchor.constraint(equalTo: card.centerYAnchor),

            titleL.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 14),
            titleL.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),

            subL.leadingAnchor.constraint(equalTo: titleL.leadingAnchor),
            subL.topAnchor.constraint(equalTo: titleL.bottomAnchor, constant: 3),

            priceBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
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
        UIView.animate(withDuration: 0.08) {
            sender.transform = CGAffineTransform(scaleX: 0.90, y: 0.90)
        } completion: { _ in
            UIView.animate(withDuration: 0.12) { sender.transform = .identity }
        }
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()

        let alert = UIAlertController(
            title: "Purchase Unavailable",
            message: "In-app purchases will be available in the next version of GeoLive.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        present(alert, animated: true)
    }
}
