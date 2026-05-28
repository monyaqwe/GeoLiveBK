import UIKit

final class AuthCoordinator {
    
    private let navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let viewModel = CreateAccountViewModel()
        let viewController = CreateAccountViewController(viewModel: viewModel)
        
        // Setup closures to handle routing
        viewModel.onGoogleSignInTapped = { [weak viewController] in
            self.presentCharacterSelection(from: viewController)
        }
        
        viewModel.onAppleSignInTapped = { [weak viewController] in
            self.presentCharacterSelection(from: viewController)
        }
        
        viewModel.onTermsTapped = { [weak self] in
            self?.openWebViewController(title: "Terms of Service", urlString: "https://example.com/terms")
        }
        
        viewModel.onPrivacyTapped = { [weak self] in
            self?.openWebViewController(title: "Privacy Policy", urlString: "https://example.com/privacy")
        }
        
        navigationController.pushViewController(viewController, animated: true)
    }
    
    private func presentCharacterSelection(from viewController: UIViewController?) {
        let selectionViewModel = CharacterSelectionViewModel()
        let selectionVC = CharacterSelectionViewController(viewModel: selectionViewModel)
        
        // Present as full-screen modal to preserve absolute immersive layout
        selectionVC.modalPresentationStyle = .fullScreen
        
        selectionViewModel.onDismiss = { [weak selectionVC] in
            selectionVC?.dismiss(animated: true, completion: nil)
        }
        
        selectionViewModel.onConfirmSelection = { [weak selectionVC] gender in
            print("Confirm Selected Gender: \(gender)")
            
            var customizationVC: CharacterCustomizationViewController?
            customizationVC = CharacterCustomizationViewController(gender: gender, onSave: { [weak selectionVC] finalGender, customizedImage in
                guard let selectionVC = selectionVC,
                      let customizationVC = selectionVC.presentedViewController as? CharacterCustomizationViewController else {
                    return
                }
                
                // Bypass Operative Dashboard completely and go directly to NicknameEntryViewController!
                weak var weakNicknameVC: NicknameEntryViewController?
                let nicknameVC = NicknameEntryViewController(gender: finalGender, avatarImage: customizedImage, onContinue: { [weak selectionVC] nickname in
                    guard let selectionVC = selectionVC else { return }
                    
                    let targetVC = weakNicknameVC ?? {
                        var topVC: UIViewController = selectionVC
                        while let presented = topVC.presentedViewController {
                            topVC = presented
                        }
                        return topVC as? NicknameEntryViewController
                    }()
                    
                    guard let nicknameVC = targetVC else {
                        return
                    }
                    
                    let loadingVC = LoadingViewController(nickname: nickname, gender: finalGender, avatarImage: customizedImage, onComplete: { [weak selectionVC] in
                        
                        // Clear level rewards claimed state for a new game session!
                        UserDefaults.standard.removeObject(forKey: "GeoLive_ClaimedRewards")
                        
                        // Initialize the MainMapViewController (standard Apple Map with live location)
                        let mapVC = MainMapViewController(nickname: nickname, gender: finalGender, avatarImage: customizedImage, onDisconnect: {
                            if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                               let window = appDelegate.window {
                                let navigationController = UINavigationController()
                                let newCoordinator = AuthCoordinator(navigationController: navigationController)
                                appDelegate.appCoordinator = newCoordinator
                                newCoordinator.start()
                                window.rootViewController = navigationController
                                window.makeKeyAndVisible()
                            }
                        })
                        
                        // Replace window's root to route natively to Apple Map
                        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
                           let window = appDelegate.window {
                            selectionVC?.dismiss(animated: false, completion: nil)
                            window.rootViewController = mapVC
                            window.makeKeyAndVisible()
                        }
                    })
                    
                    loadingVC.modalPresentationStyle = .fullScreen
                    nicknameVC.present(loadingVC, animated: true, completion: nil)
                    
                }, onCancel: { [weak customizationVC] in
                    // Tapping back dismisses nickname config to return to customization
                    customizationVC?.dismiss(animated: true, completion: nil)
                })
                
                weakNicknameVC = nicknameVC
                nicknameVC.modalPresentationStyle = .fullScreen
                customizationVC.present(nicknameVC, animated: true, completion: nil)
                
            }, onCancel: { [weak selectionVC] in
                selectionVC?.dismiss(animated: true, completion: nil)
            })
            
            if let customizationVC = customizationVC {
                customizationVC.modalPresentationStyle = .fullScreen
                selectionVC?.present(customizationVC, animated: true, completion: nil)
            }
        }
        
        viewController?.present(selectionVC, animated: true, completion: nil)
    }
    
    private func openWebViewController(title: String, urlString: String) {
        // Placeholder for WebViewController
        let webVC = UIViewController()
        webVC.title = title
        webVC.view.backgroundColor = .systemBackground
        
        let label = UILabel()
        label.text = "Web View for \(title)"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        webVC.view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: webVC.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: webVC.view.centerYAnchor)
        ])
        
        navigationController.pushViewController(webVC, animated: true)
    }
}
