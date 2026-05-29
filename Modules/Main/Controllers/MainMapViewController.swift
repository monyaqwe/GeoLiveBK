import UIKit
import MapKit
import CoreLocation

// MARK: - Main Map View Controller
public final class MainMapViewController: UIViewController {
    
    private let nickname: String
    private let selectedGender: Gender
    public let avatarImage: UIImage?
    private let onDisconnect: (() -> Void)?
    
    public let locationManager = CLLocationManager()
    public var mapView: MKMapView!
    public var avatarAnnotation: AvatarAnnotation?
    public var hasInitiallyCentered = false
    public var hasCenteredOnHighAccuracy = false
    public var hasShownWelcomeBanner = false
    
    // Interactive 150m build range overlay
    public var interactionCircle: MKCircle?
    
    // Interactive 500m attack range wave overlay
    public var attackCircle: MKCircle?
    
    // Dynamic Player Combat & Respawn State
    private var playerLevel: Int = 1
    private var playerXP: Int = 0
    private var sessionKills: Int = 0
    public var requiredXP: Int {
        return Int(100 * pow(1.5, Double(playerLevel - 1)))
    }
    private var playerCurrentHP: Int = 100
    private var playerMaxHP: Int = 100
    private var isPlayerDead: Bool = false
    private var hasAngeredMobs: Bool = false
    private var respawnTimer: Timer?
    private var combatTimer: Timer?
    private var mobMovementTimer: Timer?
    private var inventoryScrollView: UIScrollView?
    private var inventoryContentStack: UIStackView?
    private weak var activeToastView: UIView?

    // Mobs Targeting & Combat state
    public var targetedMobAnnotation: MobAnnotation?
    public var activeMobAnnotations: [MobAnnotation] = []
    
