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
    
    // Custom Building Exclusion Zones Overlay
    public let buildingExclusionOverlay = BuildingExclusionZonesOverlay()
    
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
    
    // Shop button — opens Build Store panel
    private let shopButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let config = UIImage.SymbolConfiguration(pointSize: 18, weight: .bold)
        let icon = UIImage(systemName: "bag.fill", withConfiguration: config)
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
        label.font = UIFont.systemFont(ofSize: 13, weight: .black)
        label.textColor = UIColor(red: 0.15, green: 0.65, blue: 1.0, alpha: 1.0)
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
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
        GameQuest(id: "quest_2", title: "Expanding Influence (Place 2 Buildings)", requiredCount: 2, rewardGems: 1, isClaimed: false)
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
    private var coins: Int = 100000
    private var gems: Int = 0

    // UI Outlets for stats
    private var coinsLabel: UILabel?
    private var gemsLabel: UILabel?

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
        
        // Add header container, inventory container, and quests container to bottomBar
        bottomBar.addSubview(headerContainerView)
        bottomBar.addSubview(inventoryContainerView)
        bottomBar.addSubview(questsContainerView)
        
        // Add header views into headerContainerView
        headerContainerView.addSubview(pullHandle)
        headerContainerView.addSubview(avatarThumb)
        headerContainerView.addSubview(statusDot)
        headerContainerView.addSubview(nicknameLabel)
        headerContainerView.addSubview(levelLabel)
        
        nicknameLabel.text = nickname
        avatarThumb.image = avatarImage
        
        // Badge inside Quests Button
        questsButton.addSubview(questsBadge)
        NSLayoutConstraint.activate([
            questsBadge.topAnchor.constraint(equalTo: questsButton.topAnchor, constant: -2),
            questsBadge.trailingAnchor.constraint(equalTo: questsButton.trailingAnchor, constant: 2),
            questsBadge.widthAnchor.constraint(equalToConstant: 9),
            questsBadge.heightAnchor.constraint(equalToConstant: 9)
        ])
        
        // Quests Tab only (profile button removed)
        let tabsStackView = UIStackView(arrangedSubviews: [questsButton])
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
            nicknameLabel.bottomAnchor.constraint(equalTo: avatarThumb.centerYAnchor, constant: 1),
            
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
            
            // Quests Container
            questsContainerView.topAnchor.constraint(equalTo: headerContainerView.bottomAnchor),
            questsContainerView.leadingAnchor.constraint(equalTo: bottomBar.leadingAnchor),
            questsContainerView.trailingAnchor.constraint(equalTo: bottomBar.trailingAnchor),
            questsContainerView.bottomAnchor.constraint(equalTo: bottomBar.bottomAnchor),
            
            // Floating buttons
            centerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            centerButton.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -16),
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
        shopButton.addTarget(self, action: #selector(shopButtonTapped), for: .touchUpInside)
        storeButton.addTarget(self, action: #selector(storeButtonTapped), for: .touchUpInside)
        
        questsButton.addTarget(self, action: #selector(questsTapped), for: .touchUpInside)
        
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
            iconLabel.text = quest.requiredCount == 1 ? "🏗️" : "🏢"
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
            
            let progress = min(currentPlaced, quest.requiredCount)
            let qProgress = UILabel()
            qProgress.text = "Progress: \(progress)/\(quest.requiredCount) | Reward: \(quest.rewardGems) 💎"
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
            } else if currentPlaced >= quest.requiredCount {
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
            if !quest.isClaimed && currentPlaced >= quest.requiredCount {
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
        shopVC.modalPresentationStyle = .overFullScreen
        shopVC.modalTransitionStyle = .crossDissolve
        present(shopVC, animated: false)
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
        checkQuestsProgress()
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
        let canCollect = pending >= building.totalIncome
        let collectTitle = canCollect
            ? "COLLECT $\(pending) ⬆️"
            : "PENDING $\(pending)"
        collectBtn.setTitle(collectTitle, for: .normal)
        collectBtn.titleLabel?.font = UIFont.systemFont(ofSize: 10, weight: .black)
        collectBtn.titleLabel?.numberOfLines = 1
        collectBtn.setTitleColor(canCollect ? UIColor(white: 0.08, alpha: 1) : .white, for: .normal)
        collectBtn.backgroundColor = canCollect
            ? UIColor(red: 0.25, green: 0.85, blue: 0.45, alpha: 1.0)
            : UIColor.white.withAlphaComponent(0.10)
        collectBtn.layer.cornerRadius = 12
        collectBtn.layer.borderWidth = 1.0
        collectBtn.layer.borderColor = UIColor.white.withAlphaComponent(canCollect ? 0.0 : 0.12).cgColor
        collectBtn.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
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
        upgradeButton.titleLabel?.textAlignment = .center
        upgradeButton.setTitleColor(.white, for: .normal)
        upgradeButton.backgroundColor = UIColor(red: 0.15, green: 0.55, blue: 0.95, alpha: 1.0)
        upgradeButton.layer.cornerRadius = 14
        upgradeButton.layer.borderWidth = 1.0
        upgradeButton.layer.borderColor = UIColor.white.withAlphaComponent(0.20).cgColor
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
            staffUpgradeBtn.titleLabel?.numberOfLines = 2
            staffUpgradeBtn.titleLabel?.textAlignment = .center
            staffUpgradeBtn.setTitleColor(.white, for: .normal)
            staffUpgradeBtn.backgroundColor = UIColor(red: 0.15, green: 0.85, blue: 0.45, alpha: 1.0)
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
            equipUpgradeBtn.titleLabel?.numberOfLines = 2
            equipUpgradeBtn.titleLabel?.textAlignment = .center
            equipUpgradeBtn.setTitleColor(.white, for: .normal)
            equipUpgradeBtn.backgroundColor = UIColor(red: 0.15, green: 0.55, blue: 0.95, alpha: 1.0)
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

            collectBtn.leadingAnchor.constraint(equalTo: incomeLabel.trailingAnchor, constant: 10),
            collectBtn.centerYAnchor.constraint(equalTo: incomeLabel.centerYAnchor),

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
        updateStatsBarLabels()

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        showNotificationHUD(message: "COLLECTED $\(amount) 💰\nFrom \(annotation.buildingItem.name)!")
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

    
    // MARK: - Premium Dynamic Notification Toast & Stats
    public func updateStatsBarLabels() {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        
        if let formattedCoins = formatter.string(from: NSNumber(value: coins)) {
            coinsLabel?.text = formattedCoins
        } else {
            coinsLabel?.text = "\(coins)"
        }
        
        gemsLabel?.text = "\(gems)"
        
        UIView.animate(withDuration: 0.1, animations: {
            self.coinsLabel?.transform = CGAffineTransform(scaleX: 1.15, y: 1.15)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.coinsLabel?.transform = .identity
            }
        }
    }
    
    public func showNotificationHUD(message: String) {
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
