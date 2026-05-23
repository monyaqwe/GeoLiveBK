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
    
    // Floating nickname bar
    private let topBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 0.10, alpha: 0.85)
        view.layer.cornerRadius = 24
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
    
    private let nicknameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = .white
        label.textAlignment = .center
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
        iv.layer.cornerRadius = 18
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(white: 0.18, alpha: 1.0)
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
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
        mapView.pointOfInterestFilter = .excludingAll
        
        // Restrict maximum zoom out to prevent heavy GPU/CPU rendering and phone load
        if #available(iOS 13.0, *) {
            let zoomRange = MKMapView.CameraZoomRange(maxCenterCoordinateDistance: 20000)
            mapView.setCameraZoomRange(zoomRange, animated: false)
        }
        
        // Apply dark map style
        if #available(iOS 16.0, *) {
            let config = MKStandardMapConfiguration(emphasisStyle: .muted)
            mapView.preferredConfiguration = config
            mapView.overrideUserInterfaceStyle = .dark
        } else {
            mapView.overrideUserInterfaceStyle = .dark
        }
        
        view.addSubview(mapView)
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.06, alpha: 1.0)
        
        // Top bar
        view.addSubview(topBar)
        topBar.addSubview(avatarThumb)
        topBar.addSubview(nicknameLabel)
        topBar.addSubview(statusDot)
        
        nicknameLabel.text = nickname
        avatarThumb.image = avatarImage
        
        // Floating buttons
        view.addSubview(centerButton)
        view.addSubview(disconnectButton)
        
        NSLayoutConstraint.activate([
            // Top bar
            topBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            topBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            topBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            topBar.heightAnchor.constraint(equalToConstant: 52),
            
            avatarThumb.leadingAnchor.constraint(equalTo: topBar.leadingAnchor, constant: 8),
            avatarThumb.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            avatarThumb.widthAnchor.constraint(equalToConstant: 36),
            avatarThumb.heightAnchor.constraint(equalToConstant: 36),
            
            statusDot.leadingAnchor.constraint(equalTo: avatarThumb.trailingAnchor, constant: 10),
            statusDot.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            statusDot.widthAnchor.constraint(equalToConstant: 10),
            statusDot.heightAnchor.constraint(equalToConstant: 10),
            
            nicknameLabel.leadingAnchor.constraint(equalTo: statusDot.trailingAnchor, constant: 8),
            nicknameLabel.trailingAnchor.constraint(equalTo: topBar.trailingAnchor, constant: -16),
            nicknameLabel.centerYAnchor.constraint(equalTo: topBar.centerYAnchor),
            
            // Center button
            centerButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            centerButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24),
            centerButton.widthAnchor.constraint(equalToConstant: 52),
            centerButton.heightAnchor.constraint(equalToConstant: 52),
            
            // Disconnect button
            disconnectButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            disconnectButton.bottomAnchor.constraint(equalTo: centerButton.topAnchor, constant: -14),
            disconnectButton.widthAnchor.constraint(equalToConstant: 52),
            disconnectButton.heightAnchor.constraint(equalToConstant: 52),
        ])
    }
    
    // MARK: - Actions
    private func setupActions() {
        centerButton.addTarget(self, action: #selector(centerOnUserTapped), for: .touchUpInside)
        disconnectButton.addTarget(self, action: #selector(disconnectTapped), for: .touchUpInside)
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
        
        // Exclude standard 0,0 placeholder coordinate unless it's explicitly desired
        guard coordinate.latitude != 0.0 || coordinate.longitude != 0.0 else { return }
        
        placeAvatarAtLocation(coordinate)
        
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
        
        if !hasInitiallyCentered {
            let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 800, longitudinalMeters: 800)
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
}
