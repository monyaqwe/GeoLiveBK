import UIKit

final class LoadingViewController: UIViewController {
    
    private let nickname: String
    private let selectedGender: Gender
    private let avatarImage: UIImage?
    private let onComplete: () -> Void
    
    // UI Elements
    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Glow ring around avatar
    private let avatarGlowRing: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.12)
        view.layer.cornerRadius = 80
        view.layer.borderWidth = 1.5
        view.layer.borderColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.20).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .black)
        label.textColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Preparing your world..."
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 0.25, green: 0.30, blue: 0.40, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Custom animated progress bar
    private let progressTrack: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.90, green: 0.92, blue: 0.95, alpha: 1.0)
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let progressFill: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 1.0)
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var progressFillWidthConstraint: NSLayoutConstraint!
    
    // Animated dots for status text
    private var dotTimer: Timer?
    private var dotCount = 0
    
    // Status messages to cycle through
    private let statusMessages = [
        "Preparing your world...",
        "Loading the map...",
        "Placing your avatar...",
        "Almost ready..."
    ]
    private var currentMessageIndex = 0
    
    // MARK: - Init
    init(nickname: String, gender: Gender, avatarImage: UIImage?, onComplete: @escaping () -> Void) {
        self.nickname = nickname
        self.selectedGender = gender
        self.avatarImage = avatarImage
        self.onComplete = onComplete
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAvatar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startAnimations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundContainerView.frame = view.bounds
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .default }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .clear
        setupBackground()
        
        view.addSubview(avatarGlowRing)
        view.addSubview(avatarImageView)
        view.addSubview(welcomeLabel)
        view.addSubview(statusLabel)
        view.addSubview(progressTrack)
        progressTrack.addSubview(progressFill)
        
        welcomeLabel.text = "Welcome, \(nickname)!"
        
        // Initial state for entrance animations
        avatarImageView.alpha = 0
        avatarImageView.transform = CGAffineTransform(scaleX: 0.6, y: 0.6)
        avatarGlowRing.alpha = 0
        avatarGlowRing.transform = CGAffineTransform(scaleX: 0.5, y: 0.5)
        welcomeLabel.alpha = 0
        welcomeLabel.transform = CGAffineTransform(translationX: 0, y: 20)
        statusLabel.alpha = 0
        progressTrack.alpha = 0
        
        progressFillWidthConstraint = progressFill.widthAnchor.constraint(equalToConstant: 0)
        
        NSLayoutConstraint.activate([
            avatarGlowRing.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            avatarGlowRing.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -80),
            avatarGlowRing.widthAnchor.constraint(equalToConstant: 160),
            avatarGlowRing.heightAnchor.constraint(equalToConstant: 160),
            
            avatarImageView.centerXAnchor.constraint(equalTo: avatarGlowRing.centerXAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: avatarGlowRing.centerYAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 130),
            avatarImageView.heightAnchor.constraint(equalToConstant: 130),
            
            welcomeLabel.topAnchor.constraint(equalTo: avatarGlowRing.bottomAnchor, constant: 32),
            welcomeLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            welcomeLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            statusLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 10),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            
            progressTrack.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 28),
            progressTrack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 64),
            progressTrack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -64),
            progressTrack.heightAnchor.constraint(equalToConstant: 8),
            
            progressFill.topAnchor.constraint(equalTo: progressTrack.topAnchor),
            progressFill.leadingAnchor.constraint(equalTo: progressTrack.leadingAnchor),
            progressFill.bottomAnchor.constraint(equalTo: progressTrack.bottomAnchor),
            progressFillWidthConstraint
        ])
    }
    
    private func setupBackground() {
        view.addSubview(backgroundContainerView)
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Blob 1: Saturated Deep Blue
        let blob1 = UIView()
        blob1.backgroundColor = UIColor(red: 0.05, green: 0.30, blue: 0.85, alpha: 0.70)
        blob1.layer.cornerRadius = 140
        blob1.frame = CGRect(x: -80, y: 80, width: 280, height: 280)
        backgroundContainerView.addSubview(blob1)
        
        // Blob 2: Vibrant Electric Blue
        let blob2 = UIView()
        blob2.backgroundColor = UIColor(red: 0.00, green: 0.45, blue: 0.95, alpha: 0.65)
        blob2.layer.cornerRadius = 150
        blob2.frame = CGRect(x: screenWidth - 220, y: screenHeight * 0.3, width: 300, height: 300)
        backgroundContainerView.addSubview(blob2)
        
        // Blob 3: Soft Ocean Blue
        let blob3 = UIView()
        blob3.backgroundColor = UIColor(red: 0.18, green: 0.55, blue: 1.00, alpha: 0.75)
        blob3.layer.cornerRadius = 120
        blob3.frame = CGRect(x: 20, y: screenHeight * 0.62, width: 240, height: 240)
        backgroundContainerView.addSubview(blob3)
        
        // Blob 4: Luminous Sky Blue
        let blob4 = UIView()
        blob4.backgroundColor = UIColor(red: 0.35, green: 0.70, blue: 1.00, alpha: 0.60)
        blob4.layer.cornerRadius = 130
        blob4.frame = CGRect(x: screenWidth - 140, y: screenHeight * 0.75, width: 260, height: 260)
        backgroundContainerView.addSubview(blob4)
        
        // Blur overlay
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(blurView)
        
        // Semi-transparent white overlay
        let whiteOverlay = UIView(frame: UIScreen.main.bounds)
        whiteOverlay.backgroundColor = UIColor.white.withAlphaComponent(0.70)
        whiteOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(whiteOverlay)
        
        NSLayoutConstraint.activate([
            backgroundContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func loadAvatar() {
        if let avatar = avatarImage {
            avatarImageView.image = avatar
        } else {
            avatarImageView.image = CharacterAssets.baseMannequin(for: selectedGender)?.customizedAvatar(
                gender: selectedGender,
                skinColor: .clear,
                hair: nil,
                hat: nil,
                glasses: nil,
                beard: nil,
                clothing: nil
            )
        }
    }
    
    // MARK: - Animations
    private func startAnimations() {
        // 1. Avatar entrance (spring bounce)
        UIView.animate(withDuration: 0.8, delay: 0.2, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.avatarImageView.alpha = 1.0
            self.avatarImageView.transform = .identity
            self.avatarGlowRing.alpha = 1.0
            self.avatarGlowRing.transform = .identity
        })
        
        // 2. Welcome text fade in
        UIView.animate(withDuration: 0.6, delay: 0.6, options: .curveEaseOut, animations: {
            self.welcomeLabel.alpha = 1.0
            self.welcomeLabel.transform = .identity
        })
        
        // 3. Status and progress bar fade in
        UIView.animate(withDuration: 0.5, delay: 0.9, options: .curveEaseOut, animations: {
            self.statusLabel.alpha = 1.0
            self.progressTrack.alpha = 1.0
        }) { _ in
            self.startProgressAnimation()
            self.startStatusCycling()
        }
        
        // 4. Pulsing glow on avatar ring
        let pulseAnimation = CABasicAnimation(keyPath: "opacity")
        pulseAnimation.fromValue = 0.12
        pulseAnimation.toValue = 0.30
        pulseAnimation.duration = 1.2
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        avatarGlowRing.layer.add(pulseAnimation, forKey: "glow")
    }
    
    private func startProgressAnimation() {
        let trackWidth = UIScreen.main.bounds.width - 128 // matches the 64pt insets on each side
        
        // Animate the progress bar filling over ~3 seconds
        progressFillWidthConstraint.constant = trackWidth
        UIView.animate(withDuration: 3.0, delay: 0, options: .curveEaseInOut, animations: {
            self.view.layoutIfNeeded()
        }) { _ in
            // Auto-transition when loading completes
            self.finishLoading()
        }
    }
    
    private func startStatusCycling() {
        // Cycle through status messages every 0.8 seconds
        dotTimer = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentMessageIndex = (self.currentMessageIndex + 1) % self.statusMessages.count
            
            UIView.transition(with: self.statusLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.statusLabel.text = self.statusMessages[self.currentMessageIndex]
            })
        }
    }
    
    private func finishLoading() {
        dotTimer?.invalidate()
        dotTimer = nil
        
        // Final status
        UIView.transition(with: statusLabel, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.statusLabel.text = "Ready! 🚀"
        })
        
        // Fade out everything and transition
        UIView.animate(withDuration: 0.6, delay: 0.5, options: .curveEaseIn, animations: {
            self.avatarImageView.alpha = 0
            self.avatarGlowRing.alpha = 0
            self.welcomeLabel.alpha = 0
            self.statusLabel.alpha = 0
            self.progressTrack.alpha = 0
            self.view.backgroundColor = UIColor.black.withAlphaComponent(0.02)
        }) { _ in
            self.onComplete()
        }
    }
    
    deinit {
        dotTimer?.invalidate()
    }
}
