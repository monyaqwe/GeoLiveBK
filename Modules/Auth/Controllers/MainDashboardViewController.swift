import UIKit

/// High-fidelity cyber-operative profile dashboard (Cheapshot Aesthetic).
/// Displays character mannequins, secure data synchronization metrics, and tactical maps transition triggers.
final class MainDashboardViewController: UIViewController {
    
    private let nickname: String
    private let selectedGender: Gender
    private let avatarImage: UIImage?
    private let onDisconnect: (() -> Void)?
    var onProceed: (() -> Void)?
    
    // Ambient dark background hierarchy
    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.05, alpha: 1.0)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "OPERATIVE DASHBOARD"
        label.font = UIFont.systemFont(ofSize: 22, weight: .black)
        label.textColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Securing biometric sync links to the GeoLive grid..."
        label.font = UIFont.systemFont(ofSize: 12, weight: .semibold)
        label.textColor = UIColor.white.withAlphaComponent(0.50)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let proceedButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("ACCESS TACTICAL MAP", for: .normal)
        button.setTitleColor(UIColor(white: 0.08, alpha: 1.0), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .black)
        button.backgroundColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        button.layer.cornerRadius = 25
        
        // High-tech glowing neon shadow
        button.layer.shadowColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0).cgColor
        button.layer.shadowOpacity = 0.4
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 10
        return button
    }()
    
    // Glassmorphic Info Card with vibrant cyber cyan highlights
    private let statsCard: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.10, alpha: 0.65)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1.2
        view.layer.borderColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.25).cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }()
    
    private let disconnectButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("DISCONNECT LINK", for: .normal)
        button.setTitleColor(UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .black)
        button.layer.cornerRadius = 25
        button.layer.borderWidth = 1.2
        button.layer.borderColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 0.35).cgColor
        button.clipsToBounds = true
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isUserInteractionEnabled = false
        button.addSubview(blurView)
        button.sendSubviewToBack(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: button.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        
        return button
    }()
    
    init(nickname: String, gender: Gender, avatarImage: UIImage?, onDisconnect: (() -> Void)?) {
        self.nickname = nickname
        self.selectedGender = gender
        self.avatarImage = avatarImage
        self.onDisconnect = onDisconnect
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadAvatar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundContainerView.frame = view.bounds
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Setup visual hierarchy
        setupBackground()
        
        view.addSubview(welcomeLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(avatarImageView)
        view.addSubview(statsCard)
        view.addSubview(proceedButton)
        view.addSubview(disconnectButton)
        
        // Dynamic cyber details
        let displayNickname = nickname.isEmpty ? "NOT CONFIGURED" : nickname.uppercased()
        let nicknameColor = nickname.isEmpty ? UIColor.systemOrange : UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        let title1 = createStatLabel(title: "IDENTITY CALLSIGN", value: displayNickname, color: nicknameColor)
        let title2 = createStatLabel(title: "DATA ENCRYPTION SYNC", value: "SECURE // " + getCurrentTime(), color: UIColor.white.withAlphaComponent(0.60))
        let title3 = createStatLabel(title: "OPERATIVE AVATAR MODEL", value: selectedGender == .male ? "GEN-MALE // BATTLE-CLAY-01" : "GEN-FEMALE // BATTLE-CLAY-02", color: UIColor.white.withAlphaComponent(0.60))
        
        let stack = UIStackView(arrangedSubviews: [title1, title2, title3])
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        statsCard.addSubview(stack)
        
        NSLayoutConstraint.activate([
            welcomeLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 36),
            welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: welcomeLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            avatarImageView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 10),
            avatarImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            avatarImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            avatarImageView.bottomAnchor.constraint(equalTo: statsCard.topAnchor, constant: -20),
            
            statsCard.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            statsCard.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            statsCard.bottomAnchor.constraint(equalTo: proceedButton.topAnchor, constant: -20),
            
            stack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 18),
            stack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -18),
            
            proceedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            proceedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            proceedButton.bottomAnchor.constraint(equalTo: disconnectButton.topAnchor, constant: 14),
            proceedButton.heightAnchor.constraint(equalToConstant: 50),
            
            disconnectButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            disconnectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            disconnectButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            disconnectButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        proceedButton.addTarget(self, action: #selector(proceedTapped), for: .touchUpInside)
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
    }
    
    private func setupBackground() {
        view.addSubview(backgroundContainerView)
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        // Cyber neon aura blobs
        let blob1 = UIView()
        blob1.backgroundColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.18)
        blob1.layer.cornerRadius = 140
        blob1.frame = CGRect(x: -80, y: 100, width: 280, height: 280)
        backgroundContainerView.addSubview(blob1)
        
        let blob2 = UIView()
        blob2.backgroundColor = UIColor(red: 0.08, green: 0.30, blue: 0.95, alpha: 0.20)
        blob2.layer.cornerRadius = 140
        blob2.frame = CGRect(x: screenWidth - 200, y: screenHeight * 0.5, width: 280, height: 280)
        backgroundContainerView.addSubview(blob2)
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(blurView)
    }
    
    private func createStatLabel(title: String, value: String, color: UIColor) -> UIView {
        let container = UIView()
        
        let lblTitle = UILabel()
        lblTitle.text = title
        lblTitle.font = UIFont.systemFont(ofSize: 10, weight: .black)
        lblTitle.textColor = UIColor.white.withAlphaComponent(0.40)
        lblTitle.translatesAutoresizingMaskIntoConstraints = false
        
        let lblValue = UILabel()
        lblValue.text = value
        lblValue.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        lblValue.textColor = color
        lblValue.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(lblTitle)
        container.addSubview(lblValue)
        
        NSLayoutConstraint.activate([
            lblTitle.topAnchor.constraint(equalTo: container.topAnchor),
            lblTitle.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            lblValue.topAnchor.constraint(equalTo: lblTitle.bottomAnchor, constant: 2),
            lblValue.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            lblValue.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        
        return container
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
    
    private func getCurrentTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }
    
    @objc private func proceedTapped() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        UIView.animate(withDuration: 0.12, animations: {
            self.proceedButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.proceedButton.transform = .identity
            }
            self.onProceed?()
        }
    }
    
    @objc private func disconnectTapped() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        onDisconnect?()
    }
}
