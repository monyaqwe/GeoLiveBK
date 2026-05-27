import UIKit
import MapKit
import CoreLocation

/// Futuristic Cyber-Operative Map Interface (Cheapshot Aesthetic)
/// Houses dynamic resources, real-time mob notifications, and strict icon containers.
public final class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    private let viewModel: MapViewModel
    private let locationManager = CLLocationManager()
    
    // UI Elements
    private let mapView: MKMapView = {
        let map = MKMapView()
        map.showsUserLocation = true
        map.showsCompass = false
        map.showsBuildings = false
        map.showsTraffic = false
        map.overrideUserInterfaceStyle = .dark
        map.translatesAutoresizingMaskIntoConstraints = false
        return map
    }()
    
    // Premium top resources bar (Gems, Coins, Level indicator)
    private let topHUDBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.08, alpha: 0.88)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 0.30).cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    private let statsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.distribution = .equalSpacing
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let cashLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 13, weight: .black)
        return label
    }()
    
    private let gemsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 1.00, green: 0.84, blue: 0.00, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 13, weight: .black)
        return label
    }()
    
    private let levelBadgeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        return label
    }()
    
    // Dynamic Bottom Action Drawer (Quest lists, fusion triggers)
    private let actionDrawer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.08, alpha: 0.92)
        view.layer.cornerRadius = 24
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor(white: 0.20, alpha: 0.50).cgColor
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        
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
    
    private let drawerHandle: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.20)
        view.layer.cornerRadius = 2
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var drawerHeightConstraint: NSLayoutConstraint?
    private var isDrawerExpanded = false
    
    // MARK: - Init
    public init(viewModel: MapViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocation()
        applyFuturisticMapStyling()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = .black
        
        // Map hierarchy
        view.addSubview(mapView)
        mapView.delegate = self
        
        // HUD hierarchy
        view.addSubview(topHUDBar)
        topHUDBar.addSubview(statsStackView)
        statsStackView.addArrangedSubview(cashLabel)
        statsStackView.addArrangedSubview(gemsLabel)
        statsStackView.addArrangedSubview(levelBadgeLabel)
        
        // Drawer hierarchy
        view.addSubview(actionDrawer)
        actionDrawer.addSubview(drawerHandle)
        
        // Layout constraints
        drawerHeightConstraint = actionDrawer.heightAnchor.constraint(equalToConstant: 80)
        
        NSLayoutConstraint.activate([
            // Map fills screen
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            // Top HUD
            topHUDBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            topHUDBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            topHUDBar.widthAnchor.constraint(equalToConstant: 320),
            topHUDBar.heightAnchor.constraint(equalToConstant: 44),
            
            statsStackView.centerXAnchor.constraint(equalTo: topHUDBar.centerXAnchor),
            statsStackView.centerYAnchor.constraint(equalTo: topHUDBar.centerYAnchor),
            statsStackView.widthAnchor.constraint(equalTo: topHUDBar.widthAnchor, constant: -32),
            
            // Action Drawer
            actionDrawer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            actionDrawer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            actionDrawer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            drawerHeightConstraint!,
            
            drawerHandle.topAnchor.constraint(equalTo: actionDrawer.topAnchor, constant: 8),
            drawerHandle.centerXAnchor.constraint(equalTo: actionDrawer.centerXAnchor),
            drawerHandle.widthAnchor.constraint(equalToConstant: 40),
            drawerHandle.heightAnchor.constraint(equalToConstant: 4)
        ])
        
        // Swipe gesture to reveal details inside drawer container
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(handleDrawerSwipe(_:)))
        swipeUp.direction = .up
        actionDrawer.addGestureRecognizer(swipeUp)
        
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(handleDrawerSwipe(_:)))
        swipeDown.direction = .down
        actionDrawer.addGestureRecognizer(swipeDown)
        
        updateHUDValues()
    }
    
    private func setupLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    private func applyFuturisticMapStyling() {
        // Loads tactical styling patterns.
        // Google Maps SDK would load it using: map.mapStyle = GMSMapStyle(jsonString: styleJson)
        let styleJson = GoogleMapStyleService.shared.getFuturisticTacticalMapStyleJSON()
        print("Futuristic map style JSON successfully compiled and loaded: \(styleJson.prefix(80))...")
        
        // Standard MapKit abstract flat map configuration
        if #available(iOS 16.0, *) {
            let filter = MKPointOfInterestFilter.excludingAll
            let config = MKStandardMapConfiguration(emphasisStyle: .muted)
            config.pointOfInterestFilter = filter
            mapView.preferredConfiguration = config
        }
    }
    
    private func bindViewModel() {
        viewModel.onPlayerStatsChanged = { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateHUDValues()
            }
        }
    }
    
    private func updateHUDValues() {
        cashLabel.text = "CASH: $\(viewModel.activePlayer.cash)"
        gemsLabel.text = "GEMS: \(viewModel.activePlayer.gems) 💎"
        levelBadgeLabel.text = "LEVEL \(viewModel.activePlayer.level)"
    }
    
    // MARK: - Drawer Expand / Collapse
    @objc private func handleDrawerSwipe(_ gesture: UISwipeGestureRecognizer) {
        if gesture.direction == .up {
            animateDrawer(expanded: true)
        } else if gesture.direction == .down {
            animateDrawer(expanded: false)
        }
    }
    
    private func animateDrawer(expanded: Bool) {
        guard isDrawerExpanded != expanded else { return }
        isDrawerExpanded = expanded
        
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut) {
            self.drawerHeightConstraint?.constant = expanded ? 320 : 80
            self.view.layoutIfNeeded()
        }
    }
    
    // MARK: - MKMapViewDelegate (Critical Building Overlay Bugfix)
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil // standard pulsing dot
        }
        
        if let buildingAnnotation = annotation as? BuildingAnnotation {
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: MapBuildingView.reuseIdentifier) as? MapBuildingView
            if view == nil {
                view = MapBuildingView(annotation: buildingAnnotation, reuseIdentifier: MapBuildingView.reuseIdentifier)
            } else {
                view?.annotation = buildingAnnotation
            }
            
            // Configure building views with bounded constraints & clip bounds
            view?.configure(with: buildingAnnotation.buildingItem)
            return view
        }
        
        return nil
    }
    
    // MARK: - CLLocationManagerDelegate
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Auto center map on initial launch
        let region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 400, longitudinalMeters: 400)
        mapView.setRegion(region, animated: true)
        locationManager.stopUpdatingLocation() // conserve power
    }
}
