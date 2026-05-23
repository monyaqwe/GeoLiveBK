import UIKit
import MapKit
import CoreLocation

// MARK: - Avatar Annotation
/// Custom annotation that holds the user's avatar image to display on the map.
final class AvatarAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var avatarImage: UIImage?
    
    init(coordinate: CLLocationCoordinate2D, avatarImage: UIImage?) {
        self.coordinate = coordinate
        super.init()
        self.avatarImage = avatarImage
    }
}

// MARK: - Avatar Annotation View
/// Renders the user's character standing directly on the map with a soft ground shadow in a premium Snapchat style.
final class AvatarAnnotationView: MKAnnotationView {
    
    static let reuseID = "AvatarAnnotationView"
    
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let groundShadowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.32)
        view.layer.cornerRadius = 7 // Perfect half of height (14)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        canShowCallout = false
        backgroundColor = .clear
        
        // A perfect square bounds matching the 1024x1024 aspect ratio of the customized avatar.
        // This ensures the character's feet align precisely with the bottom of the frame and never float.
        let annotationWidth: CGFloat = 110
        let annotationHeight: CGFloat = 110
        
        frame = CGRect(x: 0, y: 0, width: annotationWidth, height: annotationHeight)
        // Anchor the annotation view by its bottom-center so the character's feet stand on the coordinate.
        centerOffset = CGPoint(x: 0, y: -annotationHeight / 2)
        
        addSubview(groundShadowView)
        addSubview(avatarImageView)
        
        NSLayoutConstraint.activate([
            // Soft ground shadow centered exactly at the bottom under the feet
            groundShadowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 4),
            groundShadowView.centerXAnchor.constraint(equalTo: centerXAnchor),
            groundShadowView.widthAnchor.constraint(equalToConstant: 56),
            groundShadowView.heightAnchor.constraint(equalToConstant: 14),
            
            // Standing avatar completely filling the square view, aligning its feet precisely with the shadow
            avatarImageView.topAnchor.constraint(equalTo: topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        // Premium spring-bounce entrance animation when character appears
        transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        alpha = 0.0
        UIView.animate(withDuration: 0.65, delay: 0.0, usingSpringWithDamping: 0.65, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.transform = .identity
            self.alpha = 1.0
        }, completion: nil)
    }
    
    func configure(with image: UIImage?) {
        avatarImageView.image = image
    }
}

// MARK: - Main Map View Controller
final class MainMapViewController: UIViewController {
    
    private let nickname: String
    private let selectedGender: Gender
    private let avatarImage: UIImage?
    private let onDisconnect: (() -> Void)?
    
    private let locationManager = CLLocationManager()
    private var mapView: MKMapView!
    private var avatarAnnotation: AvatarAnnotation?
    private var hasInitiallyCentered = false
    private var hasCenteredOnHighAccuracy = false
    private var hasShownWelcomeBanner = false
    
    // Interactive 500m build range overlay
    private var interactionCircle: MKCircle?
    
    // Interactive 1500m attack range wave overlay
    private var attackCircle: MKCircle?
    
    // Bottom bar height adjustment state
    private var bottomBarHeightConstraint: NSLayoutConstraint?
    private var isBottomBarExpanded = false
    
