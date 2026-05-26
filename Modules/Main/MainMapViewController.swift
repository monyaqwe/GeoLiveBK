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

// MARK: - Building Models
enum BuildingType: String {
    case kiosk = "Kiosk"
    case cafe = "Cafe"
    case bar = "Bar"
    
    var cost: Int {
        switch self {
        case .kiosk: return 10000
        case .cafe: return 20000
        case .bar: return 30000
        }
    }
    
    var emoji: String {
        switch self {
        case .kiosk: return "🏪"
        case .cafe: return "☕"
        case .bar: return "🍺"
        }
    }
}

struct BuildingItem {
    let id = UUID()
    let type: BuildingType
    var coordinate: CLLocationCoordinate2D
    var level: Int = 1
    var currentHP: Int = 100
    var maxHP: Int = 100
    
    var name: String { type.rawValue }
    var cost: Int { type.cost }
    var capacity: Int { level }
    var emoji: String { type.emoji }
}

final class BuildingAnnotation: NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    var buildingItem: BuildingItem
    
    var title: String? { "\(buildingItem.name) (Lv. \(buildingItem.level))" }
    var subtitle: String? { "HP: \(buildingItem.currentHP)/\(buildingItem.maxHP) | Slots: \(buildingItem.capacity)" }
    
    init(coordinate: CLLocationCoordinate2D, buildingItem: BuildingItem) {
        self.coordinate = coordinate
        self.buildingItem = buildingItem
        super.init()
    }
}

// MARK: - Building Annotation View
final class BuildingAnnotationView: MKAnnotationView {
    static let reuseID = "BuildingAnnotationView"
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.12, alpha: 0.88)
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        
        let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
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
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let badgeLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 9, weight: .black)
        label.textColor = .white
        label.textAlignment = .center
        label.backgroundColor = UIColor(red: 0.15, green: 0.55, blue: 0.95, alpha: 1.0)
        label.layer.cornerRadius = 7
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let groundShadowView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.28)
        view.layer.cornerRadius = 5
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
        
        frame = CGRect(x: 0, y: 0, width: 56, height: 62)
        centerOffset = CGPoint(x: 0, y: -24)
        
        addSubview(groundShadowView)
        addSubview(containerView)
        containerView.addSubview(emojiLabel)
        containerView.addSubview(badgeLabel)
        
        NSLayoutConstraint.activate([
            groundShadowView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: 2),
            groundShadowView.centerXAnchor.constraint(equalTo: centerXAnchor),
            groundShadowView.widthAnchor.constraint(equalToConstant: 30),
            groundShadowView.heightAnchor.constraint(equalToConstant: 10),
            
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            emojiLabel.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: containerView.centerYAnchor, constant: -2),
            
            badgeLabel.topAnchor.constraint(equalTo: containerView.topAnchor, constant: -4),
            badgeLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: 4),
            badgeLabel.widthAnchor.constraint(equalToConstant: 24),
            badgeLabel.heightAnchor.constraint(equalToConstant: 14)
        ])
    }
    
    func configure(with building: BuildingItem) {
        emojiLabel.text = building.emoji
        badgeLabel.text = "L\(building.level)"
        
        // Premium bounce animation on first load
        transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.transform = .identity
        }, completion: nil)
    }
}

// MARK: - Store Card View
final class StoreCardView: UIView {
    let buildingType: BuildingType
    
    init(type: BuildingType) {
        self.buildingType = type
        super.init(frame: .zero)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
    
    // Player dynamic resources
    private var coins: Int = 100000
    private var gems: Int = 0
    
    // UI Outlets for stats
    private var coinsLabel: UILabel?
    private var gemsLabel: UILabel?
    
    // Construction and Upgrade states
    private var placedBuildings: [BuildingItem] = []
    private var isPlacementModeActive: Bool = false
    private var selectedTypeToPlace: BuildingType?
    private var placementOverlayView: UIView?
    private var mapTapRecognizer: UITapGestureRecognizer?
    private var buildStorePanel: UIView?
    private var inspectionPanel: UIView?
    private var selectedBuildingAnnotation: BuildingAnnotation?
    
    // MARK: - Initю
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
            let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 8000)
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
        
