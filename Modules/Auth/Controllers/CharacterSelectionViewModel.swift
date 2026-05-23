import Foundation

enum Gender {
    case male
    case female
}

final class CharacterSelectionViewModel {
    
    // Bindable gender state
    private(set) var selectedGender: Gender = .male {
        didSet {
            onGenderChanged?(selectedGender)
        }
    }
    
    // Callbacks to view
    var onGenderChanged: ((Gender) -> Void)?
    
    // Callbacks to coordinator
    var onDismiss: (() -> Void)?
    var onConfirmSelection: ((Gender) -> Void)?
    
    func selectGender(_ gender: Gender) {
        selectedGender = gender
    }
    
    func confirm() {
        onConfirmSelection?(selectedGender)
    }
    
    func dismiss() {
        onDismiss?()
    }
}
