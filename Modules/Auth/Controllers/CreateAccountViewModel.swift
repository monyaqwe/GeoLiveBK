import Foundation

// ViewModel in MVVM-C
final class CreateAccountViewModel {
    
    // Constants for Strings (ready for future localization)
    enum Constants {
        static let title = "Create your account"
        static let subtitle = "Join the adventure."
        static let termsText = "By signing in, you agree to our Terms of Service and Privacy Policy."
        static let termsLink = "Terms of Service"
        static let privacyLink = "Privacy Policy"
    }
    
    // Callbacks for coordinator
    var onGoogleSignInTapped: (() -> Void)?
    var onAppleSignInTapped: (() -> Void)?
    var onTermsTapped: (() -> Void)?
    var onPrivacyTapped: (() -> Void)?
    
    // Methods for view to trigger
    func handleGoogleSignIn() {
        onGoogleSignInTapped?()
    }
    
    func handleAppleSignIn() {
        onAppleSignInTapped?()
    }
    
    func handleGameCenterSignIn() {
        // Method removed
    }
    
    func handleTermsTapped() {
        onTermsTapped?()
    }
    
    func handlePrivacyTapped() {
        onPrivacyTapped?()
    }
}