        let coinsResult = createStatSegment(iconName: "dollarsign.circle.fill", iconColor: UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0), text: "100,000")
        let gemsResult = createStatSegment(iconName: "suit.diamond.fill", iconColor: UIColor(red: 0.20, green: 0.80, blue: 1.00, alpha: 1.0), text: "0")
        let bagResult = createStatSegment(iconName: "backpack.fill", iconColor: UIColor(white: 0.75, alpha: 1.0), text: "0/8")
        
        self.coinsLabel = coinsResult.1
        self.gemsLabel = gemsResult.1
        
        let statsStack = UIStackView(arrangedSubviews: [coinsResult.0, gemsResult.0, bagResult.0])
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
    private func createStatSegment(iconName: String, iconColor: UIColor, text: String) -> (UIView, UILabel) {
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
        
        return (container, label)
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
            self.showBuildStorePanel()
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
    
    // MARK: - Build Store & Dynamic Placement Engine
    private func showBuildStorePanel() {
        dismissActivePanels(animated: false)
        
        // Hide bottom bar with smooth animation
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.bottomBar.transform = CGAffineTransform(translationX: 0, y: 150)
            self.bottomBar.alpha = 0
            self.centerButton.transform = CGAffineTransform(translationX: 0, y: 150)
            self.centerButton.alpha = 0
            self.disconnectButton.transform = CGAffineTransform(translationX: 0, y: 150)
            self.disconnectButton.alpha = 0
        }, completion: nil)
        
        let panelHeight: CGFloat = 280
        
        let panel = UIView()
        panel.backgroundColor = UIColor(white: 0.10, alpha: 0.90)
        panel.layer.cornerRadius = 24
        panel.layer.borderWidth = 1.0
        panel.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        panel.clipsToBounds = true
        panel.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: panel.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: panel.bottomAnchor)
        ])
        
        // Drag indicator handle
        let dragHandle = UIView()
        dragHandle.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        dragHandle.layer.cornerRadius = 2.5
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(dragHandle)
        
        // Header
        let titleLabel = UILabel()
        titleLabel.text = "BUILD STORE 🏗️"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Select a business to construct in your zone"
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        subtitleLabel.font = UIFont.systemFont(ofSize: 11, weight: .medium)
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(subtitleLabel)
        
        // Close Button
        let closeButton = UIButton(type: .system)
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let closeIcon = UIImage(systemName: "xmark.circle.fill", withConfiguration: closeConfig)
        closeButton.setImage(closeIcon, for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.4)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeStorePanel), for: .touchUpInside)
        panel.addSubview(closeButton)
        
        // Horizontal stack of cards
        let cardsStack = UIStackView()
        cardsStack.axis = .horizontal
        cardsStack.spacing = 10
        cardsStack.distribution = .fillEqually
        cardsStack.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(cardsStack)
        
        // Create 3 cards: Kiosk, Cafe, Bar
        let types: [BuildingType] = [.kiosk, .cafe, .bar]
        for type in types {
            let card = createStoreCard(for: type)
            cardsStack.addArrangedSubview(card)
        }
        
        view.addSubview(panel)
        self.buildStorePanel = panel
        
        NSLayoutConstraint.activate([
            panel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            panel.heightAnchor.constraint(equalToConstant: panelHeight),
            
            dragHandle.topAnchor.constraint(equalTo: panel.topAnchor, constant: 8),
            dragHandle.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 36),
            dragHandle.heightAnchor.constraint(equalToConstant: 5),
            
            titleLabel.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 18),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            subtitleLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 18),
            
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -18),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
            
            cardsStack.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 16),
            cardsStack.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 18),
            cardsStack.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -18),
            cardsStack.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -20)
        ])
        
        // Animate slide up with bounce
        panel.transform = CGAffineTransform(translationX: 0, y: 350)
        panel.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            panel.transform = .identity
            panel.alpha = 1.0
        }, completion: nil)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func createStoreCard(for type: BuildingType) -> StoreCardView {
        let card = StoreCardView(type: type)
        card.backgroundColor = UIColor.white.withAlphaComponent(0.05)
        card.layer.cornerRadius = 18
        card.layer.borderWidth = 1.0
        card.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        card.translatesAutoresizingMaskIntoConstraints = false
        
        let emojiLabel = UILabel()
        emojiLabel.text = type.emoji
        emojiLabel.font = .systemFont(ofSize: 34)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(emojiLabel)
        
        let nameLabel = UILabel()
        nameLabel.text = type.rawValue.uppercased()
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 12, weight: .black)
        nameLabel.textAlignment = .center
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(nameLabel)
        
        let costLabel = UILabel()
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedCost = formatter.string(from: NSNumber(value: type.cost)) ?? "\(type.cost)"
        costLabel.text = "\(formattedCost) 🪙"
        costLabel.textColor = UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0)
        costLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        costLabel.textAlignment = .center
        costLabel.translatesAutoresizingMaskIntoConstraints = false
        card.addSubview(costLabel)
        
        NSLayoutConstraint.activate([
            emojiLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 16),
            emojiLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 10),
            nameLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 4),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -4),
            
            costLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            costLabel.centerXAnchor.constraint(equalTo: card.centerXAnchor),
            costLabel.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -16)
        ])
        
        // Tap Gesture Recognizer
        let tap = UITapGestureRecognizer(target: self, action: #selector(storeCardTapped(_:)))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        
        return card
    }
    
    @objc private func storeCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view as? StoreCardView else { return }
        
        // Micro-bounce visual touch animation on the card
        UIView.animate(withDuration: 0.12, animations: {
            card.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                card.transform = .identity
            }
            self.storeCardSelected(type: card.buildingType)
        }
    }
    
    private func storeCardSelected(type: BuildingType) {
        dismissActivePanels(animated: true)
        
        isPlacementModeActive = true
        selectedTypeToPlace = type
        
        // Create top HUD banner
        let hud = UIView()
        hud.backgroundColor = UIColor(white: 0.08, alpha: 0.90)
        hud.layer.cornerRadius = 16
        hud.layer.borderWidth = 1.0
        hud.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        hud.clipsToBounds = true
        hud.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        hud.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: hud.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: hud.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: hud.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: hud.bottomAnchor)
        ])
        
        let textLabel = UILabel()
        textLabel.numberOfLines = 2
        textLabel.textAlignment = .left
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedCost = formatter.string(from: NSNumber(value: type.cost)) ?? "\(type.cost)"
        
        let titleAttr = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12, weight: .bold),
            NSAttributedString.Key.foregroundColor: UIColor.white
        ]
        let subAttr = [
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 10, weight: .semibold),
            NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.6)
        ]
        
        let attrString = NSMutableAttributedString(string: "PLACING \(type.rawValue.uppercased())\n", attributes: titleAttr)
        attrString.append(NSAttributedString(string: "Tap inside 500m blue range | Cost: \(formattedCost) 🪙", attributes: subAttr))
        textLabel.attributedText = attrString
        textLabel.translatesAutoresizingMaskIntoConstraints = false
        hud.addSubview(textLabel)
        
        let cancelBtn = UIButton(type: .system)
        cancelBtn.setTitle("CANCEL", for: .normal)
        cancelBtn.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .black)
        cancelBtn.tintColor = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
        cancelBtn.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        cancelBtn.layer.cornerRadius = 10
        cancelBtn.layer.borderWidth = 1.0
        cancelBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.15).cgColor
        cancelBtn.translatesAutoresizingMaskIntoConstraints = false
        cancelBtn.addTarget(self, action: #selector(cancelPlacementMode), for: .touchUpInside)
        hud.addSubview(cancelBtn)
        
        view.addSubview(hud)
        self.placementOverlayView = hud
        
        NSLayoutConstraint.activate([
            hud.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            hud.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            hud.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            hud.heightAnchor.constraint(equalToConstant: 54),
            
            textLabel.leadingAnchor.constraint(equalTo: hud.leadingAnchor, constant: 16),
            textLabel.centerYAnchor.constraint(equalTo: hud.centerYAnchor),
            
            cancelBtn.trailingAnchor.constraint(equalTo: hud.trailingAnchor, constant: -12),
            cancelBtn.centerYAnchor.constraint(equalTo: hud.centerYAnchor),
            cancelBtn.widthAnchor.constraint(equalToConstant: 72),
            cancelBtn.heightAnchor.constraint(equalToConstant: 28)
        ])
        
        // Hide topStatsBar
        UIView.animate(withDuration: 0.25) {
            self.topStatsBar.transform = CGAffineTransform(translationX: 0, y: -100)
            self.topStatsBar.alpha = 0
        }
        
        // Slide in HUD from top
        hud.transform = CGAffineTransform(translationX: 0, y: -100)
        hud.alpha = 0
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            hud.transform = .identity
            hud.alpha = 1.0
        }, completion: nil)
        
        // Add tap gesture to map
        if let oldTap = mapTapRecognizer {
            mapView.removeGestureRecognizer(oldTap)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tap)
        self.mapTapRecognizer = tap
    }
    
    @objc private func cancelPlacementMode() {
        guard isPlacementModeActive else { return }
        isPlacementModeActive = false
        selectedTypeToPlace = nil
        
        // Remove map tap recognizer
        if let tap = mapTapRecognizer {
            mapView.removeGestureRecognizer(tap)
            mapTapRecognizer = nil
        }
        
        // Slide out top HUD
        if let hud = placementOverlayView {
            placementOverlayView = nil
            UIView.animate(withDuration: 0.35, animations: {
                hud.transform = CGAffineTransform(translationX: 0, y: -100)
                hud.alpha = 0
            }) { _ in
                hud.removeFromSuperview()
            }
        }
        
        // Bring back topStatsBar and bottomBar
        UIView.animate(withDuration: 0.40, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.topStatsBar.transform = .identity
            self.topStatsBar.alpha = 1.0
            
            self.bottomBar.transform = .identity
            self.bottomBar.alpha = 1.0
            self.centerButton.transform = .identity
            self.centerButton.alpha = 1.0
            self.disconnectButton.transform = .identity
            self.disconnectButton.alpha = 1.0
        }, completion: nil)
    }
    
    @objc private func closeStorePanel() {
        dismissActivePanels(animated: true)
        
        // Bring back bottomBar and location buttons
        UIView.animate(withDuration: 0.40, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.bottomBar.transform = .identity
            self.bottomBar.alpha = 1.0
            self.centerButton.transform = .identity
            self.centerButton.alpha = 1.0
            self.disconnectButton.transform = .identity
            self.disconnectButton.alpha = 1.0
        }, completion: nil)
    }
    
    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        guard isPlacementModeActive, let type = selectedTypeToPlace else { return }
        
        // Convert screen touch to map coordinate
        let touchPoint = gesture.location(in: mapView)
        let tapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        
        // Get user coordinate
        guard let userCoord = avatarAnnotation?.coordinate else {
            showNotificationHUD(message: "Location unavailable! Stand where GPS syncs.")
            return
        }
        
        // Calculate distance in meters
        let userLoc = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
        let tapLoc = CLLocation(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude)
        let distance = tapLoc.distance(from: userLoc)
        
        // 1. Distance check
        if distance > 500.0 {
            showNotificationHUD(message: "OUT OF RANGE 📡\nDistance is \(Int(distance))m. Must be inside 500m circle!")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        // 2. Fund check
        if coins < type.cost {
            showNotificationHUD(message: "INSUFFICIENT FUNDS 🪙\nNeed \(type.cost) coins, you have \(coins)!")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        // 3. Construction Successful!
        coins -= type.cost
        updateStatsBarLabels()
        
        let newBuilding = BuildingItem(type: type, coordinate: tapCoordinate)
        placedBuildings.append(newBuilding)
        
        let annotation = BuildingAnnotation(coordinate: tapCoordinate, buildingItem: newBuilding)
        mapView.addAnnotation(annotation)
        
        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showNotificationHUD(message: "CONSTRUCTION SUCCESSFUL 🏗️\nPlaced \(type.rawValue)!")
        
        // Exit placement mode
        cancelPlacementMode()
    }
    
    // MARK: - Inspection & Upgrade Engine
    private func showBuildingInspectionPanel(for annotation: BuildingAnnotation) {
        dismissActivePanels(animated: false)
        
        self.selectedBuildingAnnotation = annotation
        
        // Hide bottom bar with smooth animation
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.bottomBar.transform = CGAffineTransform(translationX: 0, y: 150)
            self.bottomBar.alpha = 0
            self.centerButton.transform = CGAffineTransform(translationX: 0, y: 150)
            self.centerButton.alpha = 0
            self.disconnectButton.transform = CGAffineTransform(translationX: 0, y: 150)
            self.disconnectButton.alpha = 0
        }, completion: nil)
        
        let panelHeight: CGFloat = 220
        
        let panel = UIView()
        panel.backgroundColor = UIColor(white: 0.10, alpha: 0.90)
        panel.layer.cornerRadius = 24
        panel.layer.borderWidth = 1.0
        panel.layer.borderColor = UIColor.white.withAlphaComponent(0.18).cgColor
        panel.clipsToBounds = true
        panel.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: panel.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: panel.bottomAnchor)
        ])
        
        // Drag indicator handle
        let dragHandle = UIView()
        dragHandle.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        dragHandle.layer.cornerRadius = 2.5
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(dragHandle)
        
        // Building Title & Info
        let building = annotation.buildingItem
        
        let emojiLabel = UILabel()
        emojiLabel.text = building.emoji
        emojiLabel.font = .systemFont(ofSize: 38)
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(emojiLabel)
        
        let nameLabel = UILabel()
        nameLabel.text = "\(building.name.uppercased())"
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(nameLabel)
        
        let levelLabel = UILabel()
        levelLabel.text = "LEVEL \(building.level)"
        levelLabel.textColor = UIColor(red: 0.15, green: 0.55, blue: 0.95, alpha: 1.0)
        levelLabel.font = UIFont.systemFont(ofSize: 11, weight: .black)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(levelLabel)
        
        // Close Button
        let closeButton = UIButton(type: .system)
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let closeIcon = UIImage(systemName: "xmark.circle.fill", withConfiguration: closeConfig)
        closeButton.setImage(closeIcon, for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.4)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeInspectionPanel), for: .touchUpInside)
        panel.addSubview(closeButton)
        
        // Detail values: Income, Capacity (Slots), HP
        let incomeLabel = UILabel()
        let currentIncome = calculateIncome(for: building)
        incomeLabel.text = "INCOME: \(currentIncome) 🪙/hr"
        incomeLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        incomeLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        incomeLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(incomeLabel)
        
        let capacityLabel = UILabel()
        capacityLabel.text = "CAPACITY: \(building.capacity) SLOT\(building.capacity > 1 ? "S" : "")"
        capacityLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        capacityLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        capacityLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(capacityLabel)
        
        // HP Progress Section
        let hpLabel = UILabel()
        hpLabel.text = "HP: \(building.currentHP)/\(building.maxHP)"
        hpLabel.textColor = UIColor.white.withAlphaComponent(0.5)
        hpLabel.font = UIFont.systemFont(ofSize: 10, weight: .semibold)
        hpLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(hpLabel)
        
        let hpProgressContainer = UIView()
        hpProgressContainer.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        hpProgressContainer.layer.cornerRadius = 3
        hpProgressContainer.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(hpProgressContainer)
        
        let hpProgressBar = UIView()
        hpProgressBar.backgroundColor = UIColor(red: 0.15, green: 0.85, blue: 0.45, alpha: 1.0)
        hpProgressBar.layer.cornerRadius = 3
        hpProgressBar.translatesAutoresizingMaskIntoConstraints = false
        hpProgressContainer.addSubview(hpProgressBar)
        
        // Upgrade button
        let upgradeButton = UIButton(type: .system)
        let upgradeCost = building.level * 5000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedCost = formatter.string(from: NSNumber(value: upgradeCost)) ?? "\(upgradeCost)"
        upgradeButton.setTitle("UPGRADE - \(formattedCost) 🪙", for: .normal)
        upgradeButton.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .black)
        upgradeButton.tintColor = .white
        upgradeButton.backgroundColor = UIColor(red: 0.15, green: 0.55, blue: 0.95, alpha: 1.0)
        upgradeButton.layer.cornerRadius = 14
        upgradeButton.layer.borderWidth = 1.0
        upgradeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        upgradeButton.translatesAutoresizingMaskIntoConstraints = false
        upgradeButton.addTarget(self, action: #selector(upgradeBuildingTapped), for: .touchUpInside)
        panel.addSubview(upgradeButton)
        
        view.addSubview(panel)
        self.inspectionPanel = panel
        
        let hpRatio = CGFloat(building.currentHP) / CGFloat(building.maxHP)
        
        NSLayoutConstraint.activate([
            panel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            panel.heightAnchor.constraint(equalToConstant: panelHeight),
            
            dragHandle.topAnchor.constraint(equalTo: panel.topAnchor, constant: 8),
            dragHandle.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 36),
            dragHandle.heightAnchor.constraint(equalToConstant: 5),
            
            emojiLabel.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 14),
            emojiLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            emojiLabel.widthAnchor.constraint(equalToConstant: 44),
            emojiLabel.heightAnchor.constraint(equalToConstant: 44),
            
            nameLabel.topAnchor.constraint(equalTo: emojiLabel.topAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
            
            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            levelLabel.leadingAnchor.constraint(equalTo: emojiLabel.trailingAnchor, constant: 12),
            
            closeButton.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
            
            incomeLabel.topAnchor.constraint(equalTo: emojiLabel.bottomAnchor, constant: 16),
            incomeLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            
            capacityLabel.topAnchor.constraint(equalTo: incomeLabel.bottomAnchor, constant: 6),
            capacityLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            
            hpLabel.topAnchor.constraint(equalTo: capacityLabel.bottomAnchor, constant: 12),
            hpLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            
            hpProgressContainer.topAnchor.constraint(equalTo: hpLabel.bottomAnchor, constant: 6),
            hpProgressContainer.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            hpProgressContainer.widthAnchor.constraint(equalToConstant: 120),
            hpProgressContainer.heightAnchor.constraint(equalToConstant: 6),
            
            hpProgressBar.leadingAnchor.constraint(equalTo: hpProgressContainer.leadingAnchor),
            hpProgressBar.topAnchor.constraint(equalTo: hpProgressContainer.topAnchor),
            hpProgressBar.bottomAnchor.constraint(equalTo: hpProgressContainer.bottomAnchor),
            hpProgressBar.widthAnchor.constraint(equalTo: hpProgressContainer.widthAnchor, multiplier: hpRatio),
            
            upgradeButton.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),
            upgradeButton.bottomAnchor.constraint(equalTo: panel.bottomAnchor, constant: -20),
            upgradeButton.widthAnchor.constraint(equalToConstant: 150),
            upgradeButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Animate slide up
        panel.transform = CGAffineTransform(translationX: 0, y: 350)
        panel.alpha = 0
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            panel.transform = .identity
            panel.alpha = 1.0
        }, completion: nil)
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    private func calculateIncome(for building: BuildingItem) -> Int {
        switch building.type {
        case .kiosk: return building.level * 250
        case .cafe: return building.level * 600
        case .bar: return building.level * 1000
        }
    }
    
    @objc private func closeInspectionPanel() {
        dismissActivePanels(animated: true)
        
        // Bring back bottomBar and location buttons
        UIView.animate(withDuration: 0.40, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.bottomBar.transform = .identity
            self.bottomBar.alpha = 1.0
            self.centerButton.transform = .identity
            self.centerButton.alpha = 1.0
            self.disconnectButton.transform = .identity
            self.disconnectButton.alpha = 1.0
        }, completion: nil)
    }
    
    @objc private func upgradeBuildingTapped() {
        guard let annotation = selectedBuildingAnnotation else { return }
        let currentLevel = annotation.buildingItem.level
        let upgradeCost = currentLevel * 5000
        
        // 1. Check funds
        if coins < upgradeCost {
            showNotificationHUD(message: "INSUFFICIENT FUNDS 🪙\nNeed \(upgradeCost) coins to upgrade!")
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        // 2. Perform upgrade
        coins -= upgradeCost
        updateStatsBarLabels()
        
        // Modify actual structure values
        annotation.buildingItem.level += 1
        annotation.buildingItem.currentHP = 100
        
        // Refresh annotation
        mapView.removeAnnotation(annotation)
        mapView.addAnnotation(annotation)
        
        // Trigger haptics
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Show success toast
        showNotificationHUD(message: "UPGRADED TO LEVEL \(currentLevel + 1) 🚀")
        
        // Re-open inspection panel to show new values!
        showBuildingInspectionPanel(for: annotation)
    }
    
    // MARK: - Premium Dynamic Notification Toast & Stats
    private func updateStatsBarLabels() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if let formattedCoins = formatter.string(from: NSNumber(value: coins)) {
            coinsLabel?.text = formattedCoins
        } else {
            coinsLabel?.text = "\(coins)"
        }
        
        gemsLabel?.text = "\(gems)"
        
        // Add a micro-animation (brief scale pop) to stats bar labels when they update
        UIView.animate(withDuration: 0.1, animations: {
            self.coinsLabel?.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.coinsLabel?.transform = .identity
            }
        }
    }
    
    private func showNotificationHUD(message: String) {
        let toast = UIView()
        toast.backgroundColor = UIColor(white: 0.12, alpha: 0.92)
        toast.layer.cornerRadius = 20
        toast.layer.borderWidth = 1.0
        toast.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        toast.addSubview(blurView)
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: toast.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: toast.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: toast.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: toast.bottomAnchor)
        ])
        
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        toast.addSubview(label)
        
        view.addSubview(toast)
        
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -100),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 180),
            toast.widthAnchor.constraint(lessThanOrEqualToConstant: 300),
            toast.heightAnchor.constraint(greaterThanOrEqualToConstant: 40),
            
            label.topAnchor.constraint(equalTo: toast.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 16),
            label.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -10)
        ])
        
        toast.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        toast.alpha = 0.0
        
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            toast.transform = .identity
            toast.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.35, delay: 1.8, options: .curveEaseIn, animations: {
                toast.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                toast.alpha = 0.0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
    }
    
    private func dismissActivePanels(animated: Bool = true) {
        if let panel = buildStorePanel {
            buildStorePanel = nil
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    panel.transform = CGAffineTransform(translationX: 0, y: 350)
                    panel.alpha = 0
                }) { _ in
                    panel.removeFromSuperview()
                }
            } else {
                panel.removeFromSuperview()
            }
        }
        
        if let panel = inspectionPanel {
            inspectionPanel = nil
            selectedBuildingAnnotation = nil
            if animated {
                UIView.animate(withDuration: 0.3, animations: {
                    panel.transform = CGAffineTransform(translationX: 0, y: 350)
                    panel.alpha = 0
                }) { _ in
                    panel.removeFromSuperview()
                }
            } else {
                panel.removeFromSuperview()
            }
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
        
        // Update the 1200-meter interactive attack range wave overlay
        if let oldAttack = attackCircle {
            mapView.removeOverlay(oldAttack)
        }
        let newAttack = MKCircle(center: coordinate, radius: 1200) // 1200m attack radius wave!
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
        
        if let buildingAnnotation = annotation as? BuildingAnnotation {
            let view = mapView.dequeueReusableAnnotationView(withIdentifier: BuildingAnnotationView.reuseID) as? BuildingAnnotationView
                ?? BuildingAnnotationView(annotation: buildingAnnotation, reuseIdentifier: BuildingAnnotationView.reuseID)
            view.annotation = buildingAnnotation
            view.configure(with: buildingAnnotation.buildingItem)
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
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let buildingAnnotation = view.annotation as? BuildingAnnotation else { return }
        mapView.deselectAnnotation(buildingAnnotation, animated: true)
        showBuildingInspectionPanel(for: buildingAnnotation)
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
            welcomeView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -160),
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
            // Auto dismiss after 2.0 seconds
            UIView.animate(withDuration: 0.40, delay: 2.00, options: .curveEaseIn, animations: {
                welcomeView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                welcomeView.alpha = 0.0
            }) { _ in
                welcomeView.removeFromSuperview()
            }
        }
    }
}
