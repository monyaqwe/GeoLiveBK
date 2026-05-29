import UIKit

public final class LevelRewardsViewController: UIViewController {
    
    public var currentLevel: Int = 1
    public var coins: Int = 0
    public var gems: Int = 0
    
    public var onRewardClaimed: ((Int, String, Int, Int) -> Void)? // level, message, coinsAwarded, gemsAwarded
    
    private var claimedLevels: Set<Int> = []
    
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
        v.backgroundColor = UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 0.40)
        v.layer.cornerRadius = 2.5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.text = "PROGRESSION REWARDS 🏆"
        l.font = UIFont.systemFont(ofSize: 22, weight: .black)
        l.textColor = UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0)
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
        s.spacing = 16
        s.translatesAutoresizingMaskIntoConstraints = false
        return s
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        // Restore claimed rewards state from UserDefaults
        if let savedClaims = UserDefaults.standard.array(forKey: "GeoLive_ClaimedRewards") as? [Int] {
            claimedLevels = Set(savedClaims)
        }
        
        setupView()
        setupRewardsList()
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
    
    private struct RewardMilestone {
        let level: Int
        let rewardTitle: String
        let rewardDetail: String
        let cashBonus: Int
        let gemBonus: Int
    }
    
    private let milestones = [
        RewardMilestone(level: 1, rewardTitle: "Recruit Packet", rewardDetail: "Starter operation box", cashBonus: 1000, gemBonus: 2),
        RewardMilestone(level: 2, rewardTitle: "Plasma Ammo Pack", rewardDetail: "Extra ammo supplies", cashBonus: 2500, gemBonus: 5),
        RewardMilestone(level: 3, rewardTitle: "Advanced Radar Core", rewardDetail: "Visual range booster module", cashBonus: 5000, gemBonus: 10),
        RewardMilestone(level: 4, rewardTitle: "Enforcer Sentry Core", rewardDetail: "Sentinel base blueprint", cashBonus: 10000, gemBonus: 15),
        RewardMilestone(level: 5, rewardTitle: "Commander's Drop", rewardDetail: "Legendary operations gacha pack", cashBonus: 25000, gemBonus: 30)
    ]
    
    private func setupRewardsList() {
        for m in milestones {
            let card = UIView()
            card.backgroundColor = UIColor.white.withAlphaComponent(0.03)
            card.layer.cornerRadius = 16
            card.layer.borderWidth = 1.0
            
            let isUnlocked = currentLevel >= m.level
            let isClaimed = claimedLevels.contains(m.level)
            
            let accentColor: UIColor
            if isClaimed {
                accentColor = UIColor.white.withAlphaComponent(0.20)
                card.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
            } else if isUnlocked {
                accentColor = UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0)
                card.layer.borderColor = accentColor.withAlphaComponent(0.40).cgColor
            } else {
                accentColor = UIColor.white.withAlphaComponent(0.12)
                card.layer.borderColor = UIColor.white.withAlphaComponent(0.05).cgColor
            }
            
            let badge = UILabel()
            badge.text = "Lvl \(m.level)"
            badge.font = .systemFont(ofSize: 10, weight: .black)
            badge.textColor = .black
            badge.backgroundColor = accentColor
            badge.layer.cornerRadius = 6
            badge.clipsToBounds = true
            badge.textAlignment = .center
            badge.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(badge)
            
            let titleL = UILabel()
            titleL.text = m.rewardTitle.uppercased()
            titleL.font = .systemFont(ofSize: 12, weight: .bold)
            titleL.textColor = isUnlocked ? .white : .white.withAlphaComponent(0.35)
            titleL.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(titleL)
            
            let descL = UILabel()
            descL.text = "\(m.rewardDetail) (Bonus: $\(m.cashBonus) & \(m.gemBonus) Gems)"
            descL.font = .systemFont(ofSize: 9, weight: .bold)
            descL.textColor = isUnlocked ? UIColor.white.withAlphaComponent(0.45) : .white.withAlphaComponent(0.20)
            descL.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(descL)
            
            let actionBtn = UIButton(type: .custom)
            actionBtn.titleLabel?.font = .systemFont(ofSize: 9, weight: .black)
            actionBtn.layer.cornerRadius = 12
            actionBtn.translatesAutoresizingMaskIntoConstraints = false
            card.addSubview(actionBtn)
            
            if isClaimed {
                actionBtn.setTitle("CLAIMED ✓", for: .normal)
                actionBtn.setTitleColor(.white.withAlphaComponent(0.25), for: .normal)
                actionBtn.backgroundColor = .clear
                actionBtn.layer.borderWidth = 1.0
                actionBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
                actionBtn.isEnabled = false
            } else if isUnlocked {
                actionBtn.setTitle("CLAIM REWARD", for: .normal)
                actionBtn.setTitleColor(.black, for: .normal)
                actionBtn.backgroundColor = accentColor
                actionBtn.isEnabled = true
                actionBtn.addTarget(self, action: #selector(claimTapped(_:)), for: .touchUpInside)
                actionBtn.accessibilityIdentifier = "\(m.level)"
            } else {
                actionBtn.setTitle("LOCKED 🔒", for: .normal)
                actionBtn.setTitleColor(.white.withAlphaComponent(0.25), for: .normal)
                actionBtn.backgroundColor = .clear
                actionBtn.layer.borderWidth = 1.0
                actionBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
                actionBtn.isEnabled = false
            }
            
            contentStack.addArrangedSubview(card)
            
            NSLayoutConstraint.activate([
                card.heightAnchor.constraint(equalToConstant: 72),
                
                badge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
                badge.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
                badge.widthAnchor.constraint(equalToConstant: 44),
                badge.heightAnchor.constraint(equalToConstant: 16),
                
                titleL.leadingAnchor.constraint(equalTo: badge.leadingAnchor),
                titleL.topAnchor.constraint(equalTo: badge.bottomAnchor, constant: 6),
                
                descL.leadingAnchor.constraint(equalTo: titleL.leadingAnchor),
                descL.topAnchor.constraint(equalTo: titleL.bottomAnchor, constant: 2),
                
                actionBtn.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
                actionBtn.centerYAnchor.constraint(equalTo: card.centerYAnchor),
                actionBtn.widthAnchor.constraint(equalToConstant: 100),
                actionBtn.heightAnchor.constraint(equalToConstant: 28)
            ])
        }
    }
    
    @objc private func claimTapped(_ sender: UIButton) {
        guard let lvlStr = sender.accessibilityIdentifier, let lvl = Int(lvlStr) else { return }
        guard let milestone = milestones.first(where: { $0.level == lvl }) else { return }
        
        claimedLevels.insert(lvl)
        UserDefaults.standard.set(Array(claimedLevels), forKey: "GeoLive_ClaimedRewards")
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Notify callback to trigger update
        onRewardClaimed?(milestone.level, "CLAIMED: \(milestone.rewardTitle)!", milestone.cashBonus, milestone.gemBonus)
        
        // Reload rewards list
        for view in contentStack.arrangedSubviews {
            view.removeFromSuperview()
        }
        setupRewardsList()
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
