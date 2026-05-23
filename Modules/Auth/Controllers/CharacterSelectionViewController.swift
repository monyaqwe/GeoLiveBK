import UIKit

final class CharacterSelectionViewController: UIViewController {
    
    private let viewModel: CharacterSelectionViewModel
    
    // UI Elements
    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
        
        // Large modern bold X mark
        let config = UIImage.SymbolConfiguration(pointSize: 20, weight: .bold)
        let icon = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(icon, for: .normal)
        return button
    }()
    
    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Choose your character"
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Avatar circle container and view (fully transparent to let character blend natively)
    private let avatarCircleContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // Custom gender selection buttons
    private let maleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("MALE", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = 22
        return button
    }()
    
    private let femaleButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("FEMALE", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = 22
        return button
    }()
    
    private let confirmButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 1.0)
        button.setTitle("CONFIRM", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .black)
        
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.35).cgColor
        button.layer.shadowOpacity = 1.0
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 12
        button.clipsToBounds = false
        return button
    }()
    
    init(viewModel: CharacterSelectionViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        bindViewModel()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundContainerView.frame = view.bounds
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // 1. Setup cohesive frosted background with blue splashes
        setupBackground()
        
        // 2. Add subviews
        view.addSubview(closeButton)
        view.addSubview(headerTitleLabel)
        view.addSubview(avatarCircleContainer)
        avatarCircleContainer.addSubview(avatarImageView)
        
        setupLiquidGlassButton(maleButton)
        setupLiquidGlassButton(femaleButton)
        
        let buttonStack = UIStackView(arrangedSubviews: [maleButton, femaleButton])
        buttonStack.axis = .horizontal
        buttonStack.distribution = .fillEqually
        buttonStack.spacing = 16
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(buttonStack)
        
        view.addSubview(confirmButton)
        
        // 3. Layout constraints to position buttons at bottom and maximize avatar size
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 44),
            closeButton.heightAnchor.constraint(equalToConstant: 44),
            
            headerTitleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerTitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            avatarCircleContainer.topAnchor.constraint(equalTo: headerTitleLabel.bottomAnchor, constant: 8),
            avatarCircleContainer.bottomAnchor.constraint(equalTo: buttonStack.topAnchor, constant: -8),
            avatarCircleContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            avatarCircleContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            
            avatarImageView.topAnchor.constraint(equalTo: avatarCircleContainer.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarCircleContainer.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarCircleContainer.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarCircleContainer.bottomAnchor),
            
            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            buttonStack.bottomAnchor.constraint(equalTo: confirmButton.topAnchor, constant: -12),
            buttonStack.heightAnchor.constraint(equalToConstant: 44),
            
            confirmButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            confirmButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            confirmButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            confirmButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupBackground() {
        view.addSubview(backgroundContainerView)
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(blurView)
        
        let whiteOverlay = UIView(frame: UIScreen.main.bounds)
        whiteOverlay.backgroundColor = UIColor(white: 0.95, alpha: 1.0) // Even light gray background to perfectly contrast the characters
        whiteOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(whiteOverlay)
        
        NSLayoutConstraint.activate([
            backgroundContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    private func setupLiquidGlassButton(_ button: UIButton) {
        button.backgroundColor = .clear
        button.layer.cornerRadius = 22
        button.clipsToBounds = true
        button.layer.borderWidth = 1.0
        
        // Premium Apple Liquid Glass Backdrop Blur
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
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        maleButton.addTarget(self, action: #selector(maleTapped), for: .touchUpInside)
        femaleButton.addTarget(self, action: #selector(femaleTapped), for: .touchUpInside)
        confirmButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)
    }
    
    private func bindViewModel() {
        viewModel.onGenderChanged = { [weak self] gender in
            self?.updateGenderUI(gender, animated: true)
        }
        
        // Initial setup
        updateGenderUI(viewModel.selectedGender, animated: false)
    }
    
    private func updateGenderUI(_ gender: Gender, animated: Bool) {
        // 1. Resolve avatar image with white backdrop dynamically dropped out at runtime
        let image: UIImage?
        switch gender {
        case .male:
            image = CharacterAssets.baseMannequin(for: .male)?.customizedAvatar(
                gender: .male,
                skinColor: .clear,
                hair: nil,
                hat: nil,
                glasses: nil,
                beard: nil,
                clothing: nil
            )
        case .female:
            image = CharacterAssets.baseMannequin(for: .female)?.customizedAvatar(
                gender: .female,
                skinColor: .clear,
                hair: nil,
                hat: nil,
                glasses: nil,
                beard: nil,
                clothing: nil
            )
        }
        
        // 2. Perform smooth image change cross-fade animation
        if animated {
            UIView.transition(with: avatarImageView, duration: 0.35, options: .transitionCrossDissolve, animations: {
                self.avatarImageView.image = image
            }, completion: nil)
        } else {
            avatarImageView.image = image
        }
        
        // 3. Highlight the active/inactive gender choice buttons using modern Liquid Glass styling
        let activeBorderColor = UIColor.white.withAlphaComponent(0.85).cgColor
        let inactiveBorderColor = UIColor.white.withAlphaComponent(0.25).cgColor
        
        let activeBgColor = UIColor.white.withAlphaComponent(0.22)
        let inactiveBgColor = UIColor.white.withAlphaComponent(0.06)
        
        let activeTextColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
        let inactiveTextColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.45)
        
        switch gender {
        case .male:
            maleButton.backgroundColor = activeBgColor
            maleButton.layer.borderColor = activeBorderColor
            maleButton.layer.borderWidth = 1.8
            maleButton.setTitleColor(activeTextColor, for: .normal)
            
            maleButton.layer.shadowColor = UIColor.white.cgColor
            maleButton.layer.shadowOpacity = 0.25
            maleButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            maleButton.layer.shadowRadius = 4
            
            femaleButton.backgroundColor = inactiveBgColor
            femaleButton.layer.borderColor = inactiveBorderColor
            femaleButton.layer.borderWidth = 1.0
            femaleButton.setTitleColor(inactiveTextColor, for: .normal)
            femaleButton.layer.shadowOpacity = 0
            
        case .female:
            femaleButton.backgroundColor = activeBgColor
            femaleButton.layer.borderColor = activeBorderColor
            femaleButton.layer.borderWidth = 1.8
            femaleButton.setTitleColor(activeTextColor, for: .normal)
            
            femaleButton.layer.shadowColor = UIColor.white.cgColor
            femaleButton.layer.shadowOpacity = 0.25
            femaleButton.layer.shadowOffset = CGSize(width: 0, height: 2)
            femaleButton.layer.shadowRadius = 4
            
            maleButton.backgroundColor = inactiveBgColor
            maleButton.layer.borderColor = inactiveBorderColor
            maleButton.layer.borderWidth = 1.0
            maleButton.setTitleColor(inactiveTextColor, for: .normal)
            maleButton.layer.shadowOpacity = 0
        }
    }

    
    // Actions
    @objc private func closeTapped() {
        viewModel.dismiss()
    }
    
    @objc private func maleTapped() {
        viewModel.selectGender(.male)
    }
    
    @objc private func femaleTapped() {
        viewModel.selectGender(.female)
    }
    
    @objc private func confirmTapped() {
        // Tactical bounce animation on button click
        UIView.animate(withDuration: 0.1, animations: {
            self.confirmButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.confirmButton.transform = .identity
            }
            self.viewModel.confirm()
        }
    }
}
