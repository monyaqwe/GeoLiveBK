import UIKit

final class MainDashboardViewController: UIViewController {
    
    private let nickname: String
    private let selectedGender: Gender
    private let avatarImage: UIImage?
    private let onDisconnect: (() -> Void)?
    var onProceed: (() -> Void)?
    
    // UI Elements
    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let welcomeLabel: UILabel = {
        let label = UILabel()
        label.text = "AUTHORIZED ACCESS"
        label.font = UIFont.systemFont(ofSize: 22, weight: .black)
        label.textColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Your 3D avatar is connected to the GeoLive matrix."
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 0.25, green: 0.30, blue: 0.40, alpha: 1.0)
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
        button.setTitle("CONFIGURE NICKNAME & MAP", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        button.backgroundColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 1.0)
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 1.0).cgColor
        button.layer.shadowOpacity = 0.3
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        return button
    }()
    
    // Glassmorphic Info Card
    private let statsCard: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.50).cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .systemMaterialLight)
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
        button.setTitle("DISCONNECT", for: .normal)
        button.setTitleColor(UIColor(red: 0.85, green: 0.20, blue: 0.20, alpha: 1.0), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = 25
        button.layer.borderWidth = 1.2
        button.layer.borderColor = UIColor.red.withAlphaComponent(0.20).cgColor
        button.clipsToBounds = true
        
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
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
        view.backgroundColor = .clear
        
        // 1. Frosted ambient background
        setupBackground()
        
        view.addSubview(welcomeLabel)
        view.addSubview(subtitleLabel)
        view.addSubview(avatarImageView)
        view.addSubview(statsCard)
        view.addSubview(proceedButton)
        view.addSubview(disconnectButton)
        
        // Populate stats inside card
        let displayNickname = nickname.isEmpty ? "NOT CONFIGURED" : nickname.uppercased()
        let nicknameColor = nickname.isEmpty ? UIColor.systemOrange : UIColor(red: 0.05, green: 0.60, blue: 0.30, alpha: 1.0)
        let title1 = createStatLabel(title: "NICKNAME", value: displayNickname, color: nicknameColor)
        let title2 = createStatLabel(title: "DATA SYNC", value: "TODAY, " + getCurrentTime(), color: .darkGray)
        let title3 = createStatLabel(title: "AVATAR ID", value: selectedGender == .male ? "GEN-MALE // CLAY-01" : "GEN-FEMALE // CLAY-02", color: .darkGray)
        
        let stack = UIStackView(arrangedSubviews: [title1, title2, title3])
        stack.axis = .vertical
        stack.spacing = 10
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
            
            stack.topAnchor.constraint(equalTo: statsCard.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: statsCard.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: statsCard.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: statsCard.bottomAnchor, constant: -16),
            
            proceedButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            proceedButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            proceedButton.bottomAnchor.constraint(equalTo: disconnectButton.topAnchor, constant: -14),
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
        
        let blob1 = UIView()
        blob1.backgroundColor = UIColor(red: 0.05, green: 0.30, blue: 0.85, alpha: 0.50)
        blob1.layer.cornerRadius = 140
        blob1.frame = CGRect(x: -80, y: 100, width: 280, height: 280)
        backgroundContainerView.addSubview(blob1)
        
        let blob2 = UIView()
        blob2.backgroundColor = UIColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 0.50)
        blob2.layer.cornerRadius = 140
        blob2.frame = CGRect(x: screenWidth - 200, y: screenHeight * 0.5, width: 280, height: 280)
        backgroundContainerView.addSubview(blob2)
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(blurView)
        
        let whiteOverlay = UIView(frame: UIScreen.main.bounds)
        whiteOverlay.backgroundColor = UIColor.white.withAlphaComponent(0.75)
        whiteOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(whiteOverlay)
    }
    
    private func createStatLabel(title: String, value: String, color: UIColor) -> UIView {
        let container = UIView()
        
        let lblTitle = UILabel()
        lblTitle.text = title
        lblTitle.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        lblTitle.textColor = UIColor(red: 0.40, green: 0.45, blue: 0.55, alpha: 1.0)
        lblTitle.translatesAutoresizingMaskIntoConstraints = false
        
        let lblValue = UILabel()
        lblValue.text = value
        lblValue.font = UIFont.systemFont(ofSize: 13, weight: .semibold)
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
        UIView.animate(withDuration: 0.12, animations: {
            self.proceedButton.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.proceedButton.transform = .identity
            }
            self.onProceed?()
        }
    }
    
    @objc private func disconnectTapped() {
        onDisconnect?()
    }
}