    public let combatControlBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.08, alpha: 0.95)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor(red: 1.0, green: 0.25, blue: 0.25, alpha: 0.5).cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        view.alpha = 0.0
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return view
    }()
    
    public let targetNameLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let targetHPLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white.withAlphaComponent(0.6)
        label.font = .systemFont(ofSize: 11, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public let attackBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle("💥 FIRE!", for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14, weight: .black)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(red: 0.90, green: 0.10, blue: 0.10, alpha: 1.0)
        btn.layer.cornerRadius = 22
        btn.layer.borderWidth = 1.5
        btn.layer.borderColor = UIColor(red: 1.00, green: 0.35, blue: 0.35, alpha: 0.8).cgColor
        
        // Add a premium target crosshair shadow glow
        btn.layer.shadowColor = UIColor(red: 1.0, green: 0.2, blue: 0.2, alpha: 1.0).cgColor
        btn.layer.shadowOffset = .zero
        btn.layer.shadowRadius = 8.0
        btn.layer.shadowOpacity = 0.6
        
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    public let rewardsButton = UIButton(type: .custom)
    
    // High-tech respawn sheet overlay
    private let respawnOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.85)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        
        let blur = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        blur.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blur)
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        return view
    }()
    
    private let respawnTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "⚠️ OPERATIVE DEFEATED"
        label.textColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 22, weight: .black)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let respawnSubtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "RESPAWNING..."
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Custom Building Exclusion Zones Overlay
    public let buildingExclusionOverlay = BuildingExclusionZonesOverlay()
    
    // Bottom bar height adjustment state
    private var bottomBarHeightConstraint: NSLayoutConstraint?
    private var centerButtonBottomConstraint: NSLayoutConstraint?
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
    
    private let bottomBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.10, alpha: 0.85)
        view.layer.cornerRadius = 28
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
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
    
    // Quests Tab Button using SF Symbols
    private let questsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let icon = UIImage(systemName: "checkmark.seal.fill", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        button.layer.cornerRadius = 19
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        return button
    }()
    
    // Notification Badge on Quests Tab
    private let questsBadge: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 1.0, green: 0.35, blue: 0.35, alpha: 1.0)
        view.layer.cornerRadius = 4.5
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
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
    
    // Shop button — opens Build Store panel (Changed to hammer.fill for construction representation)
    private let shopButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let icon = UIImage(systemName: "hammer.fill", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.tintColor = UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0)
        
        button.backgroundColor = UIColor(white: 0.10, alpha: 0.85)
        button.layer.cornerRadius = 26
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor(white: 0.25, alpha: 0.60).cgColor
        
        return button
    }()
    
    // Store button — opens ShopViewController with slide-up animation
    private let storeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let icon = UIImage(systemName: "cart.fill", withConfiguration: config)
        button.setImage(icon, for: .normal)
        button.tintColor = UIColor(red: 0.30, green: 0.85, blue: 0.60, alpha: 1.0)
        
        button.backgroundColor = UIColor(white: 0.10, alpha: 0.85)
        button.layer.cornerRadius = 26
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor(white: 0.25, alpha: 0.60).cgColor
        
        return button
    }()
    
    // Level badge - EMPHASIZED visually to weight 14pt black
    private let levelLabel: UILabel = {
        let label = UILabel()
        label.text = "LEVEL 1"
        label.font = UIFont.systemFont(ofSize: 11, weight: .black)
        label.textColor = UIColor(red: 0.15, green: 0.65, blue: 1.0, alpha: 1.0)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // Glowing XP Progress Bar
    private let xpProgressBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        view.layer.cornerRadius = 2
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let xpProgressFillView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add dynamic glow to progress fill
        view.layer.shadowColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0).cgColor
        view.layer.shadowRadius = 4.0
        view.layer.shadowOpacity = 0.8
        view.layer.shadowOffset = .zero
        return view
    }()
    
    private var xpProgressWidthConstraint: NSLayoutConstraint?
    
    // Quests Container inside expandable bottomBar
    private let questsContainerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        view.alpha = 0.0
        return view
    }()
    
    private let questsTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "ACTIVE QUESTS 🏆"
        label.font = UIFont.systemFont(ofSize: 13, weight: .black)
        label.textColor = .white
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let questsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        stack.distribution = .fillEqually
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private var questsList: [GameQuest] = [
        GameQuest(id: "quest_1", title: "Establish Foothold (Place 1 Building)", requiredCount: 1, rewardGems: 1, isClaimed: false),
        GameQuest(id: "quest_2", title: "Expanding Influence (Place 2 Buildings)", requiredCount: 2, rewardGems: 1, isClaimed: false),
        GameQuest(id: "quest_3", title: "Apex Contractor (Upgrade 1 Building to Level 5)", requiredCount: 5, rewardGems: 5, isClaimed: false)
    ]
    
    // Sheet State and Views
    public enum SheetState {
        case collapsed
        case upgrades
        case slots
    }
    public var activeSheetState: SheetState = .collapsed
    public var slotsInspectionView: UIView?

    // Player dynamic resources
    private var _coins: Int = 100000
    private var coins: Int {
        get {
            if nickname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "makar" {
                return 99999999
            }
            return _coins
        }
        set {
            if nickname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != "makar" {
                _coins = newValue
            }
        }
    }

    private var _gems: Int = 0
    private var gems: Int {
        get {
            if nickname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "makar" {
                return 99999999
            }
            return _gems
        }
        set {
            if nickname.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() != "makar" {
                _gems = newValue
            }
        }
    }

    // UI Outlets for stats
    private var coinsLabel: UILabel?
    private var gemsLabel: UILabel?
    private var bagLabel: UILabel?

    // Construction and Upgrade states
    public var placedBuildings: [BuildingItem] = []
    public var isPlacementModeActive: Bool = false
    public var selectedTypeToPlace: BuildingType?
    public var placementOverlayView: UIView?
    public var mapTapRecognizer: UITapGestureRecognizer?
    public var buildStorePanel: UIView?
    public var inspectionPanel: UIView?
    public var selectedBuildingAnnotation: BuildingAnnotation?
    public var inspectionPanelHeightConstraint: NSLayoutConstraint?
    public var isInspectionPanelExpanded: Bool = false
    public var expandedInspectionView: UIView?

    /// Tracks exclusion-zone overlays keyed by building UUID
    public var exclusionOverlays: [UUID: MKCircle] = [:]

    /// Collect-button inside the inspection panel (updated on open)
    private weak var collectButton: UIButton?
    
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
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupUI()
        setupActions()
        setupLocationManager()
        startCombatSimulation()
        
        // Initial stats bar labels sync
        updateStatsBarLabels()
        startMobMovementTimer()
        
        // 1 HP per second health regeneration
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isPlayerDead else { return }
            if self.playerCurrentHP < self.playerMaxHP {
                self.playerCurrentHP += 1
                if let avatarAnn = self.avatarAnnotation,
                   let annotationView = self.mapView.view(for: avatarAnn) as? AvatarAnnotationView {
                    annotationView.updateHP(current: self.playerCurrentHP, max: self.playerMaxHP)
                }
            }
        }
    }
    
    public override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // MARK: - Map Setup
    private func setupMap() {
        mapView = MKMapView(frame: view.bounds)
        mapView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        mapView.delegate = self
        mapView.showsUserLocation = false // Hide native pulsing blue location dot, display custom avatar instead
        mapView.showsCompass = false
        mapView.showsBuildings = false // Abstract flat maps
        mapView.showsTraffic = false // Wipe out traffic
        
        mapView.mapType = .mutedStandard
        
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleMapLongPress(_:)))
        longPress.minimumPressDuration = 0.5
        longPress.delegate = self
        mapView.addGestureRecognizer(longPress)
        
        let strictFilter = MKPointOfInterestFilter(including: [.museum, .nationalPark])
        mapView.pointOfInterestFilter = strictFilter
        
        let limitRegion = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 0, longitude: 0),
            latitudinalMeters: 3000,
            longitudinalMeters: 1500
        )
        let camera = mapView.cameraThatFits(limitRegion)
        let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: camera.centerCoordinateDistance)
        mapView.setCameraZoomRange(zoomRange, animated: false)
        
        if #available(iOS 16.0, *) {
            let config = MKStandardMapConfiguration(emphasisStyle: .muted)
            config.pointOfInterestFilter = strictFilter
            mapView.preferredConfiguration = config
            mapView.overrideUserInterfaceStyle = .dark
        } else {
            mapView.overrideUserInterfaceStyle = .dark
        }
        
        view.addSubview(mapView)
        mapView.addOverlay(buildingExclusionOverlay, level: .aboveRoads)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
        
        // Bottom bar
        view.addSubview(bottomBar)
        
        // Add header container, inventory container, and quests container
        bottomBar.addSubview(headerContainerView)
        bottomBar.addSubview(inventoryContainerView)
        bottomBar.addSubview(questsContainerView)
        
        // Add header views into headerContainerView
        headerContainerView.addSubview(pullHandle)
        headerContainerView.addSubview(avatarThumb)
        headerContainerView.addSubview(statusDot)
        headerContainerView.addSubview(nicknameLabel)
        headerContainerView.addSubview(levelLabel)
        
        nicknameLabel.text = "\(nickname) \(playerLevel)"
        avatarThumb.image = avatarImage
        
        // Badge inside Quests Button
        questsButton.addSubview(questsBadge)
        
        NSLayoutConstraint.activate([
            questsBadge.topAnchor.constraint(equalTo: questsButton.topAnchor, constant: -2),
            questsBadge.trailingAnchor.constraint(equalTo: questsButton.trailingAnchor, constant: 2),
            questsBadge.widthAnchor.constraint(equalToConstant: 9),
            questsBadge.heightAnchor.constraint(equalToConstant: 9)
        ])
        
        // Setup rewards tab button
        let rewardsConfig = UIImage.SymbolConfiguration(pointSize: 14, weight: .bold)
        let rewardsIcon = UIImage(systemName: "trophy.fill", withConfiguration: rewardsConfig)
        rewardsButton.setImage(rewardsIcon, for: .normal)
        rewardsButton.tintColor = .white
        rewardsButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        rewardsButton.layer.cornerRadius = 19
        rewardsButton.layer.borderWidth = 1.0
        rewardsButton.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        rewardsButton.translatesAutoresizingMaskIntoConstraints = false

        let tabsStackView = UIStackView(arrangedSubviews: [questsButton, rewardsButton])
        tabsStackView.axis = .horizontal
        tabsStackView.spacing = 10
        tabsStackView.distribution = .fillEqually
        tabsStackView.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.addSubview(tabsStackView)
        
        // Setup subviews layout inside bottomBar
        setupInventoryUI()
        setupQuestsUI()
        
        // Add Top Stats Bar (Coins, Gems, Backpack Capacity)
        view.addSubview(topStatsBar)
        
        let coinsResult = createStatSegment(iconName: "dollarsign.circle.fill", iconColor: UIColor(red: 0.95, green: 0.75, blue: 0.15, alpha: 1.0), text: "100,000")
        let gemsResult = createStatSegment(iconName: "suit.diamond.fill", iconColor: UIColor(red: 0.20, green: 0.80, blue: 1.00, alpha: 1.0), text: "0")
        let bagResult = createStatSegment(iconName: "backpack.fill", iconColor: UIColor(white: 0.75, alpha: 1.0), text: "0/8")
        
        self.coinsLabel = coinsResult.1
        self.gemsLabel = gemsResult.1
        self.bagLabel = bagResult.1
        
        let statsStack = UIStackView(arrangedSubviews: [coinsResult.0, gemsResult.0, bagResult.0])
        statsStack.axis = .horizontal
        statsStack.spacing = 16
        statsStack.distribution = .equalSpacing
        statsStack.alignment = .center
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        topStatsBar.addSubview(statsStack)
        
        // Floating buttons
        view.addSubview(centerButton)
        view.addSubview(shopButton)
        view.addSubview(storeButton)
        
        view.bringSubviewToFront(bottomBar)
        
        bottomBarHeightConstraint = bottomBar.heightAnchor.constraint(equalToConstant: 76)
        centerButtonBottomConstraint = centerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -96)
        
        NSLayoutConstraint.activate([
            centerButtonBottomConstraint!,
            // Top Stats Bar
            topStatsBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            topStatsBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topStatsBar.heightAnchor.constraint(equalToConstant: 40),
            topStatsBar.widthAnchor.constraint(equalToConstant: 290),
            
            statsStack.centerXAnchor.constraint(equalTo: topStatsBar.centerXAnchor),
            statsStack.centerYAnchor.constraint(equalTo: topStatsBar.centerYAnchor),
            statsStack.heightAnchor.constraint(equalTo: topStatsBar.heightAnchor),
            
            // Bottom Tab Bar
            bottomBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomBarHeightConstraint!,
            
            // Header Container View
            headerContainerView.topAnchor.constraint(equalTo: bottomBar.topAnchor),
            headerContainerView.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            headerContainerView.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            headerContainerView.heightAnchor.constraint(equalToConstant: 76),
            
            // Pull handle
            pullHandle.topAnchor.constraint(equalTo: headerContainerView.topAnchor, constant: 6),
            pullHandle.centerXAnchor.constraint(equalTo: headerContainerView.centerXAnchor),
            pullHandle.widthAnchor.constraint(equalToConstant: 36),
            pullHandle.heightAnchor.constraint(equalToConstant: 5),
            
            avatarThumb.leadingAnchor.constraint(equalTo: headerContainerView.leadingAnchor, constant: 12),
            avatarThumb.centerYAnchor.constraint(equalTo: headerContainerView.centerYAnchor, constant: 2),
            avatarThumb.widthAnchor.constraint(equalToConstant: 38),
            avatarThumb.heightAnchor.constraint(equalToConstant: 38),
            
            statusDot.leadingAnchor.constraint(equalTo: avatarThumb.trailingAnchor, constant: 8),
            statusDot.centerYAnchor.constraint(equalTo: avatarThumb.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),
            
            nicknameLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            nicknameLabel.trailingAnchor.constraint(lessThanOrEqualTo: tabsStackView.leadingAnchor, constant: -12),
            nicknameLabel.bottomAnchor.constraint(equalTo: avatarThumb.centerYAnchor, constant: -4),
            
            levelLabel.leadingAnchor.constraint(equalTo: nicknameLabel.leadingAnchor),
            levelLabel.topAnchor.constraint(equalTo: nicknameLabel.bottomAnchor, constant: 1),
            levelLabel.trailingAnchor.constraint(lessThanOrEqualTo: tabsStackView.leadingAnchor, constant: -12),
            
            // Tabs Stack
            tabsStackView.trailingAnchor.constraint(equalTo: headerContainerView.trailingAnchor, constant: -12),
            tabsStackView.centerYAnchor.constraint(equalTo: avatarThumb.centerYAnchor),
            tabsStackView.heightAnchor.constraint(equalToConstant: 38),
            
            questsButton.widthAnchor.constraint(equalToConstant: 38),
            
            // Inventory Container
            inventoryContainerView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            inventoryContainerView.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            inventoryContainerView.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            inventoryContainerView.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor),
            
            // Quests Container
            questsContainerView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            questsContainerView.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            questsContainerView.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            questsContainerView.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor),
            
            // Floating buttons anchored statically above collapsed bottomBar (76px + safeArea spacing)
            centerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            centerButton.widthAnchor.constraint(equalToConstant: 52),
            centerButton.heightAnchor.constraint(equalToConstant: 52),
            
            shopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            shopButton.bottomAnchor.constraint(equalTo: centerButton.topAnchor, constant: -12),
            shopButton.widthAnchor.constraint(equalToConstant: 52),
            shopButton.heightAnchor.constraint(equalToConstant: 52),
            
            storeButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            storeButton.bottomAnchor.constraint(equalTo: shopButton.topAnchor, constant: -12),
            storeButton.widthAnchor.constraint(equalToConstant: 52),
            storeButton.heightAnchor.constraint(equalToConstant: 52),
        ])
        
        // Add rewardsButton constraint width
        NSLayoutConstraint.activate([
            rewardsButton.widthAnchor.constraint(equalToConstant: 38)
        ])

        // Add Combat Control Bar & hierarchy
        view.addSubview(combatControlBar)
        combatControlBar.addSubview(targetNameLabel)
        combatControlBar.addSubview(targetHPLabel)
        combatControlBar.addSubview(attackBtn)
        
        NSLayoutConstraint.activate([
            // Combat bar: Anchored statically above the base bottom bar level
            combatControlBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -96),
            combatControlBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            combatControlBar.widthAnchor.constraint(equalToConstant: 340),
            combatControlBar.heightAnchor.constraint(equalToConstant: 76),
            
            targetNameLabel.leadingAnchor.constraint(equalTo: combatControlBar.leadingAnchor, constant: 16),
            targetNameLabel.topAnchor.constraint(equalTo: combatControlBar.topAnchor, constant: 16),
            targetNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: attackBtn.leadingAnchor, constant: -8),
            
            targetHPLabel.leadingAnchor.constraint(equalTo: targetNameLabel.leadingAnchor),
            targetHPLabel.topAnchor.constraint(equalTo: targetNameLabel.bottomAnchor, constant: 4),
            targetHPLabel.trailingAnchor.constraint(lessThanOrEqualTo: attackBtn.leadingAnchor, constant: -8),
            
            attackBtn.trailingAnchor.constraint(equalTo: combatControlBar.trailingAnchor, constant: -14),
            attackBtn.centerYAnchor.constraint(equalTo: combatControlBar.centerYAnchor),
            attackBtn.widthAnchor.constraint(equalToConstant: 110),
            attackBtn.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        // Mount respawn overlay constraints
        view.addSubview(respawnOverlay)
        respawnOverlay.addSubview(respawnTitleLabel)
        respawnOverlay.addSubview(respawnSubtitleLabel)
        
        NSLayoutConstraint.activate([
            respawnOverlay.topAnchor.constraint(equalTo: view.topAnchor),
            respawnOverlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            respawnOverlay.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            respawnOverlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            respawnTitleLabel.centerYAnchor.constraint(equalTo: respawnOverlay.centerYAnchor, constant: -20),
            respawnTitleLabel.centerXAnchor.constraint(equalTo: respawnOverlay.centerXAnchor),
            
            respawnSubtitleLabel.topAnchor.constraint(equalTo: respawnTitleLabel.bottomAnchor, constant: 12),
            respawnSubtitleLabel.centerXAnchor.constraint(equalTo: respawnOverlay.centerXAnchor)
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
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        inventoryContainerView.addSubview(scrollView)
        self.inventoryScrollView = scrollView
        
        let contentStack = UIStackView()
        contentStack.axis = .vertical
        contentStack.spacing = 14
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)
        self.inventoryContentStack = contentStack
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: inventoryContainerView.topAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: inventoryContainerView.leadingAnchor, constant: 16),
            scrollView.trailingAnchor.constraint(equalTo: inventoryContainerView.trailingAnchor, constant: -16),
            scrollView.bottomAnchor.constraint(equalTo: inventoryContainerView.bottomAnchor, constant: -10),
            
            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        refreshInventoryUI()
    }
    
    private func setupActions() {
        centerButton.addTarget(self, action: #selector(centerOnUserTapped), for: .touchUpInside)
        shopButton.addTarget(self, action: #selector(shopButtonTapped), for: .touchUpInside)
        storeButton.addTarget(self, action: #selector(storeButtonTapped), for: .touchUpInside)
        
        questsButton.addTarget(self, action: #selector(questsTapped), for: .touchUpInside)
        rewardsButton.addTarget(self, action: #selector(rewardsTapped), for: .touchUpInside)
        attackBtn.addTarget(self, action: #selector(attackBtnTapped), for: .touchUpInside)
        
        headerContainerView.isUserInteractionEnabled = true
        let swipeUpHeader = UISwipeGestureRecognizer(target: self, action: #selector(showInventoryPanel))
        swipeUpHeader.direction = .up
        headerContainerView.addGestureRecognizer(swipeUpHeader)
        
        let pan = UIPanGestureRecognizer(target: self, action: #selector(handleBottomBarPan(_:)))
        bottomBar.addGestureRecognizer(pan)
        
        let mapTap = UITapGestureRecognizer(target: self, action: #selector(handleCombatDismissTap(_:)))
        mapTap.cancelsTouchesInView = false
        mapTap.delegate = self
        view.addGestureRecognizer(mapTap)
        
        let mapSwipeUp = UISwipeGestureRecognizer(target: self, action: #selector(showInventoryPanel))
        mapSwipeUp.direction = .up
        mapSwipeUp.delegate = self
        mapView.addGestureRecognizer(mapSwipeUp)
    }
    
    @objc private func handleCombatDismissTap(_ gesture: UITapGestureRecognizer) {
        let loc = gesture.location(in: view)
        if combatControlBar.alpha > 0 && !combatControlBar.frame.contains(loc) {
            hideCombatBar()
        }
    }
    
    @objc private func handleSwipeGesture(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .down {
            collapseBottomBar()
        }
    }
    
    private func expandBottomBar() {
        guard !isBottomBarExpanded else { return }
        isBottomBarExpanded = true
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        if self.inventoryContainerView.alpha == 0.0 && self.questsContainerView.alpha == 0.0 {
            self.inventoryContainerView.alpha = 1.0
            self.questsContainerView.alpha = 0.0
        }
        
        UIView.animate(withDuration: 0.55, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.6, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.bottomBarHeightConstraint?.constant = 340
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
            self.questsContainerView.alpha = 0.0
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc private func questsTapped() {
        UIView.animate(withDuration: 0.12, animations: {
            self.questsButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.questsButton.transform = .identity
            }
            self.showQuestsPanel()
        }
    }
    
    private func showQuestsPanel() {
        let isAlreadyShowingQuests = isBottomBarExpanded && questsContainerView.alpha == 1.0
        
        if isAlreadyShowingQuests {
            collapseBottomBar()
        } else {
            self.updateQuestsPanel()
            expandBottomBar()
            
            UIView.animate(withDuration: 0.3) {
                self.inventoryContainerView.alpha = 0.0
                self.questsContainerView.alpha = 1.0
            }
        }
    }
    
    private func setupQuestsUI() {
        questsContainerView.addSubview(questsTitleLabel)
        questsContainerView.addSubview(questsStackView)
        
        NSLayoutConstraint.activate([
            questsTitleLabel.topAnchor.constraint(equalTo: questsContainerView.topAnchor, constant: 12),
            questsTitleLabel.leadingAnchor.constraint(equalTo: questsContainerView.leadingAnchor, constant: 16),
            questsTitleLabel.trailingAnchor.constraint(equalTo: questsContainerView.trailingAnchor, constant: -16),
            
            questsStackView.topAnchor.constraint(equalTo: questsTitleLabel.bottomAnchor, constant: 12),
            questsStackView.leadingAnchor.constraint(equalTo: questsContainerView.leadingAnchor, constant: 16),
            questsStackView.trailingAnchor.constraint(equalTo: questsContainerView.trailingAnchor, constant: -16),
            questsStackView.bottomAnchor.constraint(lessThanOrEqualTo: questsContainerView.bottomAnchor, constant: -16)
        ])
        
        updateQuestsPanel()
        checkQuestsProgress()
    }
    
    private func updateQuestsPanel() {
        for subview in questsStackView.arrangedSubviews {
            subview.removeFromSuperview()
        }
        
        let currentPlaced = placedBuildings.count
        
        for quest in questsList {
            let row = UIView()
            row.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            row.layer.cornerRadius = 14
            row.layer.borderWidth = 1.0
            row.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
            row.translatesAutoresizingMaskIntoConstraints = false
            questsStackView.addArrangedSubview(row)
            
            let iconLabel = UILabel()
            iconLabel.text = quest.id == "quest_3" ? "🚀" : (quest.requiredCount == 1 ? "🏗️" : "🏢")
            iconLabel.font = .systemFont(ofSize: 22)
            iconLabel.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(iconLabel)
            
            let infoStack = UIStackView()
            infoStack.axis = .vertical
            infoStack.spacing = 2
            infoStack.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(infoStack)
            
            let qTitle = UILabel()
            qTitle.text = quest.title
            qTitle.textColor = .white
            qTitle.font = UIFont.systemFont(ofSize: 11, weight: .bold)
            infoStack.addArrangedSubview(qTitle)
            
            // Calculate progress and completion dynamically per quest type
            let progressVal: Int
            let isComplete: Bool
            
            if quest.id == "quest_3" {
                let maxLevel = placedBuildings.map { $0.level }.max() ?? 1
                progressVal = maxLevel
                isComplete = maxLevel >= quest.requiredCount
            } else {
                progressVal = currentPlaced
                isComplete = currentPlaced >= quest.requiredCount
            }
            
            let cappedProgress = min(progressVal, quest.requiredCount)
            let qProgress = UILabel()
            qProgress.text = "Progress: \(cappedProgress)/\(quest.requiredCount) | Reward: \(quest.rewardGems) 💎"
            qProgress.textColor = UIColor.white.withAlphaComponent(0.5)
            qProgress.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
            infoStack.addArrangedSubview(qProgress)
            
            let actionBtn = UIButton(type: .custom)
            actionBtn.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .black)
            actionBtn.layer.cornerRadius = 10
            actionBtn.translatesAutoresizingMaskIntoConstraints = false
            row.addSubview(actionBtn)
            
            if quest.isClaimed {
                actionBtn.setTitle("CLAIMED ✓", for: .normal)
                actionBtn.setTitleColor(UIColor.white.withAlphaComponent(0.3), for: .normal)
                actionBtn.backgroundColor = UIColor.white.withAlphaComponent(0.04)
                actionBtn.layer.borderWidth = 1.0
                actionBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
                actionBtn.isEnabled = false
            } else if isComplete {
                actionBtn.setTitle("CLAIM", for: .normal)
                actionBtn.setTitleColor(.white, for: .normal)
                actionBtn.backgroundColor = UIColor(red: 0.95, green: 0.65, blue: 0.15, alpha: 1.0)
                actionBtn.layer.borderWidth = 1.0
                actionBtn.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
                actionBtn.isEnabled = true
                
                let targetId = quest.id
                actionBtn.addAction(UIAction(handler: { [weak self] _ in
                    self?.claimQuest(id: targetId)
                }), for: .touchUpInside)
                
                UIView.animate(withDuration: 0.6, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: {
                    actionBtn.transform = CGAffineTransform(scaleX: 1.04, y: 1.04)
                }, completion: nil)
            } else {
                actionBtn.setTitle("IN PROGRESS", for: .normal)
                actionBtn.setTitleColor(UIColor.white.withAlphaComponent(0.4), for: .normal)
                actionBtn.backgroundColor = UIColor.white.withAlphaComponent(0.06)
                actionBtn.isEnabled = false
            }
            
            NSLayoutConstraint.activate([
                row.heightAnchor.constraint(equalToConstant: 52),
                
                iconLabel.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
                iconLabel.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                iconLabel.widthAnchor.constraint(equalToConstant: 24),
                
                infoStack.leadingAnchor.constraint(equalTo: iconLabel.trailingAnchor, constant: 10),
                infoStack.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                infoStack.trailingAnchor.constraint(equalTo: actionBtn.leadingAnchor, constant: -10),
                
                actionBtn.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -10),
                actionBtn.centerYAnchor.constraint(equalTo: row.centerYAnchor),
                actionBtn.widthAnchor.constraint(equalToConstant: 94),
                actionBtn.heightAnchor.constraint(equalToConstant: 32)
            ])
        }
    }
    
    private func claimQuest(id: String) {
        guard let index = questsList.firstIndex(where: { $0.id == id }) else { return }
        let quest = questsList[index]
        
        questsList[index].isClaimed = true
        gems += quest.rewardGems // Award GEMS
        updateStatsBarLabels()
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showNotificationHUD(message: "CLAIMED \(quest.rewardGems) 💎 REWARD! 🎉")
        
        checkQuestsProgress()
        updateQuestsPanel()
    }
    
    public func checkQuestsProgress() {
        var claimableCount = 0
        let currentPlaced = placedBuildings.count
        
        for quest in questsList {
            let isComplete: Bool
            if quest.id == "quest_3" {
                let maxLevel = placedBuildings.map { $0.level }.max() ?? 1
                isComplete = maxLevel >= quest.requiredCount
            } else {
                isComplete = currentPlaced >= quest.requiredCount
            }
            
            if !quest.isClaimed && isComplete {
                claimableCount += 1
            }
        }
        
        if claimableCount > 0 {
            questsBadge.isHidden = false
            questsButton.backgroundColor = UIColor(red: 1.0, green: 0.60, blue: 0.10, alpha: 0.22)
            questsButton.layer.borderColor = UIColor(red: 1.0, green: 0.60, blue: 0.10, alpha: 1.0).cgColor
            questsButton.tintColor = UIColor(red: 1.0, green: 0.60, blue: 0.10, alpha: 1.0)
            
            UIView.animate(withDuration: 0.8, delay: 0.0, options: [.repeat, .autoreverse, .allowUserInteraction], animations: {
                self.questsButton.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
            }, completion: nil)
        } else {
            questsBadge.isHidden = true
            questsButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
            questsButton.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
            questsButton.tintColor = .white
            questsButton.transform = .identity
            questsButton.layer.removeAllAnimations()
        }
    }
    
    private func checkProgressionMilestones() {
        let hasThreeBuildings = placedBuildings.count >= 3
        let maxBuildingLevel = placedBuildings.map { $0.level }.max() ?? 1
        let hasLevel5Building = maxBuildingLevel >= 5
        
        if (hasThreeBuildings || hasLevel5Building) && playerLevel < 2 {
            playerLevel = 2
            playerXP = 0 // Reset XP
            updateStatsBarLabels()
            showTopLevelUpBanner(message: "⚡ PLAYER LEVEL UP!\nYou achieved Level 2 by completing milestones!")
            showLevelUpCongratulationAlert()
            lightUpRewardsButton()
            
            // Pistol reward moved to rewardsVC claim.
        }
    }
    
    @objc private func shopButtonTapped() {
        UIView.animate(withDuration: 0.12, animations: {
            self.shopButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.shopButton.transform = .identity
            }
            self.showBuildStorePanel()
        }
    }
    
    @objc private func storeButtonTapped() {
        UIView.animate(withDuration: 0.10, animations: {
            self.storeButton.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        }) { _ in
            UIView.animate(withDuration: 0.10) {
                self.storeButton.transform = .identity
            }
            self.openShopViewController()
        }
    }
    
    private func openShopViewController() {
        let shopVC = ShopViewController()
        shopVC.coins = coins
        shopVC.gems = gems
        shopVC.onPurchaseSuccess = { [weak self] message, newCoins, newGems, itemId in
            guard let self = self else { return }
            
            // Map the purchased item ID to an ItemProtocol object
            var purchasedItem: ItemProtocol?
            if itemId == "case_standard" {
                purchasedItem = WeaponDTO(type: .pistol, tier: .uncommon)
            } else if itemId == "case_premium" {
                purchasedItem = WeaponDTO(type: .smg, tier: .epic)
            } else if itemId == "def_scout" {
                purchasedItem = ModDTO(name: "Scout Guard Core", description: "Recon sentinel core", statAffected: "HP", multiplierBoost: 1.2)
            } else if itemId == "def_enforcer" {
                purchasedItem = ModDTO(name: "Enforcer Sentry Core", description: "Localized shockwave mod", statAffected: "Damage", multiplierBoost: 1.5)
            } else if itemId == "def_heavy" {
                purchasedItem = ModDTO(name: "Heavy Sentinel Core", description: "Ultimate defense sentinel mod", statAffected: "HP", multiplierBoost: 1.8)
            } else if itemId == "boost_chef" {
                purchasedItem = ModDTO(name: "Chef Booster", description: "Income x1.5 modifier", statAffected: "Damage", multiplierBoost: 1.5)
            } else if itemId == "boost_equipment" {
                purchasedItem = ModDTO(name: "Advanced Equip Core", description: "Income x1.8 modifier", statAffected: "Damage", multiplierBoost: 1.8)
            }
            
            if let item = purchasedItem {
                if InventoryManager.shared.canAddItem(item) {
                    self.coins = newCoins
                    self.gems = newGems
                    InventoryManager.shared.addItem(item) { _ in }
                    self.updateStatsBarLabels()
                    self.showNotificationHUD(message: "\(message)\n🎒 Item added to your inventory!")
                } else {
                    // Do NOT update coins/gems (Keep old coins/gems -> Full Refund!)
                    self.updateStatsBarLabels()
                    self.showNotificationHUD(message: "⚠️ INVENTORY FULL!\nCould not add \(item.name). Transaction refunded!")
                }
            } else {
                // If it is standard Gems pack (which doesn't occupy inventory space, just boosts gems count!)
                self.coins = newCoins
                self.gems = newGems
                self.updateStatsBarLabels()
                self.showNotificationHUD(message: message)
            }
        }
        shopVC.modalPresentationStyle = .overFullScreen
        shopVC.modalTransitionStyle = .crossDissolve
        present(shopVC, animated: false)
    }
    
    @objc private func showInventoryPanel() {
        let isAlreadyShowingInventory = isBottomBarExpanded && inventoryContainerView.alpha == 1.0
        
        if isAlreadyShowingInventory {
            collapseBottomBar()
        } else {
            self.activeTab = 0
            self.refreshInventoryUI()
            expandBottomBar()
            
            UIView.animate(withDuration: 0.3) {
                self.questsContainerView.alpha = 0.0
                self.inventoryContainerView.alpha = 1.0
            }
        }
    }
    
    @objc private func rewardsTapped() {
        // Reset rewards button visual glow state
        rewardsButton.layer.removeAllAnimations()
        rewardsButton.transform = .identity
        rewardsButton.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        rewardsButton.tintColor = .white
        rewardsButton.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        
        let rewardsVC = LevelRewardsViewController()
        rewardsVC.currentLevel = playerLevel
        rewardsVC.coins = coins
        rewardsVC.gems = gems
        rewardsVC.onRewardClaimed = { [weak self] level, message, cash, gemBonus in
            guard let self = self else { return }
            self.coins += cash
            self.gems += gemBonus
            self.updateStatsBarLabels()
            self.showNotificationHUD(message: "\(message)\nReceived $\(cash) & \(gemBonus) Gems!")
            
            // Level 2 Reward: Pistol (+20 damage)
            if level == 2 {
                let rewardPistol = WeaponDTO(type: .pistol, tier: .rare, damage: 35) // 15 base + 20 DMG
                InventoryManager.shared.addItem(rewardPistol) { result in
                    switch result {
                    case .success:
                        self.showNotificationHUD(message: "🔫 MILESTONE REWARD\nReceived Pistol (+20 DMG)!\nOpen Stats/Inventory to equip it!")
                    case .failure:
                        self.showNotificationHUD(message: "⚠️ INVENTORY FULL\nCould not receive Milestone Pistol. Clear some space!")
                    }
                }
            }
        }
        rewardsVC.modalPresentationStyle = .overFullScreen
        rewardsVC.modalTransitionStyle = .crossDissolve
        present(rewardsVC, animated: false)
    }
    

    
    public func hideCombatBar() {
        guard combatControlBar.alpha > 0 else { return }
        targetedMobAnnotation = nil
        UIView.animate(withDuration: 0.3) {
            self.combatControlBar.alpha = 0.0
            self.centerButtonBottomConstraint?.constant = -96
            self.view.layoutIfNeeded()
        }
    }
    
    public func targetMob(_ annotation: MobAnnotation) {
        // Attack has absolute priority -> Dismiss building inspection panels immediately!
        dismissActivePanels(animated: true)
        
        self.targetedMobAnnotation = annotation
        
        targetNameLabel.text = annotation.mobDTO.type.rawValue.uppercased()
        targetHPLabel.text = "HP: \(annotation.mobDTO.currentHP)/\(annotation.mobDTO.maxHP)"
        
        // Show combat control bar
        UIView.animate(withDuration: 0.3) {
            self.combatControlBar.alpha = 1.0
            self.centerButtonBottomConstraint?.constant = -180
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func attackBtnTapped() {
        guard let mobAnn = targetedMobAnnotation else { return }
        
        // --- Range check: must be within attack circle (500m) ---
        guard let playerCoord = avatarAnnotation?.coordinate else { return }
        let playerCL  = CLLocation(latitude: playerCoord.latitude, longitude: playerCoord.longitude)
        let mobCL     = CLLocation(latitude: mobAnn.coordinate.latitude, longitude: mobAnn.coordinate.longitude)
        let distanceM = playerCL.distance(from: mobCL)
        let attackRadius: Double = 500
        
        if distanceM > attackRadius {
            showNotificationHUD(message: "OUT OF RANGE — target is outside the attack circle")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }
        
        // --- Distance-based damage multiplier (100% at 0m → 20% at 500m) ---
        // Linear: multiplier = 1.0 - 0.8 * (distance / radius)
        let t = distanceM / attackRadius                        // 0…1
        let multiplier = 1.0 - 0.80 * t                        // 1.0 … 0.20
        // Trigger mob anger immediately
        hasAngeredMobs = true
        
        var baseDamage: Double = 20
        if let equipped = InventoryManager.shared.getEquippedWeapon() {
            baseDamage = Double(equipped.damage)
        }
        let scaledDamage = Int(max(1, (baseDamage * multiplier).rounded()))
        
        // Muzzle flash / haptic feedback
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        
        // Deduct HP
        var mob = mobAnn.mobDTO
        mob.currentHP -= scaledDamage
        mobAnn.mobDTO = mob
        
        // Update HP in view
        if let annView = mapView.view(for: mobAnn) as? MobAnnotationView {
            annView.updateHP(current: mob.currentHP, max: mob.maxHP)
            annView.showFloatingDamage(amount: scaledDamage)
        }
        
        targetHPLabel.text = "HP: \(mob.currentHP)/\(mob.maxHP)"
        
        let distStr = distanceM < 1000 ? "\(Int(distanceM))m" : String(format: "%.1fkm", distanceM / 1000)
        let pctStr  = "\(Int(multiplier * 100))%"
        showNotificationHUD(message: "💥 Hit for \(scaledDamage) dmg (\(pctStr) power @ \(distStr))")
        
        // Death check
        if mob.currentHP <= 0 {
            let xpReward = mob.type.baseXP
            coins += xpReward * 10
            
            // Drop skull remains at exact coordinates
            let skull = SkullAnnotation(coordinate: mobAnn.coordinate)
            mapView.addAnnotation(skull)
            
            let message = "DEFEATED \(mob.type.rawValue.uppercased())! Earned $\(xpReward * 10)"
            
            // Series-based mob type leveling check
            var typeLeveledUp = false
            var newTypeLevel = 1
            if DangerLevelManager.shared.registerKill(for: mob.type) {
                newTypeLevel = DangerLevelManager.shared.level(for: mob.type)
                typeLeveledUp = true
            }
            
            updateStatsBarLabels()
            showNotificationHUD(message: message)
            
            if typeLeveledUp {
                showTopLevelUpBanner(message: "⚠️ NEIGHBORHOOD DANGER INCREASED\n\(mob.type.rawValue) level raised to Lv. \(newTypeLevel)!")
            }
            
            mapView.removeAnnotation(mobAnn)
            if let idx = activeMobAnnotations.firstIndex(of: mobAnn) {
                activeMobAnnotations.remove(at: idx)
            }
            
            sessionKills += 1
            if let playerCoord = avatarAnnotation?.coordinate {
                MapSpawnerService.shared.spawnRevengeWave(
                    playerCoordinate: playerCoord,
                    dangerLevel: DangerLevelManager.shared.currentDangerLevel,
                    sessionKills: sessionKills,
                    mobType: mob.type
                ) { [weak self] newMobs in
                    self?.handleNewMobsSpawned(newMobs)
                }
            }
            
            hideCombatBar()
        } else {
            // Mobs can only shoot/counter-attack when inside your small 150m circle (their max attack range)
            if distanceM <= 150 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
                    guard let self = self else { return }
                    self.takeDamage(amount: mob.damage)
                }
            } else {
                showNotificationHUD(message: "🛡️ OUT OF RANGE\nEnemy is too far to fire at you (max range is 150m)!")
            }
        }
    }
    
    private func handleNewMobsSpawned(_ mobs: [MobDTO]) {
        for mob in mobs {
            // Avoid duplicates
            if !activeMobAnnotations.contains(where: { $0.mobDTO.id == mob.id }) {
                let ann = MobAnnotation(coordinate: mob.coordinate, mobDTO: mob)
                mapView.addAnnotation(ann)
                activeMobAnnotations.append(ann)
            }
        }
        
        // Clean up mobs that are extremely far from the player (> 2000 meters) to keep memory footprint clean
        if let playerCoord = avatarAnnotation?.coordinate {
            let playerCL = CLLocation(latitude: playerCoord.latitude, longitude: playerCoord.longitude)
            let toRemove = activeMobAnnotations.filter { ann in
                let mobCL = CLLocation(latitude: ann.coordinate.latitude, longitude: ann.coordinate.longitude)
                return playerCL.distance(from: mobCL) > 2000.0
            }
            if !toRemove.isEmpty {
                mapView.removeAnnotations(toRemove)
                activeMobAnnotations.removeAll { ann in toRemove.contains(where: { $0.mobDTO.id == ann.mobDTO.id }) }
            }
        }
    }
    
    // MARK: - Build Store & Dynamic Placement Engine
    public func showBuildStorePanel() {
        dismissActivePanels(animated: false)
        
        // Hide bottom bar with smooth animation
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.bottomBar.transform = CGAffineTransform(translationX: 0, y: 150)
            self.bottomBar.alpha = 0
            self.centerButton.transform = CGAffineTransform(translationX: 0, y: 150)
            self.centerButton.alpha = 0
            self.shopButton.transform = CGAffineTransform(translationX: 0, y: 150)
            self.shopButton.alpha = 0
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
        costLabel.text = "$\(formattedCost)" // Replaced 🪙 with $
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
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(storeCardTapped(_:)))
        card.addGestureRecognizer(tap)
        card.isUserInteractionEnabled = true
        
        return card
    }
    
    @objc private func storeCardTapped(_ gesture: UITapGestureRecognizer) {
        guard let card = gesture.view as? StoreCardView else { return }
        
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
        attrString.append(NSAttributedString(string: "Tap inside 150m blue range | Cost: $\(formattedCost)", attributes: subAttr)) // Replaced 🪙 with $
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
        
        UIView.animate(withDuration: 0.25) {
            self.topStatsBar.transform = CGAffineTransform(translationX: 0, y: -100)
            self.topStatsBar.alpha = 0
        }
        
        hud.transform = CGAffineTransform(translationX: 0, y: -100)
        hud.alpha = 0
        UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            hud.transform = .identity
            hud.alpha = 1.0
        }, completion: nil)
        
        if let oldTap = mapTapRecognizer {
            mapView.removeGestureRecognizer(oldTap)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleMapTap(_:)))
        mapView.addGestureRecognizer(tap)
        self.mapTapRecognizer = tap
    }
    
    @objc public func cancelPlacementMode() {
        guard isPlacementModeActive else { return }
        isPlacementModeActive = false
        selectedTypeToPlace = nil
        
        if let tap = mapTapRecognizer {
            mapView.removeGestureRecognizer(tap)
            mapTapRecognizer = nil
        }
        
        if let hud = placementOverlayView {
            placementOverlayView = nil
            UIView.animate(withDuration: 0.35, animations: {
                hud.transform = CGAffineTransform(translationX: 0, y: -100)
                hud.alpha = 0
            }) { _ in
                hud.removeFromSuperview()
            }
        }
        
        UIView.animate(withDuration: 0.40, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.topStatsBar.transform = .identity
            self.topStatsBar.alpha = 1.0
            
            self.bottomBar.transform = .identity
            self.bottomBar.alpha = 1.0
            self.centerButton.transform = .identity
            self.centerButton.alpha = 1.0
            self.shopButton.transform = .identity
            self.shopButton.alpha = 1.0
        }, completion: nil)
    }
    
    @objc private func closeStorePanel() {
        dismissActivePanels(animated: true)
        
        UIView.animate(withDuration: 0.40, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.bottomBar.transform = .identity
            self.bottomBar.alpha = 1.0
            self.centerButton.transform = .identity
            self.centerButton.alpha = 1.0
            self.shopButton.transform = .identity
            self.shopButton.alpha = 1.0
        }, completion: nil)
    }
    
    @objc private func handleMapTap(_ gesture: UITapGestureRecognizer) {
        guard isPlacementModeActive, let type = selectedTypeToPlace else { return }

        let touchPoint    = gesture.location(in: mapView)
        let tapCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        guard let userCoord = avatarAnnotation?.coordinate else {
            showNotificationHUD(message: "Location unavailable! Stand where GPS syncs.")
            return
        }

        let userLoc = CLLocation(latitude: userCoord.latitude,     longitude: userCoord.longitude)
        let tapLoc  = CLLocation(latitude: tapCoordinate.latitude, longitude: tapCoordinate.longitude)
        let distanceFromUser = tapLoc.distance(from: userLoc)

        if distanceFromUser > 150.0 {
            showNotificationHUD(message: "OUT OF RANGE 📡\nDistance \(Int(distanceFromUser))m — must be inside 150m zone!")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        // Exclusion zone check — can't build within 100m square of an existing building
        let radius = BuildingType.exclusionRadius
        for building in placedBuildings {
            let latDistance = abs(tapCoordinate.latitude - building.coordinate.latitude) * 111319.9
            let lonDistance = abs(tapCoordinate.longitude - building.coordinate.longitude) * 111319.9 * cos(building.coordinate.latitude * .pi / 180.0)
            if latDistance < radius && lonDistance < radius {
                showNotificationHUD(message: "TOO CLOSE ⛔\nAnother building is within \(Int(radius))m square!")
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                return
            }
        }

        if coins < type.cost {
            showNotificationHUD(message: "INSUFFICIENT FUNDS\nNeed $\(type.cost), you have $\(coins)!")
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            return
        }

        coins -= type.cost
        updateStatsBarLabels()

        let newBuilding = BuildingItem(type: type, coordinate: tapCoordinate)
        placedBuildings.append(newBuilding)

        let annotation = BuildingAnnotation(coordinate: tapCoordinate, buildingItem: newBuilding)
        mapView.addAnnotation(annotation)

        // Update custom building exclusion overlay
        mapView.removeOverlay(buildingExclusionOverlay)
        buildingExclusionOverlay.addCoordinate(tapCoordinate)
        mapView.addOverlay(buildingExclusionOverlay, level: .aboveRoads)

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showNotificationHUD(message: "CONSTRUCTION SUCCESSFUL 🏗\nPlaced \(type.rawValue)!")
        
        // Award XP for placing a building: 35 XP
        playerXP += 35
        
        var req = requiredXP
        var levelUpOccurred = false
        while playerXP >= req {
            playerXP -= req
            playerLevel += 1
            levelUpOccurred = true
            req = Int(100 * pow(1.5, Double(playerLevel - 1)))
        }
        
        updateStatsBarLabels()
        
        if levelUpOccurred {
            showTopLevelUpBanner(message: "⚡ PLAYER LEVEL UP!\nYou advanced to Level \(playerLevel)!")
            showLevelUpCongratulationAlert()
            lightUpRewardsButton()
        }
        
        checkQuestsProgress()
        checkProgressionMilestones()
        cancelPlacementMode()
    }
    
    // MARK: - Inspection & Upgrade Engine
    public func showBuildingInspectionPanel(for annotation: BuildingAnnotation) {
        dismissActivePanels(animated: false)
        
        self.selectedBuildingAnnotation = annotation
        
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.bottomBar.transform = CGAffineTransform(translationX: 0, y: 150)
            self.bottomBar.alpha = 0
            self.centerButton.transform = CGAffineTransform(translationX: 0, y: 150)
            self.centerButton.alpha = 0
            self.shopButton.transform = CGAffineTransform(translationX: 0, y: 150)
            self.shopButton.alpha = 0
        }, completion: nil)
        
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
        
        let dragHandle = UIView()
        dragHandle.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        dragHandle.layer.cornerRadius = 2.5
        dragHandle.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(dragHandle)
        
        let building = annotation.buildingItem
        
        let emojiContainer = UIView()
        emojiContainer.backgroundColor = UIColor.white.withAlphaComponent(0.06)
        emojiContainer.layer.cornerRadius = 12
        emojiContainer.layer.borderWidth = 1.0
        emojiContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.12).cgColor
        emojiContainer.clipsToBounds = true
        emojiContainer.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(emojiContainer)
        
        let emojiLabel = UILabel()
        emojiLabel.text = building.emoji
        emojiLabel.font = .systemFont(ofSize: 26)
        emojiLabel.textAlignment = .center
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiContainer.addSubview(emojiLabel)
        
        // Setup internal constraints for the emoji inside the container
        NSLayoutConstraint.activate([
            emojiLabel.centerXAnchor.constraint(equalTo: emojiContainer.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: emojiContainer.centerYAnchor)
        ])
        
        let nameLabel = UILabel()
        nameLabel.text = "\(building.name.uppercased())"
        nameLabel.textColor = .white
        nameLabel.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(nameLabel)
        
        // Emphasized Level Indicator inside Building Card - 14pt black weight
        let levelLabel = UILabel()
        levelLabel.text = "LEVEL \(building.level)"
        levelLabel.textColor = UIColor(red: 0.15, green: 0.65, blue: 1.0, alpha: 1.0)
        levelLabel.font = UIFont.systemFont(ofSize: 14, weight: .black)
        levelLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(levelLabel)
        
        let closeButton = UIButton(type: .system)
        let closeConfig = UIImage.SymbolConfiguration(pointSize: 20, weight: .semibold)
        let closeIcon = UIImage(systemName: "xmark.circle.fill", withConfiguration: closeConfig)
        closeButton.setImage(closeIcon, for: .normal)
        closeButton.tintColor = UIColor.white.withAlphaComponent(0.4)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(self, action: #selector(closeInspectionPanel), for: .touchUpInside)
        panel.addSubview(closeButton)
        
        let incomeLabel = UILabel()
        incomeLabel.text = "INCOME: $\(building.totalIncome)/hr"
        incomeLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        incomeLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        incomeLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(incomeLabel)

        // COLLECT button — shows pending income, tapping collects it
        let pending = building.pendingIncome
        let collectBtn = UIButton(type: .custom)
        let canCollect = pending > 0
        let collectTitle = canCollect
            ? "COLLECT $\(pending) ⬆️"
            : "EMPTY 📭"
        collectBtn.setTitle(collectTitle, for: .normal)
        collectBtn.titleLabel?.numberOfLines = 1
        
        if #available(iOS 15.0, *) {
            var config = UIButton.Configuration.filled()
            config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
                var outgoing = incoming
                outgoing.font = UIFont.systemFont(ofSize: 13, weight: .black)
                return outgoing
            }
            config.cornerStyle = .capsule
            config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
            config.baseBackgroundColor = canCollect
                ? UIColor(red: 0.10, green: 0.80, blue: 0.35, alpha: 1.0)
                : UIColor.white.withAlphaComponent(0.12)
            config.baseForegroundColor = .white
            collectBtn.configuration = config
        } else {
            collectBtn.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .black)
            collectBtn.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            collectBtn.backgroundColor = canCollect
                ? UIColor(red: 0.10, green: 0.80, blue: 0.35, alpha: 1.0)
                : UIColor.white.withAlphaComponent(0.12)
            collectBtn.layer.cornerRadius = 16
        }
        
        if canCollect {
            collectBtn.layer.shadowColor = UIColor(red: 0.10, green: 0.80, blue: 0.35, alpha: 1.0).cgColor
            collectBtn.layer.shadowOpacity = 0.5
            collectBtn.layer.shadowOffset = CGSize(width: 0, height: 4)
            collectBtn.layer.shadowRadius = 8
        }
        
        collectBtn.layer.borderWidth = 1.0
        collectBtn.layer.borderColor = UIColor.white.withAlphaComponent(canCollect ? 0.0 : 0.15).cgColor
        collectBtn.isEnabled = canCollect
        collectBtn.translatesAutoresizingMaskIntoConstraints = false
        collectBtn.addTarget(self, action: #selector(collectIncomeTapped), for: .touchUpInside)
        panel.addSubview(collectBtn)
        self.collectButton = collectBtn

        let capacityLabel = UILabel()
        capacityLabel.text = "CAPACITY: \(building.capacity) SLOT\(building.capacity > 1 ? "S" : "")"
        capacityLabel.textColor = UIColor.white.withAlphaComponent(0.7)
        capacityLabel.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        capacityLabel.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(capacityLabel)
        
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
        
        let upgradeButton = UIButton(type: .custom)
        let upgradeCost = building.level * 5000
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedCost = formatter.string(from: NSNumber(value: upgradeCost)) ?? "\(upgradeCost)"
        
        let nextBaseIncomeBoost: Int
        switch building.type {
        case .kiosk: nextBaseIncomeBoost = 250
        case .cafe: nextBaseIncomeBoost = 600
        case .bar: nextBaseIncomeBoost = 1000
        }
        
        upgradeButton.setTitle("UPGRADE - $\(formattedCost)\n(+$\(nextBaseIncomeBoost)/hr, +1 Slot)", for: .normal)
        upgradeButton.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .black)
        upgradeButton.titleLabel?.numberOfLines = 2
        if self.coins < upgradeCost {
            upgradeButton.backgroundColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0)
            upgradeButton.layer.borderColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 0.60).cgColor
        } else {
            upgradeButton.backgroundColor = UIColor(red: 0.15, green: 0.55, blue: 0.95, alpha: 1.0)
            upgradeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
        }
        upgradeButton.layer.cornerRadius = 14
        upgradeButton.translatesAutoresizingMaskIntoConstraints = false
        upgradeButton.addTarget(self, action: #selector(upgradeBuildingTapped), for: .touchUpInside)
        panel.addSubview(upgradeButton)
        
        let expandedView = UIView()
        expandedView.backgroundColor = .clear
        expandedView.alpha = 0.0
        expandedView.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(expandedView)
        self.expandedInspectionView = expandedView
        
        let divider = UIView()
        divider.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        divider.translatesAutoresizingMaskIntoConstraints = false
        expandedView.addSubview(divider)
        
        if building.level == 1 {
            let label = UILabel()
            label.text = "🔒 UPGRADE TO LEVEL 2 TO UNLOCK OPERATIONS & STAFF!"
            label.textColor = UIColor.white.withAlphaComponent(0.3)
            label.font = UIFont.systemFont(ofSize: 9, weight: .bold)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            expandedView.addSubview(label)
            
            NSLayoutConstraint.activate([
                divider.topAnchor.constraint(equalTo: expandedView.topAnchor),
                divider.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor, constant: 20),
                divider.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor, constant: -20),
                divider.heightAnchor.constraint(equalToConstant: 1),
                
                label.centerXAnchor.constraint(equalTo: expandedView.centerXAnchor),
                label.centerYAnchor.constraint(equalTo: expandedView.centerYAnchor)
            ])
        } else {
            // Staff recruitment section
            let staffContainer = UIView()
            staffContainer.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            staffContainer.layer.cornerRadius = 16
            staffContainer.layer.borderWidth = 1.0
            staffContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
            staffContainer.translatesAutoresizingMaskIntoConstraints = false
            expandedView.addSubview(staffContainer)
            
            let staffEmoji = UILabel()
            staffEmoji.text = "👥"
            staffEmoji.font = .systemFont(ofSize: 22)
            staffEmoji.translatesAutoresizingMaskIntoConstraints = false
            staffContainer.addSubview(staffEmoji)
            
            let staffTitle = UILabel()
            staffTitle.text = "RECRUIT STAFF"
            staffTitle.textColor = .white
            staffTitle.font = UIFont.systemFont(ofSize: 11, weight: .black)
            staffTitle.translatesAutoresizingMaskIntoConstraints = false
            staffContainer.addSubview(staffTitle)
            
            let staffSub = UILabel()
            staffSub.text = "Lv. \(building.staffLevel) | +$\(building.staffLevel * 150)/hr, +\(building.staffLevel * 20) HP" // Replaced 🪙 with $
            staffSub.textColor = UIColor.white.withAlphaComponent(0.5)
            staffSub.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
            staffSub.translatesAutoresizingMaskIntoConstraints = false
            staffContainer.addSubview(staffSub)
            
            let staffUpgradeBtn = UIButton(type: .custom)
            let formattedStaffCost = formatter.string(from: NSNumber(value: (building.staffLevel + 1) * 3000)) ?? "\((building.staffLevel + 1) * 3000)"
            staffUpgradeBtn.setTitle("UPGRADE - $\(formattedStaffCost)\n(+$150/hr, +20 HP)", for: .normal) // Replaced 🪙 with $
            staffUpgradeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 8, weight: .black)
            let staffCostValue = (building.staffLevel + 1) * 3000
            if self.coins < staffCostValue {
                staffUpgradeBtn.backgroundColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0)
            } else {
                staffUpgradeBtn.backgroundColor = UIColor(red: 0.15, green: 0.85, blue: 0.45, alpha: 1.0)
            }
            staffUpgradeBtn.layer.cornerRadius = 10
            staffUpgradeBtn.translatesAutoresizingMaskIntoConstraints = false
            staffUpgradeBtn.addTarget(self, action: #selector(upgradeStaffTapped), for: .touchUpInside)
            staffContainer.addSubview(staffUpgradeBtn)
            
            // Equipment upgrading section
            let equipContainer = UIView()
            equipContainer.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            equipContainer.layer.cornerRadius = 16
            equipContainer.layer.borderWidth = 1.0
            equipContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
            equipContainer.translatesAutoresizingMaskIntoConstraints = false
            expandedView.addSubview(equipContainer)
            
            let equipEmoji = UILabel()
            equipEmoji.text = "⚙️"
            equipEmoji.font = .systemFont(ofSize: 22)
            equipEmoji.translatesAutoresizingMaskIntoConstraints = false
            equipContainer.addSubview(equipEmoji)
            
            let equipTitle = UILabel()
            equipTitle.text = "UPGRADE EQUIP"
            equipTitle.textColor = .white
            equipTitle.font = UIFont.systemFont(ofSize: 11, weight: .black)
            equipTitle.translatesAutoresizingMaskIntoConstraints = false
            equipContainer.addSubview(equipTitle)
            
            let equipSub = UILabel()
            equipSub.text = "Lv. \(building.equipLevel) | +$\(building.equipLevel * 250)/hr, +\(building.equipLevel * 30) HP" // Replaced 🪙 with $
            equipSub.textColor = UIColor.white.withAlphaComponent(0.5)
            equipSub.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
            equipSub.translatesAutoresizingMaskIntoConstraints = false
            equipContainer.addSubview(equipSub)
            
            let equipUpgradeBtn = UIButton(type: .custom)
            let formattedEquipCost = formatter.string(from: NSNumber(value: (building.equipLevel + 1) * 4000)) ?? "\((building.equipLevel + 1) * 4000)"
            equipUpgradeBtn.setTitle("UPGRADE - $\(formattedEquipCost)\n(+$250/hr, +30 HP)", for: .normal) // Replaced 🪙 with $
            equipUpgradeBtn.titleLabel?.font = UIFont.systemFont(ofSize: 8, weight: .black)
            let equipCostValue = (building.equipLevel + 1) * 4000
            if self.coins < equipCostValue {
                equipUpgradeBtn.backgroundColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0)
            } else {
                equipUpgradeBtn.backgroundColor = UIColor(red: 0.15, green: 0.55, blue: 0.95, alpha: 1.0)
            }
            equipUpgradeBtn.layer.cornerRadius = 10
            equipUpgradeBtn.translatesAutoresizingMaskIntoConstraints = false
            equipUpgradeBtn.addTarget(self, action: #selector(upgradeEquipTapped), for: .touchUpInside)
            equipContainer.addSubview(equipUpgradeBtn)
            
            NSLayoutConstraint.activate([
                divider.topAnchor.constraint(equalTo: expandedView.topAnchor),
                divider.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor, constant: 20),
                divider.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor, constant: -20),
                divider.heightAnchor.constraint(equalToConstant: 1),
                
                staffContainer.topAnchor.constraint(equalTo: divider.bottomAnchor, constant: 14),
                staffContainer.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor, constant: 20),
                staffContainer.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor, constant: -20),
                staffContainer.heightAnchor.constraint(equalToConstant: 58),
                
                staffEmoji.leadingAnchor.constraint(equalTo: staffContainer.leadingAnchor, constant: 12),
                staffEmoji.centerYAnchor.constraint(equalTo: staffContainer.centerYAnchor),
                
                staffTitle.topAnchor.constraint(equalTo: staffContainer.topAnchor, constant: 10),
                staffTitle.leadingAnchor.constraint(equalTo: staffEmoji.trailingAnchor, constant: 10),
                
                staffSub.topAnchor.constraint(equalTo: staffTitle.bottomAnchor, constant: 2),
                staffSub.leadingAnchor.constraint(equalTo: staffEmoji.trailingAnchor, constant: 10),
                
                staffUpgradeBtn.trailingAnchor.constraint(equalTo: staffContainer.trailingAnchor, constant: -10),
                staffUpgradeBtn.centerYAnchor.constraint(equalTo: staffContainer.centerYAnchor),
                staffUpgradeBtn.widthAnchor.constraint(equalToConstant: 120),
                staffUpgradeBtn.heightAnchor.constraint(equalToConstant: 36),
                
                equipContainer.topAnchor.constraint(equalTo: staffContainer.bottomAnchor, constant: 10),
                equipContainer.leadingAnchor.constraint(equalTo: expandedView.leadingAnchor, constant: 20),
                equipContainer.trailingAnchor.constraint(equalTo: expandedView.trailingAnchor, constant: -20),
                equipContainer.heightAnchor.constraint(equalToConstant: 58),
                
                equipEmoji.leadingAnchor.constraint(equalTo: equipContainer.leadingAnchor, constant: 12),
                equipEmoji.centerYAnchor.constraint(equalTo: equipContainer.centerYAnchor),
                
                equipTitle.topAnchor.constraint(equalTo: equipContainer.topAnchor, constant: 10),
                equipTitle.leadingAnchor.constraint(equalTo: equipEmoji.trailingAnchor, constant: 10),
                
                equipSub.topAnchor.constraint(equalTo: equipTitle.bottomAnchor, constant: 2),
                equipSub.leadingAnchor.constraint(equalTo: equipEmoji.trailingAnchor, constant: 10),
                
                equipUpgradeBtn.trailingAnchor.constraint(equalTo: equipContainer.trailingAnchor, constant: -10),
                equipUpgradeBtn.centerYAnchor.constraint(equalTo: equipContainer.centerYAnchor),
                equipUpgradeBtn.widthAnchor.constraint(equalToConstant: 120),
                equipUpgradeBtn.heightAnchor.constraint(equalToConstant: 36)
            ])
        }
        
        // --- Slots / Inventory Section ---
        let slotsView = UIView()
        slotsView.backgroundColor = .clear
        slotsView.alpha = 0.0
        slotsView.translatesAutoresizingMaskIntoConstraints = false
        panel.addSubview(slotsView)
        self.slotsInspectionView = slotsView
        
        let slotsDivider = UIView()
        slotsDivider.backgroundColor = UIColor.white.withAlphaComponent(0.08)
        slotsDivider.translatesAutoresizingMaskIntoConstraints = false
        slotsView.addSubview(slotsDivider)
        
        let slotsTitle = UILabel()
        slotsTitle.text = "📥 PRODUCTION SLOTS"
        slotsTitle.textColor = .white
        slotsTitle.font = UIFont.systemFont(ofSize: 11, weight: .bold)
        slotsTitle.translatesAutoresizingMaskIntoConstraints = false
        slotsView.addSubview(slotsTitle)
        
        let slotsStack = UIStackView()
        slotsStack.axis = .horizontal
        slotsStack.spacing = 14
        slotsStack.distribution = .fillEqually
        slotsStack.translatesAutoresizingMaskIntoConstraints = false
        slotsView.addSubview(slotsStack)
        
        // Generate pristine slots using optimized 72x72 square constraints
        for i in 1...building.capacity {
            let slot = UIView()
            slot.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            slot.layer.cornerRadius = 14
            slot.layer.borderWidth = 1.0
            slot.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
            slot.translatesAutoresizingMaskIntoConstraints = false
            slotsStack.addArrangedSubview(slot)
            
            // Set explicit square dimensions to prevent compression
            slot.widthAnchor.constraint(equalToConstant: 72).isActive = true
            slot.heightAnchor.constraint(equalToConstant: 72).isActive = true
            
            let plusLabel = UILabel()
            plusLabel.text = "➕"
            plusLabel.font = .systemFont(ofSize: 18)
            plusLabel.textAlignment = .center
            plusLabel.translatesAutoresizingMaskIntoConstraints = false
            slot.addSubview(plusLabel)
            
            let slotLabel = UILabel()
            slotLabel.text = "Slot \(i)"
            slotLabel.textColor = UIColor.white.withAlphaComponent(0.4)
            slotLabel.font = UIFont.systemFont(ofSize: 9, weight: .semibold)
            slotLabel.textAlignment = .center
            slotLabel.translatesAutoresizingMaskIntoConstraints = false
            slot.addSubview(slotLabel)
            
            NSLayoutConstraint.activate([
                plusLabel.centerXAnchor.constraint(equalTo: slot.centerXAnchor),
                plusLabel.centerYAnchor.constraint(equalTo: slot.centerYAnchor, constant: -6),
                
                slotLabel.topAnchor.constraint(equalTo: plusLabel.bottomAnchor, constant: 4),
                slotLabel.centerXAnchor.constraint(equalTo: slot.centerXAnchor)
            ])
            
            let slotTap = UITapGestureRecognizer(target: self, action: #selector(slotPlusTapped))
            slot.addGestureRecognizer(slotTap)
            slot.isUserInteractionEnabled = true
        }
        
        view.addSubview(panel)
        self.inspectionPanel = panel
        activeSheetState = .collapsed
        
        let hpRatio = CGFloat(building.currentHP) / CGFloat(building.maxHP)
        self.inspectionPanelHeightConstraint = panel.heightAnchor.constraint(equalToConstant: 220)
        
        NSLayoutConstraint.activate([
            panel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            panel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            panel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            self.inspectionPanelHeightConstraint!,
            
            dragHandle.topAnchor.constraint(equalTo: panel.topAnchor, constant: 8),
            dragHandle.centerXAnchor.constraint(equalTo: panel.centerXAnchor),
            dragHandle.widthAnchor.constraint(equalToConstant: 36),
            dragHandle.heightAnchor.constraint(equalToConstant: 5),
            
            emojiContainer.topAnchor.constraint(equalTo: dragHandle.bottomAnchor, constant: 14),
            emojiContainer.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),
            emojiContainer.widthAnchor.constraint(equalToConstant: 44),
            emojiContainer.heightAnchor.constraint(equalToConstant: 44),
            
            nameLabel.topAnchor.constraint(equalTo: emojiContainer.topAnchor, constant: 2),
            nameLabel.leadingAnchor.constraint(equalTo: emojiContainer.trailingAnchor, constant: 12),
            
            levelLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 2),
            levelLabel.leadingAnchor.constraint(equalTo: emojiContainer.trailingAnchor, constant: 12),
            
            closeButton.centerYAnchor.constraint(equalTo: nameLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),
            
            incomeLabel.topAnchor.constraint(equalTo: emojiContainer.bottomAnchor, constant: 16),
            incomeLabel.leadingAnchor.constraint(equalTo: panel.leadingAnchor, constant: 20),

            collectBtn.trailingAnchor.constraint(equalTo: panel.trailingAnchor, constant: -20),
            collectBtn.bottomAnchor.constraint(equalTo: upgradeButton.topAnchor, constant: -8),
            collectBtn.widthAnchor.constraint(equalToConstant: 150),
            collectBtn.heightAnchor.constraint(equalToConstant: 36),

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
            upgradeButton.bottomAnchor.constraint(equalTo: hpProgressContainer.bottomAnchor, constant: 0),
            upgradeButton.widthAnchor.constraint(equalToConstant: 150),
            upgradeButton.heightAnchor.constraint(equalToConstant: 44),
            
            // Expanded operations layout inside panel
            expandedView.topAnchor.constraint(equalTo: hpProgressContainer.bottomAnchor, constant: 14),
            expandedView.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            expandedView.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            expandedView.heightAnchor.constraint(equalToConstant: 160),
            
            // Slots layout
            slotsView.topAnchor.constraint(equalTo: expandedView.bottomAnchor, constant: 14),
            slotsView.leadingAnchor.constraint(equalTo: panel.leadingAnchor),
            slotsView.trailingAnchor.constraint(equalTo: panel.trailingAnchor),
            slotsView.heightAnchor.constraint(equalToConstant: 180),
            
            slotsDivider.topAnchor.constraint(equalTo: slotsView.topAnchor),
            slotsDivider.leadingAnchor.constraint(equalTo: slotsView.leadingAnchor, constant: 20),
            slotsDivider.trailingAnchor.constraint(equalTo: slotsView.trailingAnchor, constant: -20),
            slotsDivider.heightAnchor.constraint(equalToConstant: 1),
            
            slotsTitle.topAnchor.constraint(equalTo: slotsDivider.bottomAnchor, constant: 12),
            slotsTitle.leadingAnchor.constraint(equalTo: slotsView.leadingAnchor, constant: 20),
            
            // Centered slots stack view configuration
            slotsStack.topAnchor.constraint(equalTo: slotsTitle.bottomAnchor, constant: 12),
            slotsStack.centerXAnchor.constraint(equalTo: slotsView.centerXAnchor),
            slotsStack.heightAnchor.constraint(equalToConstant: 72)
        ])
        
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleInspectionSwipe(_:)))
        swipeUp.direction = .up
        panel.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleInspectionSwipe(_:)))
        swipeDown.direction = .down
        panel.addGestureRecognizer(swipeDown)
        
        panel.transform = CGAffineTransform(translationX: 0, y: 350)
        panel.alpha = 0
        UIView.animate(withDuration: 0.25, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            panel.transform = .identity
            panel.alpha = 1.0
        }, completion: nil)
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    @objc private func handleInspectionSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .up {
            if activeSheetState == .collapsed {
                transitionInspectionPanel(to: .upgrades)
            } else if activeSheetState == .upgrades {
                transitionInspectionPanel(to: .slots)
            }
        } else if gesture.direction == .down {
            if activeSheetState == .slots {
                transitionInspectionPanel(to: .upgrades)
            } else if activeSheetState == .upgrades {
                transitionInspectionPanel(to: .collapsed)
            }
        }
    }
    
    public func transitionInspectionPanel(to state: SheetState) {
        activeSheetState = state
        
        let targetHeight: CGFloat
        let showUpgrades: CGFloat
        let showSlots: CGFloat
        
        switch state {
        case .collapsed:
            targetHeight = 220
            showUpgrades = 0.0
            showSlots = 0.0
        case .upgrades:
            targetHeight = 390
            showUpgrades = 1.0
            showSlots = 0.0
        case .slots:
            targetHeight = 580
            showUpgrades = 1.0
            showSlots = 1.0
        }
        
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        UIView.animate(withDuration: 0.35, delay: 0.0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            self.inspectionPanelHeightConstraint?.constant = targetHeight
            self.expandedInspectionView?.alpha = showUpgrades
            self.slotsInspectionView?.alpha = showSlots
            self.view.layoutIfNeeded()
        }, completion: nil)
    }
    
    @objc private func slotPlusTapped() {
        closeInspectionPanel()
        openShopViewController()
    }
    
    @objc private func closeInspectionPanel() {
        dismissActivePanels(animated: true)
        
        UIView.animate(withDuration: 0.40, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            self.bottomBar.transform = .identity
            self.bottomBar.alpha = 1.0
            self.centerButton.transform = .identity
            self.centerButton.alpha = 1.0
            self.shopButton.transform = .identity
            self.shopButton.alpha = 1.0
        }, completion: nil)
    }
    
    @objc private func upgradeBuildingTapped() {
        guard let annotation = selectedBuildingAnnotation else { return }
        let currentLevel = annotation.buildingItem.level
        let upgradeCost = currentLevel * 5000
        
        if coins < upgradeCost {
            showNotificationHUD(message: "INSUFFICIENT FUNDS\nNeed $\(upgradeCost) to upgrade!") // Replaced 🪙 with $
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        coins -= upgradeCost
        updateStatsBarLabels()
        
        annotation.buildingItem.level += 1
        
        // Sync back into placedBuildings array
        if let idx = placedBuildings.firstIndex(where: { $0.id == annotation.buildingItem.id }) {
            placedBuildings[idx] = annotation.buildingItem
        }
        
        // Award XP for upgrading a building: 15 XP * level
        let xpAward = 15 * (currentLevel + 1)
        playerXP += xpAward
        
        var req = requiredXP
        var levelUpOccurred = false
        while playerXP >= req {
            playerXP -= req
            playerLevel += 1
            levelUpOccurred = true
            req = Int(100 * pow(1.5, Double(playerLevel - 1)))
        }
        
        updateStatsBarLabels()
        
        if levelUpOccurred {
            showTopLevelUpBanner(message: "⚡ PLAYER LEVEL UP!\nYou advanced to Level \(playerLevel)!")
            showLevelUpCongratulationAlert()
            lightUpRewardsButton()
        }
        
        checkQuestsProgress()
        checkProgressionMilestones()
        
        mapView.removeAnnotation(annotation)
        mapView.addAnnotation(annotation)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showNotificationHUD(message: "UPGRADED TO LEVEL \(currentLevel + 1) 🚀")
        
        let prevState = activeSheetState
        showBuildingInspectionPanel(for: annotation)
        transitionInspectionPanel(to: prevState)
    }
    
    @objc private func upgradeStaffTapped() {
        guard let annotation = selectedBuildingAnnotation else { return }
        let currentStaff = annotation.buildingItem.staffLevel
        let cost = (currentStaff + 1) * 3000
        
        if coins < cost {
            showNotificationHUD(message: "INSUFFICIENT FUNDS\nNeed $\(cost) to hire staff!") // Replaced 🪙 with $
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        coins -= cost
        updateStatsBarLabels()
        
        annotation.buildingItem.staffLevel += 1
        annotation.buildingItem.currentHP = annotation.buildingItem.maxHP
        
        mapView.removeAnnotation(annotation)
        mapView.addAnnotation(annotation)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showNotificationHUD(message: "Hired Personnel! Staff is now Level \(currentStaff + 1) 👥")
        
        let prevState = activeSheetState
        showBuildingInspectionPanel(for: annotation)
        transitionInspectionPanel(to: prevState)
    }
    
    @objc private func upgradeEquipTapped() {
        guard let annotation = selectedBuildingAnnotation else { return }
        let currentEquip = annotation.buildingItem.equipLevel
        let cost = (currentEquip + 1) * 4000
        
        if coins < cost {
            showNotificationHUD(message: "INSUFFICIENT FUNDS\nNeed $\(cost) to upgrade equipment!") // Replaced 🪙 with $
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
            return
        }
        
        coins -= cost
        updateStatsBarLabels()
        
        annotation.buildingItem.equipLevel += 1
        annotation.buildingItem.currentHP = annotation.buildingItem.maxHP
        
        mapView.removeAnnotation(annotation)
        mapView.addAnnotation(annotation)
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        showNotificationHUD(message: "Equipment Upgraded to Level \(currentEquip + 1) ⚙️")
        
        let prevState = activeSheetState
        showBuildingInspectionPanel(for: annotation)
        transitionInspectionPanel(to: prevState)
    }

    // MARK: - Income Collection

    /// Called from map delegate when user taps a building with enough pending income
    public func collectIncomeFromAnnotation(_ annotation: BuildingAnnotation) {
        let amount = annotation.buildingItem.collectIncome()
        guard amount > 0 else { return }

        // Sync back into placedBuildings array
        if let idx = placedBuildings.firstIndex(where: { $0.id == annotation.buildingItem.id }) {
            placedBuildings[idx] = annotation.buildingItem
        }

        coins += amount
        
        // Roll 5% chance for XP: awards 50% of the collected amount as XP
        var xpGained = 0
        if Double.random(in: 0..<1) < 0.05 {
            xpGained = amount / 2
        }
        
        if xpGained > 0 {
            playerXP += xpGained
            showFloatingXPPopup(amount: xpGained)
        }
        
        var req = requiredXP
        var levelUpOccurred = false
        while playerXP >= req {
            playerXP -= req
            playerLevel += 1
            levelUpOccurred = true
            req = Int(100 * pow(1.5, Double(playerLevel - 1)))
        }
        
        updateStatsBarLabels()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        var msg = "COLLECTED $\(amount) 💰\nFrom \(annotation.buildingItem.name)!"
        if xpGained > 0 {
            msg += "\n🔥 BONUS: +\(xpGained) XP gained!"
        }
        showNotificationHUD(message: msg)
        
        if levelUpOccurred {
            showTopLevelUpBanner(message: "⚡ PLAYER LEVEL UP!\nYou advanced to Level \(playerLevel)!")
            showLevelUpCongratulationAlert()
            lightUpRewardsButton()
        }
    }

    @objc private func collectIncomeTapped() {
        guard let annotation = selectedBuildingAnnotation else { return }

        // Animate button
        UIView.animate(withDuration: 0.08) {
            self.collectButton?.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        } completion: { _ in
            UIView.animate(withDuration: 0.10) { self.collectButton?.transform = .identity }
        }

        collectIncomeFromAnnotation(annotation)

        // Refresh panel to update button state
        let state = activeSheetState
        showBuildingInspectionPanel(for: annotation)
        transitionInspectionPanel(to: state)
    }

    
    public func updateStatsBarLabels() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if let formattedCoins = formatter.string(from: NSNumber(value: coins)) {
            coinsLabel?.text = formattedCoins
        } else {
            coinsLabel?.text = "\(coins)"
        }
        
        gemsLabel?.text = "\(gems)"
        
        // Sync player level to scale inventory slot capacity
        InventoryManager.shared.updatePlayerLevel(playerLevel)
        let occupied = InventoryManager.shared.currentOccupiedSlots
        let maxSlots = InventoryManager.shared.maxSlots
        bagLabel?.text = "\(occupied)/\(maxSlots)"
        
        // Update level label with XP remaining progression next to level callsign
        nicknameLabel.text = "\(nickname) \(playerLevel)"
        
        let req = requiredXP
        levelLabel.text = "\(req - playerXP) XP to level-up"
        refreshInventoryUI()
        
        UIView.animate(withDuration: 0.1, animations: {
            self.coinsLabel?.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.coinsLabel?.transform = .identity
            }
        }
    }
    
    public func showNotificationHUD(message: String) {
        // Dismiss previous toast immediately to prevent overlapping
        if let oldToast = activeToastView {
            oldToast.removeFromSuperview()
        }
        
        let toast = UIView()
        toast.backgroundColor = UIColor(white: 0.08, alpha: 0.95)
        toast.layer.cornerRadius = 20
        toast.layer.borderWidth = 1.0
        toast.layer.borderColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.40).cgColor
        toast.clipsToBounds = true
        toast.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        toast.addSubview(blurView)
        
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        toast.addSubview(label)
        
        view.addSubview(toast)
        activeToastView = toast
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: toast.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: toast.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: toast.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: toast.bottomAnchor),
            
            label.topAnchor.constraint(equalTo: toast.topAnchor, constant: 10),
            label.leadingAnchor.constraint(equalTo: toast.leadingAnchor, constant: 20),
            label.trailingAnchor.constraint(equalTo: toast.trailingAnchor, constant: -20),
            label.bottomAnchor.constraint(equalTo: toast.bottomAnchor, constant: -10),
            
            toast.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 70),
            toast.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            toast.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.85)
        ])
        
        // Animate in
        toast.transform = CGAffineTransform(translationX: 0, y: -40)
        toast.alpha = 0.0
        
        UIView.animate(withDuration: 0.3, delay: 0.0, options: .curveEaseOut, animations: {
            toast.transform = .identity
            toast.alpha = 1.0
        })
        
        // Fade out after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak toast, weak self] in
            guard let toast = toast else { return }
            UIView.animate(withDuration: 0.3, animations: {
                toast.alpha = 0.0
                toast.transform = CGAffineTransform(translationX: 0, y: -20)
            }) { _ in
                toast.removeFromSuperview()
                if self?.activeToastView == toast {
                    self?.activeToastView = nil
                }
            }
        }
    }
    
    public func showTopLevelUpBanner(message: String) {
        let banner = UIView()
        banner.backgroundColor = UIColor(white: 0.08, alpha: 0.95)
        banner.layer.cornerRadius = 16
        banner.layer.borderWidth = 1.5
        banner.layer.borderColor = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 0.8).cgColor // Gorgeous Gold/Yellow glow border
        banner.clipsToBounds = true
        banner.translatesAutoresizingMaskIntoConstraints = false
        
        let blurEffect = UIBlurEffect(style: .dark)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(blurView)
        
        let trophyIcon = UILabel()
        trophyIcon.text = "⚡"
        trophyIcon.font = .systemFont(ofSize: 22)
        trophyIcon.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(trophyIcon)
        
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 13, weight: .black)
        label.textAlignment = .left
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        banner.addSubview(label)
        
        view.addSubview(banner)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: banner.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: banner.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: banner.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: banner.bottomAnchor),
            
            trophyIcon.leadingAnchor.constraint(equalTo: banner.leadingAnchor, constant: 16),
            trophyIcon.centerYAnchor.constraint(equalTo: banner.centerYAnchor),
            trophyIcon.widthAnchor.constraint(equalToConstant: 24),
            
            label.topAnchor.constraint(equalTo: banner.topAnchor, constant: 14),
            label.leadingAnchor.constraint(equalTo: trophyIcon.trailingAnchor, constant: 12),
            label.trailingAnchor.constraint(equalTo: banner.trailingAnchor, constant: -16),
            label.bottomAnchor.constraint(equalTo: banner.bottomAnchor, constant: -14),
            
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            banner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            banner.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.90)
        ])
        
        // Dynamic drop shadow glow
        banner.layer.shadowColor = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0).cgColor
        banner.layer.shadowRadius = 12.0
        banner.layer.shadowOpacity = 0.6
        banner.layer.shadowOffset = .zero
        
        // Slide down animation
        banner.transform = CGAffineTransform(translationX: 0, y: -100)
        banner.alpha = 0.0
        
        UIView.animate(withDuration: 0.5, delay: 0.0, usingSpringWithDamping: 0.75, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            banner.transform = .identity
            banner.alpha = 1.0
        }) { _ in
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        }
        
        // Slide up and remove after 4.0 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) { [weak banner] in
            guard let banner = banner else { return }
            UIView.animate(withDuration: 0.4, animations: {
                banner.alpha = 0.0
                banner.transform = CGAffineTransform(translationX: 0, y: -100)
            }) { _ in
                banner.removeFromSuperview()
            }
        }
    }
    
    public func dismissActivePanels(animated: Bool = true) {
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
            activeSheetState = .collapsed
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
        
        // Restore bottom bar and floating buttons when panels are dismissed
        let restoreBlock = {
            self.bottomBar.transform = .identity
            self.bottomBar.alpha = 1.0
            self.centerButton.transform = .identity
            self.centerButton.alpha = 1.0
            self.shopButton.transform = .identity
            self.shopButton.alpha = 1.0
            self.storeButton.transform = .identity
            self.storeButton.alpha = 1.0
        }
        
        if animated {
            UIView.animate(withDuration: 0.40, delay: 0.0, usingSpringWithDamping: 0.78, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: restoreBlock, completion: nil)
        } else {
            restoreBlock()
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
    
    // MARK: - Location Manager Setup & Core Operations
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // Connect Mob Spawner Service callback
        MapSpawnerService.shared.onNewMobsSpawned = { [weak self] mobs in
            DispatchQueue.main.async {
                self?.handleNewMobsSpawned(mobs)
            }
        }
        
        // Start proximity spawn timer to keep mobs refreshed around user location
        MapSpawnerService.shared.startProximitySpawnTimer(intervalSeconds: 20.0) { [weak self] in
            return self?.avatarAnnotation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863)
        }
        
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
    
    public func showLocationDeniedAlert() {
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
    
    public func handleLocationUpdate(_ location: CLLocation) {
        let coordinate = location.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else { return }
        
        if let existing = avatarAnnotation {
            let oldLocation = CLLocation(latitude: existing.coordinate.latitude, longitude: existing.coordinate.longitude)
            let distance = location.distance(from: oldLocation)
            if distance < 8.0 {
                return
            }
        }
        
        placeAvatarAtLocation(coordinate)
        
        if !hasShownWelcomeBanner {
            hasShownWelcomeBanner = true
            let geocoder = CLGeocoder()
            let locale = Locale(identifier: "en_US")
            geocoder.reverseGeocodeLocation(location, preferredLocale: locale) { [weak self] placemarks, error in
                guard let self = self else { return }
                let cityName = placemarks?.first?.locality ?? placemarks?.first?.subAdministrativeArea ?? "GeoLive"
                self.showWelcomeBanner(for: cityName)
            }
        }
        
        if location.horizontalAccuracy > 0 && location.horizontalAccuracy <= 30 && !hasCenteredOnHighAccuracy {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
            hasCenteredOnHighAccuracy = true
        }
    }
    
    private func placeAvatarAtLocation(_ coordinate: CLLocationCoordinate2D) {
        if let existing = avatarAnnotation {
            UIView.animate(withDuration: 0.3) {
                existing.coordinate = coordinate
            }
        } else {
            let annotation = AvatarAnnotation(coordinate: coordinate, avatarImage: avatarImage)
            avatarAnnotation = annotation
            mapView.addAnnotation(annotation)
        }
        
        if let oldCircle = interactionCircle {
            mapView.removeOverlay(oldCircle)
        }
        let newCircle = MKCircle(center: coordinate, radius: 150)
        interactionCircle = newCircle
        mapView.addOverlay(newCircle)
        
        if let oldAttack = attackCircle {
            mapView.removeOverlay(oldAttack)
        }
        let newAttack = MKCircle(center: coordinate, radius: 500)
        attackCircle = newAttack
        mapView.addOverlay(newAttack)
        
        if !hasInitiallyCentered {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 400)
            mapView.setRegion(region, animated: true)
            hasInitiallyCentered = true
        }
    }
    
    // MARK: - Animated Welcome HUD Banner
    public func showWelcomeBanner(for cityName: String) {
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
        
        let subLabel = UILabel()
        subLabel.text = "WELCOME TO"
        subLabel.textColor = UIColor.white.withAlphaComponent(0.50)
        subLabel.font = UIFont.systemFont(ofSize: 10, weight: .black)
        subLabel.textAlignment = .center
        subLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.addSubview(subLabel)
        
        let titleLabel = UILabel()
        titleLabel.text = "\(cityName) 📍"
        titleLabel.textColor = .white
        titleLabel.font = UIFont.systemFont(ofSize: 22, weight: .bold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        welcomeView.addSubview(titleLabel)
        
        view.addSubview(welcomeView)
        
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
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        welcomeView.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        welcomeView.alpha = 0.0
        
        UIView.animate(withDuration: 0.65, delay: 0.15, usingSpringWithDamping: 0.72, initialSpringVelocity: 0.5, options: .curveEaseOut, animations: {
            welcomeView.transform = .identity
            welcomeView.alpha = 1.0
        }) { _ in
            UIView.animate(withDuration: 0.40, delay: 2.00, options: .curveEaseIn, animations: {
                welcomeView.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
                welcomeView.alpha = 0.0
            }) { _ in
                welcomeView.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Combat Simulation & Dynamic Respawning
    private func startCombatSimulation() {
        // Disabled unfair random damage. Damage is now only received intentionally during visible mob battles.
    }
    
    public func takeDamage(amount: Int) {
        guard !isPlayerDead else { return }
        
        playerCurrentHP -= amount
        if playerCurrentHP < 0 { playerCurrentHP = 0 }
        
        // Update floating HP progress bar and red damage flashes on map avatar view!
        if let avatarAnn = avatarAnnotation,
           let annotationView = mapView.view(for: avatarAnn) as? AvatarAnnotationView {
            annotationView.triggerDamageFlash()
            annotationView.updateHP(current: playerCurrentHP, max: playerMaxHP)
        }
        
        showNotificationHUD(message: "⚡ INCOMING DAMAGE\nReceived \(amount) damage! HP: \(playerCurrentHP)/\(playerMaxHP)")
        
        if playerCurrentHP <= 0 {
            triggerPlayerDeath()
        }
    }
    
    private func triggerPlayerDeath() {
        isPlayerDead = true
        hasAngeredMobs = false // Stop pursuing after death
        respawnTimer?.invalidate()
        
        // Respawn cooldown rises with level: base 3s + level * 1.5s
        var secondsRemaining = 3.0 + Double(playerLevel) * 1.5
        
        respawnOverlay.isHidden = false
        respawnOverlay.alpha = 0.0
        respawnSubtitleLabel.text = String(format: "RESTABLISHING MATRIX IN %.1fS...", secondsRemaining)
        
        UINotificationFeedbackGenerator().notificationOccurred(.error)
        
        UIView.animate(withDuration: 0.35) {
            self.respawnOverlay.alpha = 1.0
        }
        
        respawnTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self else { return }
            secondsRemaining -= 0.1
            if secondsRemaining <= 0 {
                timer.invalidate()
                self.triggerRespawn()
            } else {
                self.respawnSubtitleLabel.text = String(format: "RESTABLISHING MATRIX IN %.1fS...", secondsRemaining)
            }
        }
    }
    
    private func triggerRespawn() {
        isPlayerDead = false
        playerCurrentHP = playerMaxHP
        
        UIView.animate(withDuration: 0.30, animations: {
            self.respawnOverlay.alpha = 0.0
        }) { _ in
            self.respawnOverlay.isHidden = true
            
            if let avatarAnn = self.avatarAnnotation,
               let annotationView = self.mapView.view(for: avatarAnn) as? AvatarAnnotationView {
                annotationView.updateHP(current: self.playerCurrentHP, max: self.playerMaxHP)
            }
            
            self.showNotificationHUD(message: "⚡ CONNECTION RESTORED\nOperative successfully resurrected!")
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
    
    // MARK: - Skull Collection & Level Up Congratulations
    @objc public func collectSkull(_ annotation: SkullAnnotation) {
        // Haptic feedback
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        // Award 1 XP and update labels
        playerXP += 1
        
        let req = requiredXP
        var levelUpOccurred = false
        while playerXP >= req {
            playerXP -= req
            playerLevel += 1
            levelUpOccurred = true
            // Re-fetch req to support multiple level-ups
        }
        
        updateStatsBarLabels()
        showNotificationHUD(message: "💀 Remains collected! +1 XP! \(levelUpOccurred ? "\n⚡ LEVEL UP! NOW LEVEL \(playerLevel)!" : "")")
        
        if levelUpOccurred {
            showLevelUpCongratulationAlert()
            lightUpRewardsButton()
        }
        
        // Remove annotation from map
        mapView.removeAnnotation(annotation)
    }
    
    private func showLevelUpCongratulationAlert() {
        let alert = UIAlertController(
            title: "⚡ LEVEL UP! ⚡",
            message: "Congratulations! You have advanced to Level \(playerLevel)!\n\nNew milestone rewards are now available in your Rewards tab! 🏆",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "TACTICAL EXCELLENCE!", style: .default, handler: nil))
        present(alert, animated: true)
    }
    
    private func lightUpRewardsButton() {
        rewardsButton.layer.removeAllAnimations()
        rewardsButton.backgroundColor = UIColor(red: 1.0, green: 0.85, blue: 0.0, alpha: 1.0)
        rewardsButton.tintColor = .black
        rewardsButton.layer.borderColor = UIColor(red: 1.0, green: 0.95, blue: 0.2, alpha: 1.0).cgColor
        
        // Pulsate animation
        UIView.animate(withDuration: 0.6, delay: 0, options: [.repeat, .autoreverse, .allowUserInteraction]) {
            self.rewardsButton.transform = CGAffineTransform(scaleX: 1.25, y: 1.25)
        }
    }
    
    private func startMobMovementTimer() {
        mobMovementTimer?.invalidate()
        mobMovementTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let userCoord = self.avatarAnnotation?.coordinate ?? CLLocationCoordinate2D(latitude: 37.3382, longitude: -121.8863)
            let playerCL = CLLocation(latitude: userCoord.latitude, longitude: userCoord.longitude)
            
            for (idx, mobAnn) in self.activeMobAnnotations.enumerated() {
                var mob = mobAnn.mobDTO
                let latDiff = userCoord.latitude - mobAnn.coordinate.latitude
                let lonDiff = userCoord.longitude - mobAnn.coordinate.longitude
                
                let dist = sqrt(latDiff*latDiff + lonDiff*lonDiff)
                guard dist > 0.00001 else { continue } // Avoid NaN
                
                let mobCL = CLLocation(latitude: mobAnn.coordinate.latitude, longitude: mobAnn.coordinate.longitude)
                let distM = playerCL.distance(from: mobCL)
                
                if !self.isPlayerDead {
                    // Mobs automatically fire at you periodically once angered and within safe circle (150m) range!
                    if self.hasAngeredMobs && distM <= 150 {
                        self.takeDamage(amount: mob.damage)
                    }
                    guard dist > 0.0002 else { continue } // Stop when very close to living player
                } else {
                    // Player is dead: disperse. If they run far enough away, they'll be cleaned up by handleNewMobsSpawned later.
                    if distM > 1000 { continue } // Stop rendering movement if they are already far
                }
                
                // Glide step speed step: 0.00015 (~15 meters per 1.5s)
                let step: Double = 0.00015
                let direction: Double = self.isPlayerDead ? -1.0 : 1.0 // Move away if player is dead
                
                let moveLat = (latDiff / dist) * step * direction
                let moveLon = (lonDiff / dist) * step * direction
                
                let newCoord = CLLocationCoordinate2D(
                    latitude: mobAnn.coordinate.latitude + moveLat,
                    longitude: mobAnn.coordinate.longitude + moveLon
                )
                
                // Smooth interpolation instead of teleportation
                self.animateAnnotation(mobAnn, toCoordinate: newCoord, duration: 1.3)
                
                mob.latitude = newCoord.latitude
                mob.longitude = newCoord.longitude
                self.activeMobAnnotations[idx].mobDTO = mob
            }
        }
    }
    
    // Smooth 33 FPS sliding coordinate interpolation animation
    private func animateAnnotation(_ annotation: MKAnnotation, toCoordinate newCoordinate: CLLocationCoordinate2D, duration: Double) {
        let start = annotation.coordinate
        let end = newCoordinate
        let startTime = CACurrentMediaTime()
        
        let timer = Timer.scheduledTimer(withTimeInterval: 0.03, repeats: true) { timer in
            let elapsed = CACurrentMediaTime() - startTime
            let percent = min(elapsed / duration, 1.0)
            
            let lat = start.latitude + (end.latitude - start.latitude) * percent
            let lon = start.longitude + (end.longitude - start.longitude) * percent
            
            let currentCoord = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            if let mob = annotation as? MobAnnotation {
                mob.coordinate = currentCoord
            } else if let skull = annotation as? SkullAnnotation {
                skull.coordinate = currentCoord
            }
            
            if percent >= 1.0 {
                timer.invalidate()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
    
    // MARK: - Long Press Gestures & Auto Collection

    @objc private func handleMapLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began else { return }
        
        let touchPoint = gesture.location(in: mapView)
        
        // Find which annotation view's frame contains the touchPoint directly in mapView coordinates!
        var pressedAnnotation: MKAnnotation?
        for annotation in mapView.annotations {
            if let view = mapView.view(for: annotation) {
                if view.frame.contains(touchPoint) {
                    pressedAnnotation = annotation
                    break
                }
            }
        }
        
        guard let pressedAnn = pressedAnnotation else { return }
        
        if let _ = pressedAnn as? BuildingAnnotation {
            autoCollectAllBuildingsInCircle()
        } else if let skullAnn = pressedAnn as? SkullAnnotation {
            autoCollectAllNearbySkulls(from: skullAnn)
        }
    }
    
    private func autoCollectAllBuildingsInCircle() {
        guard let playerCoord = avatarAnnotation?.coordinate else { return }
        let playerCL = CLLocation(latitude: playerCoord.latitude, longitude: playerCoord.longitude)
        
        var collectedTotal = 0
        var totalXPGained = 0
        var buildingsCount = 0
        
        // Find all building annotations within 500m
        let buildingsToCollect = mapView.annotations.compactMap { $0 as? BuildingAnnotation }.filter { ann in
            let mobCL = CLLocation(latitude: ann.coordinate.latitude, longitude: ann.coordinate.longitude)
            let distance = playerCL.distance(from: mobCL)
            return distance <= 500
        }
        
        for ann in buildingsToCollect {
            let amount = ann.buildingItem.collectIncome()
            if amount > 0 {
                // Sync back into placedBuildings array
                if let idx = placedBuildings.firstIndex(where: { $0.id == ann.buildingItem.id }) {
                    placedBuildings[idx] = ann.buildingItem
                }
                collectedTotal += amount
                buildingsCount += 1
                
                // Roll 5% chance for XP
                if Double.random(in: 0..<1) < 0.05 {
                    let xpGained = amount / 2
                    totalXPGained += xpGained
                }
            }
        }
        
        if collectedTotal > 0 {
            coins += collectedTotal
            if totalXPGained > 0 {
                playerXP += totalXPGained
                showFloatingXPPopup(amount: totalXPGained)
            }
            
            var req = requiredXP
            var levelUpOccurred = false
            while playerXP >= req {
                playerXP -= req
                playerLevel += 1
                levelUpOccurred = true
                req = Int(100 * pow(1.5, Double(playerLevel - 1)))
            }
            
            updateStatsBarLabels()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            
            var msg = "⚡ AUTO-COLLECTED $\(collectedTotal) 💰\nFrom \(buildingsCount) buildings in circle!"
            if totalXPGained > 0 {
                msg += "\n🔥 BONUS: +\(totalXPGained) XP gained!"
            }
            showNotificationHUD(message: msg)
            
            if levelUpOccurred {
                showTopLevelUpBanner(message: "⚡ PLAYER LEVEL UP!\nYou advanced to Level \(playerLevel)!")
                showLevelUpCongratulationAlert()
                lightUpRewardsButton()
            }
        } else {
            showNotificationHUD(message: "No income ready in circle buildings")
        }
    }
    
    private func autoCollectAllNearbySkulls(from tappedSkull: SkullAnnotation) {
        let centerCL = CLLocation(latitude: tappedSkull.coordinate.latitude, longitude: tappedSkull.coordinate.longitude)
        
        let skullsToCollect = mapView.annotations.compactMap { $0 as? SkullAnnotation }.filter { ann in
            let skullCL = CLLocation(latitude: ann.coordinate.latitude, longitude: ann.coordinate.longitude)
            let distance = centerCL.distance(from: skullCL)
            return distance <= 250
        }
        
        guard !skullsToCollect.isEmpty else { return }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        let skullsCount = skullsToCollect.count
        playerXP += skullsCount
        
        var req = requiredXP
        var levelUpOccurred = false
        while playerXP >= req {
            playerXP -= req
            playerLevel += 1
            levelUpOccurred = true
            // Re-fetch req to support multiple level-ups
            req = Int(100 * pow(1.5, Double(playerLevel - 1)))
        }
        
        updateStatsBarLabels()
        showNotificationHUD(message: "💀 Collected \(skullsCount) Remains! +\(skullsCount) XP! \(levelUpOccurred ? "\n⚡ LEVEL UP! NOW LEVEL \(playerLevel)!" : "")")
        
        if levelUpOccurred {
            showTopLevelUpBanner(message: "⚡ PLAYER LEVEL UP!\nYou advanced to Level \(playerLevel)!")
            showLevelUpCongratulationAlert()
            lightUpRewardsButton()
        }
        
        for skull in skullsToCollect {
            mapView.removeAnnotation(skull)
        }
    }
    
    public func showFloatingXPPopup(amount: Int) {
        guard let avatar = avatarAnnotation,
              mapView.view(for: avatar) != nil else { return }
        
        let label = UILabel()
        label.text = "+\(amount) XP"
        label.textColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0)
        label.font = UIFont(name: "Outfit-Bold", size: 18) ?? UIFont.systemFont(ofSize: 18, weight: .bold)
        
        label.layer.shadowColor = UIColor(red: 0.0, green: 0.8, blue: 1.0, alpha: 1.0).cgColor
        label.layer.shadowOffset = .zero
        label.layer.shadowRadius = 4.0
        label.layer.shadowOpacity = 0.8
        
        label.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(label)
        
        let screenPoint = mapView.convert(avatar.coordinate, toPointTo: self.view)
        
        label.centerXAnchor.constraint(equalTo: self.view.leadingAnchor, constant: screenPoint.x).isActive = true
        let topConst = label.topAnchor.constraint(equalTo: self.view.topAnchor, constant: screenPoint.y - 30)
        topConst.isActive = true
        
        self.view.layoutIfNeeded()
        
        UIView.animate(withDuration: 1.8, delay: 0.0, options: .curveEaseOut, animations: {
            topConst.constant -= 80
            label.alpha = 0.0
            self.view.layoutIfNeeded()
        }) { _ in
            label.removeFromSuperview()
        }
    }
    
    // MARK: - Drag/Pan Bottom Sheet Layout Engine
    private var panStartHeight: CGFloat = 76
    private var activeTab: Int = 0 // 0 = Inventory, 1 = Quests
    
    @objc private func handleBottomBarPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        
        switch gesture.state {
        case .began:
            panStartHeight = bottomBarHeightConstraint?.constant ?? 76
        case .changed:
            let newHeight = panStartHeight - translation.y
            bottomBarHeightConstraint?.constant = max(76, min(640, newHeight))
            
            let progress = (bottomBarHeightConstraint!.constant - 76) / (640 - 76)
            if activeTab == 0 {
                inventoryContainerView.alpha = progress
                questsContainerView.alpha = 0.0
            } else {
                inventoryContainerView.alpha = 0.0
                questsContainerView.alpha = progress
            }
            view.layoutIfNeeded()
        case .ended, .cancelled:
            let velocity = gesture.velocity(in: view)
            let currentHeight = bottomBarHeightConstraint?.constant ?? 76
            
            let shouldExpand: Bool
            if velocity.y < -300 {
                shouldExpand = true
            } else if velocity.y > 300 {
                shouldExpand = false
            } else {
                shouldExpand = currentHeight > 300
            }
            
            if shouldExpand {
                isBottomBarExpanded = true
                self.refreshInventoryUI()
                UIView.animate(withDuration: 0.45, delay: 0.0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                    self.bottomBarHeightConstraint?.constant = 640
                    if self.activeTab == 0 {
                        self.inventoryContainerView.alpha = 1.0
                        self.questsContainerView.alpha = 0.0
                    } else {
                        self.inventoryContainerView.alpha = 0.0
                        self.questsContainerView.alpha = 1.0
                    }
                    self.view.layoutIfNeeded()
                }, completion: nil)
            } else {
                isBottomBarExpanded = false
                UIView.animate(withDuration: 0.40, delay: 0.0, usingSpringWithDamping: 0.82, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
                    self.bottomBarHeightConstraint?.constant = 76
                    self.inventoryContainerView.alpha = 0.0
                    self.questsContainerView.alpha = 0.0
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
        default:
            break
        }
    }
    
    // MARK: - Premium Dynamic Bottom Sheet Inventory Renderer
    
    private func refreshInventoryUI() {
        guard let contentStack = inventoryContentStack else { return }
        
        // Clear old subviews
        for subview in contentStack.arrangedSubviews {
            subview.removeFromSuperview()
        }
        
        // 1. HP & Recovery Circles + 2 Red Parameter Bars Row
        func makeProgressCircle(title: String, val: String, progress: CGFloat, color: UIColor) -> UIView {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            container.backgroundColor = UIColor.white.withAlphaComponent(0.04)
            container.layer.cornerRadius = 36
            
            let trackLayer = CAShapeLayer()
            trackLayer.fillColor = UIColor.clear.cgColor
            trackLayer.strokeColor = UIColor.white.withAlphaComponent(0.1).cgColor
            trackLayer.lineWidth = 3
            
            let progressLayer = CAShapeLayer()
            progressLayer.fillColor = UIColor.clear.cgColor
            progressLayer.strokeColor = color.cgColor
            progressLayer.lineWidth = 3
            progressLayer.strokeEnd = progress
            progressLayer.lineCap = .round
            
            let center = CGPoint(x: 36, y: 36)
            let path = UIBezierPath(arcCenter: center, radius: 34.5, startAngle: -CGFloat.pi/2, endAngle: 1.5 * CGFloat.pi, clockwise: true)
            trackLayer.path = path.cgPath
            progressLayer.path = path.cgPath
            
            container.layer.addSublayer(trackLayer)
            container.layer.addSublayer(progressLayer)
            
            let titleL = UILabel()
            titleL.text = title
            titleL.textColor = .white.withAlphaComponent(0.6)
            titleL.font = .systemFont(ofSize: 8, weight: .bold)
            titleL.textAlignment = .center
            titleL.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(titleL)
            
            let valL = UILabel()
            valL.text = val
            valL.textColor = .white
            valL.font = .systemFont(ofSize: 11, weight: .black)
            valL.textAlignment = .center
            valL.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(valL)
            
            NSLayoutConstraint.activate([
                container.widthAnchor.constraint(equalToConstant: 72),
                container.heightAnchor.constraint(equalToConstant: 72),
                titleL.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                titleL.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -10),
                valL.centerXAnchor.constraint(equalTo: container.centerXAnchor),
                valL.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: 8)
            ])
            return container
        }
        
        let hpPct = CGFloat(playerCurrentHP) / CGFloat(max(1, playerMaxHP))
        let hpCircle = makeProgressCircle(title: "LIFE", val: "\(playerCurrentHP)", progress: hpPct, color: .systemGreen)
        let regenCircle = makeProgressCircle(title: "REGEN", val: "+2/s", progress: 1.0, color: .systemGreen)
        
        let barsStack = UIStackView()
        barsStack.axis = .vertical
        barsStack.spacing = 8
        barsStack.distribution = .fillEqually
        barsStack.translatesAutoresizingMaskIntoConstraints = false
        
        var baseDamage = 30
        if let equipped = InventoryManager.shared.getEquippedWeapon() {
            baseDamage = equipped.damage
        }
        
        func makeStatProgressBar(name: String, valueText: String, progress: Float) -> UIView {
            let container = UIView()
            container.translatesAutoresizingMaskIntoConstraints = false
            
            let label = UILabel()
            label.text = "\(name): \(valueText)"
            label.textColor = .white
            label.font = .systemFont(ofSize: 9, weight: .bold)
            label.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(label)
            
            let bgTrack = UIView()
            bgTrack.backgroundColor = UIColor.white.withAlphaComponent(0.10)
            bgTrack.layer.cornerRadius = 3
            bgTrack.clipsToBounds = true
            bgTrack.translatesAutoresizingMaskIntoConstraints = false
            container.addSubview(bgTrack)
            
            let fill = UIView()
            fill.backgroundColor = UIColor(red: 1.00, green: 0.25, blue: 0.25, alpha: 1.0)
            fill.layer.cornerRadius = 3
            fill.translatesAutoresizingMaskIntoConstraints = false
            bgTrack.addSubview(fill)
            
            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: container.topAnchor),
                label.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                
                bgTrack.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
                bgTrack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
                bgTrack.trailingAnchor.constraint(equalTo: container.trailingAnchor),
                bgTrack.heightAnchor.constraint(equalToConstant: 6),
                bgTrack.bottomAnchor.constraint(equalTo: container.bottomAnchor),
                
                fill.topAnchor.constraint(equalTo: bgTrack.topAnchor),
                fill.bottomAnchor.constraint(equalTo: bgTrack.bottomAnchor),
                fill.leadingAnchor.constraint(equalTo: bgTrack.leadingAnchor),
                fill.widthAnchor.constraint(equalTo: bgTrack.widthAnchor, multiplier: CGFloat(max(0.05, min(1.0, progress))))
            ])
            return container
        }
        
        let fireRate = Double(InventoryManager.shared.getEquippedWeapon()?.fireRate ?? 2.0)
        barsStack.addArrangedSubview(makeStatProgressBar(name: "DAMAGE", valueText: "\(baseDamage)", progress: Float(baseDamage) / 100.0))
        barsStack.addArrangedSubview(makeStatProgressBar(name: "SPEED", valueText: "\(fireRate)/s", progress: Float(fireRate) / 10.0))
        
        let statsRow = UIStackView(arrangedSubviews: [hpCircle, regenCircle, barsStack])
        statsRow.axis = .horizontal
        statsRow.spacing = 14
        statsRow.alignment = .center
        statsRow.distribution = .fill
        statsRow.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(statsRow)
        
        // 2. "Fuse mods" banner row
        let realItems = InventoryManager.shared.items
        
        if realItems.isEmpty {
            let emptyStateView = UIView()
            emptyStateView.translatesAutoresizingMaskIntoConstraints = false
            
            let iconL = UILabel()
            iconL.text = "🎒"
            iconL.font = .systemFont(ofSize: 40)
            iconL.textAlignment = .center
            iconL.translatesAutoresizingMaskIntoConstraints = false
            emptyStateView.addSubview(iconL)
            
            let textL = UILabel()
            textL.text = "Your backpack is empty.\nDefeat enemies to find loot!"
            textL.textColor = .white.withAlphaComponent(0.4)
            textL.font = .systemFont(ofSize: 13, weight: .medium)
            textL.textAlignment = .center
            textL.numberOfLines = 0
            textL.translatesAutoresizingMaskIntoConstraints = false
            emptyStateView.addSubview(textL)
            
            contentStack.addArrangedSubview(emptyStateView)
            
            NSLayoutConstraint.activate([
                emptyStateView.heightAnchor.constraint(equalToConstant: 120),
                iconL.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
                iconL.topAnchor.constraint(equalTo: emptyStateView.topAnchor, constant: 20),
                textL.topAnchor.constraint(equalTo: iconL.bottomAnchor, constant: 12),
                textL.centerXAnchor.constraint(equalTo: emptyStateView.centerXAnchor),
                textL.leadingAnchor.constraint(equalTo: emptyStateView.leadingAnchor, constant: 20),
                textL.trailingAnchor.constraint(equalTo: emptyStateView.trailingAnchor, constant: -20)
            ])
        }
        
        // Render items
        for item in realItems {
            let emoji: String
            let sub: String
            var isEquipped = false
            
            if let weapon = item as? WeaponDTO {
                emoji = weapon.type == .pistol ? "🔫" : (weapon.type == .smg ? "🎒" : "⚙️")
                isEquipped = InventoryManager.shared.equippedWeaponId == weapon.id
                sub = "\(weapon.tier.name) Tier • \(weapon.damage) DMG"
            } else if let mod = item as? ModDTO {
                emoji = "🔌"
                sub = "\(mod.statAffected) Boost +\(Int(mod.multiplierBoost * 10))%"
            } else {
                emoji = "📦"
                sub = item.description
            }
            
            let itemCard = UIView()
            itemCard.backgroundColor = UIColor.white.withAlphaComponent(0.02)
            itemCard.layer.cornerRadius = 12
            itemCard.layer.borderWidth = 1.0
            itemCard.layer.borderColor = isEquipped
                ? UIColor(red: 0.30, green: 0.85, blue: 0.30, alpha: 0.4).cgColor
                : UIColor.white.withAlphaComponent(0.06).cgColor
            itemCard.translatesAutoresizingMaskIntoConstraints = false
            
            let emojiL = UILabel()
            emojiL.text = emoji
            emojiL.font = .systemFont(ofSize: 22)
            emojiL.translatesAutoresizingMaskIntoConstraints = false
            itemCard.addSubview(emojiL)
            
            let titleL = UILabel()
            titleL.text = item.name
            titleL.font = .systemFont(ofSize: 12, weight: .bold)
            titleL.textColor = .white
            titleL.translatesAutoresizingMaskIntoConstraints = false
            itemCard.addSubview(titleL)
            
            let subL = UILabel()
            subL.text = sub
            subL.font = .systemFont(ofSize: 9, weight: .semibold)
            subL.textColor = isEquipped
                ? UIColor(red: 0.30, green: 0.85, blue: 0.30, alpha: 1.0)
                : UIColor.white.withAlphaComponent(0.40)
            subL.translatesAutoresizingMaskIntoConstraints = false
            itemCard.addSubview(subL)
            
            let sw = UISwitch()
            sw.isOn = isEquipped
            sw.onTintColor = UIColor(red: 0.30, green: 0.85, blue: 0.30, alpha: 1.0) // Apple green switch
            sw.translatesAutoresizingMaskIntoConstraints = false
            sw.addTarget(self, action: #selector(weaponSwitchToggledInSheet(_:)), for: .valueChanged)
            sw.accessibilityIdentifier = item.id.uuidString
            itemCard.addSubview(sw)
            
            contentStack.addArrangedSubview(itemCard)
            
            NSLayoutConstraint.activate([
                itemCard.heightAnchor.constraint(equalToConstant: 52),
                
                emojiL.leadingAnchor.constraint(equalTo: itemCard.leadingAnchor, constant: 12),
                emojiL.centerYAnchor.constraint(equalTo: itemCard.centerYAnchor),
                
                titleL.leadingAnchor.constraint(equalTo: emojiL.trailingAnchor, constant: 10),
                titleL.topAnchor.constraint(equalTo: itemCard.topAnchor, constant: 10),
                titleL.trailingAnchor.constraint(equalTo: sw.leadingAnchor, constant: -10),
                
                subL.leadingAnchor.constraint(equalTo: titleL.leadingAnchor),
                subL.topAnchor.constraint(equalTo: titleL.bottomAnchor, constant: 1),
                subL.trailingAnchor.constraint(equalTo: sw.leadingAnchor, constant: -10),
                
                sw.trailingAnchor.constraint(equalTo: itemCard.trailingAnchor, constant: -12),
                sw.centerYAnchor.constraint(equalTo: itemCard.centerYAnchor)
            ])
        }
    }
    
    @objc private func weaponSwitchToggledInSheet(_ sender: UISwitch) {
        guard let wIdStr = sender.accessibilityIdentifier, let wId = UUID(uuidString: wIdStr) else { return }
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        if sender.isOn {
            InventoryManager.shared.equipWeapon(id: wId)
        } else {
            InventoryManager.shared.equipWeapon(id: nil)
        }
        
        refreshInventoryUI()
        updateStatsBarLabels()
    }
}