    // Premium horizontal top status bar (Gems, Coins, Backpack)
    private let topStatsBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.10, alpha: 0.85)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor(white: 0.25, alpha: 0.60).cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        view.sendSubviewToBack(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }()
    
    // Floating bottom menu and tab bar
    private let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.10, alpha: 0.85)
        view.layer.cornerRadius = 28
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor(white: 0.25, alpha: 0.60).cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        view.sendSubviewToBack(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        return view
    }()
    
    // Top portion header container within bottomBar
    private let headerContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()
    
    // Sleek premium horizontal handle indicator for swipes
    private let pullHandle: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.28)
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Scrollable/expandable inventory section below header
    private let inventoryContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.alpha = 0.0 // Invisible when collapsed
        return view
    }()
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        label.textColor = .white
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statusDot: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.15, green: 0.85, blue: 0.45, alpha: 1.0)
        view.layer.cornerRadius = 5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let avatarThumb: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 19
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.18, alpha: 1.0)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    // Build Tab Button using sleek SF Symbols
    private let buildButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let icon = UIImage(systemName: "hammer.fill", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 19
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        return button
    }()
    
    // Profile Tab Button using sleek SF Symbols
    private let profileButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let icon = UIImage(systemName: "person.fill", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 19
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        return button
    }()
    
    // Center-on-me button
    private let centerButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        let icon = UIImage(systemName: "location.fill", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.tintColor = UIColor(red: 0.30, green: 0.70, blue: 1.00, alpha: 1.0)
        
        button.backgroundColor = UIColor(white: 0.10, alpha: 0.85)
        button.layer.cornerRadius = 26
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor(white: 0.25, alpha: 0.60).cgColor
        
        return button
    }()
    
    // Disconnect button
    private let disconnectButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .semibold)
        let icon = UIImage(systemName: "rectangle.portrait.and.arrow.right", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.tintColor = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
        
        button.backgroundColor = UIColor(white: 0.10, alpha: 0.85)
        button.layer.cornerRadius = 26
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor(white: 0.25, alpha: 0.60).cgColor
        
        return button
    }()
    
    // MARK: - Init
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
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupUI()
        setupActions()
        setupLocationManager()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // MARK: - Map Setup
    private func setupMap() {
        mapView = MKMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.showsUserLocation = false // Hide native pulsing location circle, displaying only the custom avatar
        mapView.showsCompass = false
        mapView.showsBuildings = false // Abstract flat maps (no blocky building shapes)!
        mapView.showsTraffic = false // Wipe out street traffic lines!
        
        // Use abstract muted standard style by default
        mapView.mapType = .mutedStandard
        
        // Keep only majestic museums, landmarks, and national parks, completely hiding commercial clutter
        let strictFilter = MKPointOfInterestFilter(including: [.museum, .nationalPark])
        
        if #available(iOS 13.0, *) {
            mapView.pointOfInterestFilter = strictFilter
        } else {
            mapView.pointOfInterestFilter = .excludingAll
        }
        
        // Restrict maximum zoom out to prevent heavy GPU/CPU rendering and phone load
        if #available(iOS 13.0, *) {
            let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 20000)
            mapView.setCameraZoomRange(zoomRange, animated: false)
        }
        
        // Enforce muted dark styling for tactical clean layout on iOS 16+
        if #available(iOS 16.0, *) {
            let config = MKStandardMapConfiguration(emphasisStyle: .muted)
            config.pointOfInterestFilter = strictFilter
            mapView.preferredConfiguration = config
            mapView.overrideUserInterfaceStyle = .dark
        } else {
            mapView.overrideUserInterfaceStyle = .dark
        }
        
        view.addSubview(mapView)
    }
    
    // MARK: - UI Setup
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
        
        // Bottom bar
        view.addSubview(bottomBar)
        
        // Add header container and inventory container to bottomBar
        bottomBar.addSubview(headerContainerView)
        bottomBar.addSubview(inventoryContainerView)
        
        // Add header views into headerContainerView
        headerContainerView.addSubview(pullHandle)
        headerContainerView.addSubview(avatarThumb)
        headerContainerView.addSubview(statusDot)
        headerContainerView.addSubview(nicknameLabel)
        
        nicknameLabel.text = nickname
        avatarThumb.image = avatarImage
        
        // Build and Profile Stack View
        let tabsStackView = UIStackView(arrangedSubviews: [buildButton, profileButton])
        tabsStackView.axis = .horizontal
        tabsStackView.spacing = 10
        tabsStackView.distribution = .fillEqually
        tabsStackView.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(tabsStackView)
        
        // Setup empty inventory content
        setupInventoryUI()
        
        // Add Top Stats Bar (Coins, Gems, Backpack Capacity)
        view.addSubview(topStatsBar)
        
        let coinsSegment = createStatSegment(iconName: "dollarsign.circle.fill", iconColor: UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0), text: "1,250")
        let gemsSegment = createStatSegment(iconName: "suit.diamond.fill", iconColor: UIColor(red: 0.20, green: 0.80, blue: 1.00, alpha: 1.0), text: "45")
        let bagSegment = createStatSegment(iconName: "backpack.fill", iconColor: UIColor(white: 0.75, alpha: 1.0), text: "0/8")
        
        let statsStack = UIStackView(arrangedSubviews: [coinsSegment, gemsSegment, bagSegment])
        statsStack.axis = .horizontal
        statsStack.spacing = 16
        statsStack.distribution = .equalSpacing
        statsStack.alignment = .center
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        topStatsBar.addSubview(statsStack)
        
        // Floating buttons
        view.addSubview(centerButton)
        view.addSubview(disconnectButton)
        
        bottomBarHeightConstraint = bottomBar.heightAnchor.constraint(equalToConstant: 76)
        
        NSLayoutConstraint.activate([
            // Top Stats Bar
            topStatsBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            topStatsBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topStatsBar.heightAnchor.constraint(equalToConstant: 40),
            topStatsBar.widthAnchor.constraint(equalToConstant: 290),
            
            statsStack.centerXAnchor.constraint(equalTo: topStatsBar.centerXAnchor),
            statsStack.centerYAnchor.constraint(equalTo: topStatsBar.centerYAnchor),
            statsStack.heightAnchor.constraint(equalTo: topStatsBar.heightAnchor),
            
            // Bottom Tab Bar
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            bottomBarHeightConstraint!,
            
            // Header Container View (pinned to the top of the bottomBar, always 76 tall)
            headerContainerView.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            headerContainerView.heightAnchor.constraint(equalToConstant: 76),
            
            // Pull handle centered horizontally at the top of the header container
            pullHandle.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 6),
            pullHandle.centerXAnchor.constraint(equalTo: headerContainerView.centerXAnchor),
            pullHandle.widthAnchor.constraint(equalToConstant: 36),
            pullHandle.heightAnchor.constraint(equalToConstant: 5),
            
            avatarThumb.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 12),
            avatarThumb.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor, constant: 2), // slightly offset for perfect vertical alignment under pull handle
            avatarThumb.widthAnchor.constraint(equalToConstant: 38),
            avatarThumb.heightAnchor.constraint(equalToConstant: 38),
            
            statusDot.leadingAnchor.constraint(equalTo: avatarThumb.trailingAnchor, constant: 8),
            statusDot.centerYAnchor.constraint(equalTo: avatarThumb.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),
            
            nicknameLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            nicknameLabel.trailingAnchor.constraint(lessThanOrEqualTo: tabsStackView.leadingAnchor, constant: -12),
            nicknameLabel.centerYAnchor.constraint(equalTo: avatarThumb.centerYAnchor),
            
            // Tabs Stack (Build, Profile)
            tabsStackView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -12),
            tabsStackView.centerYAnchor.constraint(equalTo: avatarThumb.centerYAnchor),
            tabsStackView.heightAnchor.constraint(equalToConstant: 38),
            
            buildButton.widthAnchor.constraint(equalToConstant: 38),
            profileButton.widthAnchor.constraint(equalToConstant: 38),
            
            // Inventory Container View (starts below the header container view)
            inventoryContainerView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            inventoryContainerView.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            inventoryContainerView.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            
            // Center button positioned floats perfectly above the bottom bar
            centerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            centerButton.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -16),
            centerButton.widthAnchor.constraint(equalToConstant: 52),
            centerButton.heightAnchor.constraint(equalToConstant: 52),
            
            // Disconnect button stacked vertically above center button
            disconnectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            disconnectButton.bottomAnchor.constraint(equalTo: centerButton.topAnchor, constant: -12),
            disconnectButton.widthAnchor.constraint(equalToConstant: 52),
            disconnectButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }
    
    // MARK: - Premium Segment Builder
    private func createStatSegment(iconName: String, iconColor: UIColor, text: String) -> UIView {
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        let iconView = UIImageView(image: UIImage(systemName: iconName, withConfiguration: config))
        iconView.tintColor = iconColor
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        
        let label = UILabel()
        label.text = text
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(iconView)
        container.addSubview(label)
        
        NSLayoutConstraint.activate([
            iconView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 16),
            iconView.heightAnchor.constraint(equalToConstant: 16),
            
            label.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            label.centerYAnchor.constraint(equalTo: container.centerYAnchor)
        ])
        
        return container
    }
    
    // MARK: - Setup Inventory UI
    private func setupInventoryUI() {
        let inventoryTitleLabel = UILabel()
        inventoryTitleLabel.text = "INVENTORY"
        inventoryTitleLabel.textColor = UIColor.white.withAlphaComponent(0.45)
        inventoryTitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .black)
        inventoryTitleLabel.textAlignment = .left
        inventoryTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        inventoryContainerView.addSubview(inventoryTitleLabel)
        
        let gridStackView = UIStackView()
        gridStackView.axis = .vertical
        gridStackView.spacing = 12
        gridStackView.distribution = .fillEqually
        gridStackView.translatesAutoresizingMaskIntoConstraints = false
        inventoryContainerView.addSubview(gridStackView)
        
        for _ in 0..<2 {
            let rowStackView = UIStackView()
            rowStackView.axis = .horizontal
            rowStackView.spacing = 12
            rowStackView.distribution = .fillEqually
            
            for _ in 0..<4 {
                let slotView = UIView()
                slotView.backgroundColor = UIColor.white.withAlphaComponent(0.06)
                slotView.layer.cornerRadius = 12
                slotView.layer.borderWidth = 1.0
                slotView.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
                
                let innerDot = UIView()
                innerDot.backgroundColor = UIColor.white.withAlphaComponent(0.08)
                innerDot.layer.cornerRadius = 4
                innerDot.translatesAutoresizingMaskIntoConstraints = false
                slotView.addSubview(innerDot)
                
                NSLayoutConstraint.activate([
                    innerDot.centerXAnchor.constraint(equalTo: slotView.centerXAnchor),
                    innerDot.centerYAnchor.constraint(equalTo: slotView.centerYAnchor),
                    innerDot.widthAnchor.constraint(equalToConstant: 8),
                    innerDot.heightAnchor.constraint(equalToConstant: 8)
                ])
                
                rowStackView.addArrangedSubview(slotView)
            }
            gridStackView.addArrangedSubview(rowStackView)
        }
        
        NSLayoutConstraint.activate([
            inventoryTitleLabel.topAnchor.constraint(equalTo: inventoryContainerView.topAnchor, constant: 6),
            inventoryTitleLabel.leadingAnchor.constraint(equalTo: inventoryContainerView.leadingAnchor, constant: 16),
            inventoryTitleLabel.trailingAnchor.constraint(equalTo: inventoryContainerView.trailingAnchor, constant: -16),
            
            gridStackView.topAnchor.constraint(equalTo: inventoryTitleLabel.bottomAnchor, constant: 10),
            gridStackView.leadingAnchor.constraint(equalTo: inventoryContainerView.leadingAnchor, constant: 16),
            gridStackView.trailingAnchor.constraint(equalTo: inventoryContainerView.trailingAnchor, constant: -16),
            gridStackView.heightAnchor.constraint(equalToConstant: 160)
        ])
    }
    
    // MARK: - Actions
    private func setupActions() {
        centerButton.addTarget(self, action: #selector(centerOnUserTapped), for: .touchUpInside)
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
        
        buildButton.addTarget(self, action: #selector(buildTapped), for: .touchUpInside)
        profileButton.addTarget(self, action: #selector(profileTapped), for: .touchUpInside)
        
        // Add premium swipe gestures to bottomBar
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeUp.direction = .up
        bottomBar.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeGesture(_:)))
        swipeDown.direction = .down
        bottomBar.addGestureRecognizer(swipeDown)
    }
    
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .up {
            expandBottomBar()
        } else if gesture.direction == .down {
            collapseBottomBar()
        }
    }
    
    private func expandBottomBar() {
        guard !isBottomBarExpanded else { return }
        isBottomBarExpanded = true
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.55, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.6, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.bottomBarHeightConstraint?.constant = 340
            self.inventoryContainerView.alpha = 1.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    private func collapseBottomBar() {
        guard isBottomBarExpanded else { return }
        isBottomBarExpanded = false
        
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.bottomBarHeightConstraint?.constant = 76
            self.inventoryContainerView.alpha = 0.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc private func buildTapped() {
        UIView.animate(withDuration: 0.12, animations: {
            self.buildButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.buildButton.transform = .identity
            }
            
            let alert = UIAlertController(
                title: "Build Mode Activated 🏗️",
                message: "Your 500-meter electromagnetic build range is fully online! You can place GeoCities structures anywhere inside the dashed blue perimeter.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Awesome", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    @objc private func profileTapped() {
        UIView.animate(withDuration: 0.12, animations: {
            self.profileButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.profileButton.transform = .identity
            }
            
            let details = """
            Avatar ID: \(self.selectedGender == .male ? "GEN-MALE // CLAY-01" : "GEN-FEMALE // CLAY-02")
            Sync Status: Online 🟢
            Energy Field: 500 Meters
            Territory Range: Local
            """
            let alert = UIAlertController(
                title: "Profile: \(self.nickname) 👤",
                message: details,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Close", style: .cancel))
            self.present(alert, animated: true)
        }
    }
    
    @objc private func centerOnUserTapped() {
        UIView.animate(withDuration: 0.12, animations: {
            self.centerButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.centerButton.transform = .identity
            }
        }
        
        var targetCoordinate: CLLocationCoordinate2D?
        if let annotation = avatarAnnotation {
            targetCoordinate = annotation.coordinate
        } else if let userLocation = mapView.userLocation.location {
            targetCoordinate = userLocation.coordinate
        } else if let location = locationManager.location {
            targetCoordinate = location.coordinate
        }
        
        if let coord = targetCoordinate, CLLocationCoordinate2DIsValid(coord) {
            let region = MKCoordinateRegion(center: coord, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
        }
    }
    
    @objc private func disconnectTapped() {
        UIView.animate(withDuration: 0.12, animations: {
            self.disconnectButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.disconnectButton.transform = .identity
            }
            self.onDisconnect?()
        }
    }
    
    // MARK: - Location Manager
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
            if let lastLocation = locationManager.location {
                handleLocationUpdate(lastLocation)
            }
        case .denied, .restricted:
            showLocationDeniedAlert()
        @unknown default:
            break
        }
    }
    
    private func showLocationDeniedAlert() {
        let alert = UIAlertController(
            title: "Location Access Required",
            message: "GeoLive needs your location to place your avatar on the map. Please enable location access in Settings.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url)
            }
        })
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    private func handleLocationUpdate(_ location: CLLocation) {
        let coordinate = location.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }
        
        // GPS Jitter filter: if stationary, do not update position
        if let existing = avatarAnnotation {
            let oldLocation = CLLocation(latitude: existing.coordinate.latitude, longitude: existing.coordinate.longitude)
            let distance = location.distance(from: oldLocation)
            // If movement displacement is less than 8 meters, ignore it to prevent constant jitter/wiggle when standing still!
            if distance < 8.0 {
                return
            }
        }
        
        placeAvatarAtLocation(coordinate)
        
        // Perform reverse geocoding on the first successful location coordinates to resolve the city and welcome the user!
        if !hasShownWelcomeBanner {
            hasShownWelcomeBanner = true
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
                guard let self = self else { return }
                let cityName = placemarks?.first?.locality ?? placemarks?.first?.subAdministrativeArea ?? "GeoLive"
                self.showWelcomeBanner(for: cityName)
            }
        }
        
        // Dynamic re-centering on high-accuracy GPS location (accuracy <= 30 meters)
        if location.horizontalAccuracy > 0 && location.horizontalAccuracy <= 30 && !hasCenteredOnHighAccuracy {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
            hasCenteredOnHighAccuracy = true
        }
    }
    
    private func placeAvatarAtLocation(_ coordinate: CLLocationCoordinate2D) {
        if let existing = avatarAnnotation {
            // Update existing annotation position
            UIView.animate(withDuration: 0.3) {
                existing.coordinate = coordinate
            }
        } else {
            // Create new annotation
            let annotation = AvatarAnnotation(coordinate: coordinate, avatarImage: avatarImage)
            avatarAnnotation = annotation
            mapView.addAnnotation(annotation)
        }
        
        // Update the 500-meter interactive build range circle overlay
        if let oldCircle = interactionCircle {
            mapView.removeOverlay(oldCircle)
        }
        let newCircle = MKCircle(center: coordinate, radius: 500) // 500m gaming radius field!
        interactionCircle = newCircle
        mapView.addOverlay(newCircle)
        
        // Update the 1500-meter interactive attack range wave overlay (3x larger)
        if let oldAttack = attackCircle {
            mapView.removeOverlay(oldAttack)
        }
        let newAttack = MKCircle(center: coordinate, radius: 1500) // 1500m attack radius wave!
        attackCircle = newAttack
        mapView.addOverlay(newAttack)
        
        if !hasInitiallyCentered {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
            hasInitiallyCentered = true
        }
    }
}

// MARK: - CLLocationManagerDelegate
extension MainMapViewController: CLLocationManagerDelegate {
    
    // Modern iOS 14+ Delegate callback
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = manager.authorizationStatus
        } else {
            status = CLLocationManager.authorizationStatus()
        }
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            if let location = manager.location {
                handleLocationUpdate(location)
            }
        case .denied, .restricted:
            showLocationDeniedAlert()
        default:
            break
        }
    }
    
    // Legacy iOS 13 and below callback
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            manager.startUpdatingLocation()
            if let location = manager.location {
                handleLocationUpdate(location)
            }
        case .denied, .restricted:
            showLocationDeniedAlert()
        default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        handleLocationUpdate(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - MKMapViewDelegate
extension MainMapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            // Defensively force hide the Apple blue dot by returning a completely invisible, zero-sized view
            let identifier = "InvisibleUserLocation"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.frame = .zero
                view?.isEnabled = false
            }
            return view
        }
        
        guard let avatarAnnotation = annotation as? AvatarAnnotation else { return nil }
        
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: AvatarAnnotationView.reuseID) as? AvatarAnnotationView
            ?? AvatarAnnotationView(annotation: annotation, reuseIdentifier: AvatarAnnotationView.reuseID)
        
        view.annotation = avatarAnnotation
        view.configure(with: avatarAnnotation.avatarImage)
        return view
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let circleOverlay = overlay as? MKCircle {
            if circleOverlay.radius > 600 {
                // Interactive 1500m attack range wave overlay (soft white wave)
                let renderer = MKCircleRenderer(circle: circleOverlay)
                renderer.fillColor = UIColor.white.withAlphaComponent(0.01)
                renderer.strokeColor = UIColor.white.withAlphaComponent(0.12)
                renderer.lineWidth = 1.2
                renderer.lineDashPattern = [4, 6] // Beautiful thin white wave pattern
                return renderer
            } else {
                // Interactive 500m build range circle overlay (clearly read but elegant electric blue)
                let renderer = MKCircleRenderer(circle: circleOverlay)
                renderer.fillColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.06)
                renderer.strokeColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.28)
                renderer.lineWidth = 1.5
                renderer.lineDashPattern = [6, 4] // Dashed outline
                return renderer
            }
        }
        return MKOverlayRenderer(overlay: overlay)
    }
    
    // MARK: - Animated Welcome HUD Banner
    private func showWelcomeBanner(for cityName: String) {
        // Construct glassmorphic dark-blur container
        let welcomeView = UIView()
        welcomeView.backgroundColor = UIColor(white: 0.08, alpha: 0.88)
        welcomeView.layer.cornerRadius = 24
        welcomeView.layer.borderWidth = 1.2
        welcomeView.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        welcomeView.clipsToBounds = true
        welcomeView.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.addSubview(blurView)
        welcomeView.sendSubviewToBack(blurView)
        
        // Add Sub-title (WELCOME TO)
        let subLabel = UILabel()
        subLabel.text = "WELCOME TO"
        subLabel.textColor = UIColor.white.withAlphaComponent(0.50)
        subLabel.font = UIFont.systemFont(ofSize: 10, weight: .black)
        subLabel.textAlignment = .center
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.addSubview(subLabel)
        
        // Add Main Title (City Name)
        let titleLabel = UILabel()
        titleLabel.text = "\(cityName) 📍"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.addSubview(titleLabel)
        
        view.addSubview(welcomeView)
        
        // Layout constraints centered on screen
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: welcomeView.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: welcomeView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: welcomeView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: welcomeView.bottomAnchor),
            
            welcomeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            welcomeView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -60),
            welcomeView.widthAnchor.constraint(equalToConstant: 280),
            welcomeView.heightAnchor.constraint(equalToConstant: 80),
            
            subLabel.topAnchor.constraint(equalTo: welcomeView.topAnchor, constant: 14),
            subLabel.centerXAnchor.constraint(equalTo: welcomeView.centerXAnchor),
            
            titleLabel.topAnchor.constraint(equalTo: subLabel.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: welcomeView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: welcomeView.trailingAnchor, constant: -16)
        ])
        
        // Haptic welcome feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Scale and fade-in animation
        welcomeView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        welcomeView.alpha = 0.0
        
        UIView.animate(withDuration: 0.65, delay: 0.15, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            welcomeView.transform = .identity
            welcomeView.alpha = 1.0
        }) { _ in
            // Auto dismiss after 3.5 seconds
            UIView.animate(withDuration: 0.50, delay: 3.50, options: .curveEaseIn, animations: {
                welcomeView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                welcomeView.alpha = 0.0
            }) { _ in
                welcomeView.removeFromSuperview()
            }
        }
    }
}
