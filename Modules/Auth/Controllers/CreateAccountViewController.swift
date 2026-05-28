import UIKit
import AuthenticationServices

final class CreateAccountViewController: UIViewController {
    
    private let viewModel: CreateAccountViewModel
    
    // UI Elements
    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let backgroundEmojiContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = CreateAccountViewModel.Constants.title
        label.font = UIFont.systemFont(ofSize: 28, weight: .bold)
        // High-contrast slate-dark color for readability on the light frosted glass background
        label.textColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = CreateAccountViewModel.Constants.subtitle
        label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        // Slate-grey for a polished, modern look
        label.textColor = UIColor(red: 0.25, green: 0.30, blue: 0.40, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let googleSignInButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.backgroundColor = .white
        button.setTitle("SIGN IN WITH GOOGLE", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.08
        button.layer.shadowOffset = CGSize(width: 0, height: 4)
        button.layer.shadowRadius = 8
        if let icon = UIImage(systemName: "g.circle.fill") {
            if #available(iOS 15.0, *) {
                var config = UIButton.Configuration.filled()
                config.image = icon
                config.imagePadding = 10
                config.baseBackgroundColor = .white
                config.baseForegroundColor = .black
                config.title = "SIGN IN WITH GOOGLE"
                button.configuration = config
            } else {
                button.setImage(icon, for: .normal)
                button.tintColor = .black
                button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -10, bottom: 0, right: 10)
            }
        }
        return button
    }()
    
    private let appleSignInButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(type: .signIn, style: .black)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.cornerRadius = 25
        return button
    }()
    
    private let legalTextView: UITextView = {
        let textView = UITextView()
        textView.backgroundColor = .clear
        textView.isEditable = false
        textView.isScrollEnabled = false
        textView.textAlignment = .center
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()
    
    // Animation properties
    private let emojis = ["🗼", "🗽", "🏛️", "🕰️", "🕌", "🌉", "🏰", "🚀", "⛩️", "🏯", "🪐", "✈️", "🗺️", "🎈", "🏔️"]
    private var emojiContainers: [UIView] = []
    private var hasAnimatedEmojis = false
    
    // Curated premium ratios to prevent any overlaps or crooked/storto layouts
    private let emojiRatios: [(CGFloat, CGFloat)] = [
        (0.15, 0.26), (0.85, 0.25), // High sides
        (0.30, 0.31), (0.70, 0.30), // Upper middle inner
        (0.10, 0.37), (0.90, 0.36), // Middle outer
        (0.50, 0.34),                // Center upper
        (0.24, 0.44), (0.76, 0.43), // Low-mid inner
        (0.12, 0.51), (0.88, 0.50), // Lower outer
        (0.50, 0.49),                // Center lower
        (0.28, 0.58), (0.72, 0.57), // Lower middle inner
        (0.16, 0.64)                 // Bottom frame left
    ]
    
    init(viewModel: CreateAccountViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLegalText()
        setupActions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Hide navigation bar for absolute immersive layout
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        // Since background is now a light frosted glass, use the default dark status bar icons for high visibility
        return .default
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Ensure background matches screen bounds
        backgroundContainerView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !hasAnimatedEmojis {
            startEmojiCascadeAnimation()
            hasAnimatedEmojis = true
        }
    }
    
    private func setupUI() {
        // Base view clear to bypass any potential navigation overlays
        view.backgroundColor = .clear
        
        // Initialize the advanced blurred backdrop and white overlay
        setupBackground()
        
        view.addSubview(backgroundEmojiContainer)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        let stackView = UIStackView(arrangedSubviews: [
            googleSignInButton,
            appleSignInButton,
            legalTextView
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.backgroundColor = .clear
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        setupEmojiLabels()
        
        NSLayoutConstraint.activate([
            backgroundEmojiContainer.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundEmojiContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundEmojiContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundEmojiContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            googleSignInButton.heightAnchor.constraint(equalToConstant: 50),
            appleSignInButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupBackground() {
        view.addSubview(backgroundContainerView)
        
        // 1. Add vibrant circular organic blue splashes (blobs) behind the glass
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
        
        // Blob 4: Luminous Sky Blue (extra splash for modern ambient depth)
        let blob4 = UIView()
        blob4.backgroundColor = UIColor(red: 0.35, green: 0.70, blue: 1.00, alpha: 0.60)
        blob4.layer.cornerRadius = 130
        blob4.frame = CGRect(x: screenWidth - 140, y: screenHeight * 0.75, width: 260, height: 260)
        backgroundContainerView.addSubview(blob4)
        
        // 2. Overlay a system blur view to turn the blobs into smooth organic background colors
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(blurView)
        
        // 3. Overlay a semi-transparent white backdrop ("quadrato bianco che occupa tutto lo schermo, un po' trasparente")
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
    
    private func setupEmojiLabels() {
        // Generate 15 premium emoji labels directly without any card wrappers (no white squares)
        for _ in 0..<15 {
            let emoji = emojis.randomElement() ?? "🗼"
            
            let label = UILabel()
            label.text = emoji
            label.font = UIFont.systemFont(ofSize: 44) // Clean, gorgeous large size for modern floating emojis
            label.textAlignment = .center
            label.alpha = 0
            label.backgroundColor = .clear
            
            // Set initial scale transform for a smooth cascade entry
            label.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
            
            // Set frame size to fit the emoji perfectly
            label.frame = CGRect(x: 0, y: 0, width: 64, height: 64)
            
            backgroundEmojiContainer.addSubview(label)
            emojiContainers.append(label)
        }
    }
    
    private func startEmojiCascadeAnimation() {
        let screenWidth = view.bounds.width
        let screenHeight = view.bounds.height
        
        for (index, label) in emojiContainers.enumerated() {
            // Distribute emojis using the premium curated non-overlapping coordinate ratios
            let ratio = index < emojiRatios.count ? emojiRatios[index] : (CGFloat.random(in: 0.1...0.9), CGFloat.random(in: 0.25...0.65))
            let targetX = screenWidth * ratio.0
            let targetY = screenHeight * ratio.1
            
            // Anchor transformed emoji center safely
            label.center = CGPoint(x: targetX, y: targetY)
            
            let delay = Double(index) * 0.05
            
            // Bounce spring scale cascade animation
            UIView.animate(withDuration: 0.7, delay: delay, usingSpringWithDamping: 0.68, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
                label.alpha = 1.0
                label.transform = .identity
            }, completion: nil) // Emojis stay completely still once animated
        }
    }
    
    private func setupLegalText() {
        let fullText = CreateAccountViewModel.Constants.termsText
        let termsText = CreateAccountViewModel.Constants.termsLink
        let privacyText = CreateAccountViewModel.Constants.privacyLink
        
        let attributedString = NSMutableAttributedString(string: fullText)
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let fullRange = NSRange(location: 0, length: fullText.count)
        // High-contrast charcoal/slate legal text for perfect readability on light background
        attributedString.addAttribute(.foregroundColor, value: UIColor(red: 0.30, green: 0.35, blue: 0.45, alpha: 1.0), range: fullRange)
        attributedString.addAttribute(.font, value: UIFont.systemFont(ofSize: 12), range: fullRange)
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: fullRange)
        
        // Link styling: deep royal blue with elegant underlines
        let linkAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(red: 0.10, green: 0.40, blue: 0.90, alpha: 1.0),
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        
        if let termsRange = fullText.range(of: termsText) {
            let nsRange = NSRange(termsRange, in: fullText)
            attributedString.addAttribute(.link, value: "terms://", range: nsRange)
        }
        
        if let privacyRange = fullText.range(of: privacyText) {
            let nsRange = NSRange(privacyRange, in: fullText)
            attributedString.addAttribute(.link, value: "privacy://", range: nsRange)
        }
        
        legalTextView.linkTextAttributes = linkAttributes
        legalTextView.attributedText = attributedString
        legalTextView.delegate = self
    }
    
    private func setupActions() {
        appleSignInButton.addTarget(self, action: #selector(appleTapped), for: .touchUpInside)
        googleSignInButton.addTarget(self, action: #selector(googleTapped), for: .touchUpInside)
    }
    
    @objc private func appleTapped() { viewModel.handleAppleSignIn() }
    @objc private func googleTapped() { viewModel.handleGoogleSignIn() }
}

extension CreateAccountViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        if URL.scheme == "terms" {
            viewModel.handleTermsTapped()
            return false
        } else if URL.scheme == "privacy" {
            viewModel.handlePrivacyTapped()
            return false
        }
        return true
    }
}