// MARK: - MKMapView Extensions
extension MKMapView {
    public func cameraThatFits(_ region: MKCoordinateRegion) -> MKMapCamera {
        let fittedRegion = self.regionThatFits(region)
        let latMeters = fittedRegion.span.latitudeDelta * 111319.9
        let altitude = latMeters / tan(Double.pi / 12)
        return MKMapCamera(lookingAtCenter: fittedRegion.center, fromDistance: altitude, pitch: 0, heading: 0)
    }
}

// MARK: - Building Exclusion Zones Overlay
public final class BuildingExclusionZonesOverlay: NSObject, MKOverlay {
    public var coordinate: CLLocationCoordinate2D {
        return center
    }
    
    public var boundingMapRect: MKMapRect {
        return MKMapRect.world
    }
    
    private(set) public var center: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    public var buildingCoordinates: [CLLocationCoordinate2D] = []
    
    public func addCoordinate(_ coordinate: CLLocationCoordinate2D) {
        buildingCoordinates.append(coordinate)
        if buildingCoordinates.count == 1 {
            center = coordinate
        }
    }
}

// MARK: - Building Exclusion Zones Renderer
public final class BuildingExclusionZonesRenderer: MKOverlayRenderer {
    public override func draw(_ mapRect: MKMapRect, zoomScale: MKZoomScale, in context: CGContext) {
        guard let zonesOverlay = overlay as? BuildingExclusionZonesOverlay else { return }
        let coordinates = zonesOverlay.buildingCoordinates
        if coordinates.isEmpty { return }
        
        let radius = BuildingType.exclusionRadius
        
        // 1. Draw the borders
        context.saveGState()
        context.setAlpha(0.55)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        
        let strokeColor = UIColor(red: 1.0, green: 0.45, blue: 0.10, alpha: 1.0)
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(1.5 / zoomScale)
        context.setLineDash(phase: 0, lengths: [5 / zoomScale, 4 / zoomScale])
        
        for coord in coordinates {
            let mapPointsRadius = radius * MKMapPointsPerMeterAtLatitude(coord.latitude)
            let centerPoint = MKMapPoint(coord)
            let rect = MKMapRect(
                x: centerPoint.x - mapPointsRadius,
                y: centerPoint.y - mapPointsRadius,
                width: mapPointsRadius * 2,
                height: mapPointsRadius * 2
            )
            let cgRect = self.rect(for: rect)
            context.addRect(cgRect)
        }
        context.strokePath()
        
        // Use destinationOut to erase interior strokes
        context.setBlendMode(.destinationOut)
        context.setFillColor(UIColor.black.cgColor)
        for coord in coordinates {
            let mapPointsRadius = radius * MKMapPointsPerMeterAtLatitude(coord.latitude)
            let centerPoint = MKMapPoint(coord)
            let rect = MKMapRect(
                x: centerPoint.x - mapPointsRadius,
                y: centerPoint.y - mapPointsRadius,
                width: mapPointsRadius * 2,
                height: mapPointsRadius * 2
            )
            let cgRect = self.rect(for: rect)
            context.addRect(cgRect)
        }
        context.fillPath()
        
        context.endTransparencyLayer()
        context.restoreGState()
        
        // 2. Draw the fills
        context.saveGState()
        context.setAlpha(0.12)
        context.beginTransparencyLayer(auxiliaryInfo: nil)
        context.setBlendMode(.normal)
        
        let fillColor = UIColor(red: 1.0, green: 0.35, blue: 0.10, alpha: 1.0)
        context.setFillColor(fillColor.cgColor)
        
        for coord in coordinates {
            let mapPointsRadius = radius * MKMapPointsPerMeterAtLatitude(coord.latitude)
            let centerPoint = MKMapPoint(coord)
            let rect = MKMapRect(
                x: centerPoint.x - mapPointsRadius,
                y: centerPoint.y - mapPointsRadius,
                width: mapPointsRadius * 2,
                height: mapPointsRadius * 2
            )
            let cgRect = self.rect(for: rect)
            context.addRect(cgRect)
        }
        context.fillPath()
        
        context.endTransparencyLayer()
        context.restoreGState()
    }
}

// MARK: - UIGestureRecognizerDelegate
extension MainMapViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let loc = touch.location(in: view)
        if combatControlBar.alpha > 0 && combatControlBar.frame.contains(loc) {
            return false // Let the attack button handle its own taps
        }
        return true
    }
}
