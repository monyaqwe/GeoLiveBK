import UIKit

enum CustomizationCategory: String, CaseIterable {
    case hair = "Hair"
    case hats = "Hats"
    case glasses = "Glasses"
    case beard = "Beard"
    case clothing = "Clothing"
    
    var icon: String {
        switch self {
        case .hair: return "💇‍♂️"
        case .hats: return "👑"
        case .glasses: return "🕶️"
        case .beard: return "🧔"
        case .clothing: return "👕"
        }
    }
}

struct CustomizationOption {
    let id: String
    let name: String
    let displayEmoji: String
    let value: String // The actual asset, emoji, or style name to apply
}

final class CharacterCustomizationViewController: UIViewController {
    
    private let selectedGender: Gender
    private let onSave: (Gender, UIImage?) -> Void
    private let onCancel: () -> Void
    
    // Base Mannequin Image Loaded once
    private var baseMannequin: UIImage?
    
    // Customization State
    private var activeCategory: CustomizationCategory = .hats
    private var selectedHat: String? = nil
    private var selectedHair: String? = nil
    private var selectedGlasses: String? = nil
    private var selectedBeard: String? = nil
    private var selectedClothing: String? = nil
    
    // History Stack for Rollback
    private var historyStack: [String: String?] = [:]
    
    // Options Data Dictionary
    private var categoryOptions: [CustomizationCategory: [CustomizationOption]] = [:]
    
    // UI Elements
    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    // Preview container (fully transparent)
    private let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let mannequinImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    // Top Controls
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let icon = UIImage(systemName: "xmark", withConfiguration: config)
        button.setImage(icon, for: .normal)
        
        button.backgroundColor = UIColor.white.withAlphaComponent(0.60)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.40).cgColor
        button.clipsToBounds = true
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("Save", for: .normal)
        button.setTitleColor(UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 1.0), for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 15, weight: .black)
        
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.50).cgColor
        button.clipsToBounds = true
        
        let blurEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        blurView.isUserInteractionEnabled = false
        button.addSubview(blurView)
        button.sendSubviewToBack(blurView)
        
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: button.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: button.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: button.bottomAnchor)
        ])
        
        return button
    }()
    
    // Undo / Redo glass controls
    private let undoButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.70)
        
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        button.setImage(UIImage(systemName: "arrow.uturn.backward", withConfiguration: config), for: .normal)
        
        button.backgroundColor = UIColor.white.withAlphaComponent(0.40)
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 0.8
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.30).cgColor
        return button
    }()
    
    private let redoButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.70)
        
        let config = UIImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
        button.setImage(UIImage(systemName: "arrow.uturn.forward", withConfiguration: config), for: .normal)
        
        button.backgroundColor = UIColor.white.withAlphaComponent(0.40)
        button.layer.cornerRadius = 18
        button.layer.borderWidth = 0.8
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.30).cgColor
        return button
    }()
    
    // Bottom Sheet Customization Panel
    private let bottomPanel: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 32
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.translatesAutoresizingMaskIntoConstraints = false
        
        // Premium Apple shadow for depth
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.08
        view.layer.shadowOffset = CGSize(width: 0, height: -6)
        view.layer.shadowRadius = 16
        return view
    }()
    
    private let sheetHandle: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.80, green: 0.82, blue: 0.86, alpha: 1.0)
        view.layer.cornerRadius = 2.5
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var categoryButtons: [CustomizationCategory: UIButton] = [:]
    private let categoryScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    
    private let categoryStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 10
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    // Options grid
    private var optionsCollectionView: UICollectionView!
    
    // Initializer
    init(gender: Gender, onSave: @escaping (Gender, UIImage?) -> Void, onCancel: @escaping () -> Void) {
        self.selectedGender = gender
        self.onSave = onSave
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
        setupOptionsData()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadMannequin()
        selectCategory(.hats) // Default active category
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundContainerView.frame = view.bounds
    }
    
    private func setupOptionsData() {
        // Hats (None, Crown, Cap)
        categoryOptions[.hats] = [
            CustomizationOption(id: "hat_none", name: "None", displayEmoji: "❌", value: ""),
            CustomizationOption(id: "hat_crown", name: "Crown 👑", displayEmoji: "👑", value: "hat_crown"),
            CustomizationOption(id: "hat_cap", name: "Cap 🧢", displayEmoji: "🧢", value: "hat_cap")
        ]
        
        // Glasses (None, Aviators, Classic)
        categoryOptions[.glasses] = [
            CustomizationOption(id: "glass_none", name: "None", displayEmoji: "❌", value: ""),
            CustomizationOption(id: "glass_retro", name: "Aviators 🕶️", displayEmoji: "🕶️", value: "glass_retro"),
            CustomizationOption(id: "glass_classic", name: "Classic 👓", displayEmoji: "👓", value: "glass_classic")
        ]
        
        // Beards (None, Mustache, Full Beard) - note: will be ignored for female
        categoryOptions[.beard] = [
            CustomizationOption(id: "beard_none", name: "None", displayEmoji: "❌", value: ""),
            CustomizationOption(id: "beard_mustache", name: "Mustache 👨‍🦰", displayEmoji: "👨‍🦰", value: "beard_mustache"),
            CustomizationOption(id: "beard_full", name: "Full Beard 🧔", displayEmoji: "🧔", value: "beard_full")
        ]
        
        // Clothing (Original, Black Polo, Red Polo)
        categoryOptions[.clothing] = [
            CustomizationOption(id: "cloth_default", name: "Original", displayEmoji: "🧥", value: ""),
            CustomizationOption(id: "cloth_polo", name: "Black Polo 👕", displayEmoji: "👕", value: "cloth_polo"),
            CustomizationOption(id: "cloth_red_polo", name: "Red Polo 👔", displayEmoji: "👔", value: "cloth_red_polo")
        ]
        
        // Hair (Bald, Short, Curly)
        categoryOptions[.hair] = [
            CustomizationOption(id: "hair_none", name: "Bald", displayEmoji: "❌", value: ""),
            CustomizationOption(id: "hair_short", name: "Short 💇‍♂️", displayEmoji: "💇‍♂️", value: "hair_short"),
            CustomizationOption(id: "hair_curly", name: "Curly 🧑‍🦱", displayEmoji: "🧑‍🦱", value: "hair_curly")
        ]
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        
        // 1. Setup cohesive frosted background with blue splashes (identical to selection screen background)
        setupBackground()
        
        // 2. Add controls and previews
        view.addSubview(previewContainer)
        previewContainer.addSubview(mannequinImageView)
        
        view.addSubview(closeButton)
        view.addSubview(saveButton)
        view.addSubview(undoButton)
        view.addSubview(redoButton)
        
        // 3. Add Customization Panel
        view.addSubview(bottomPanel)
        bottomPanel.addSubview(sheetHandle)
        bottomPanel.addSubview(categoryScrollView)
        categoryScrollView.addSubview(categoryStackView)
        
        // Setup Grid Collection View
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 16
        layout.minimumInteritemSpacing = 16
        
        optionsCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        optionsCollectionView.backgroundColor = .clear
        optionsCollectionView.showsVerticalScrollIndicator = false
        optionsCollectionView.translatesAutoresizingMaskIntoConstraints = false
        optionsCollectionView.delegate = self
        optionsCollectionView.dataSource = self
        optionsCollectionView.register(CustomizationOptionCell.self, forCellWithReuseIdentifier: "OptionCell")
        bottomPanel.addSubview(optionsCollectionView)
        
        // Setup categories horizontal scroll
        for cat in CustomizationCategory.allCases {
            // Skip beard for females
            if selectedGender == .female && cat == .beard { continue }
            
            let button = UIButton(type: .custom)
            button.setTitle("\(cat.icon) \(cat.rawValue)", for: .normal)
            button.titleLabel?.font = UIFont.systemFont(ofSize: 13, weight: .bold)
            button.setTitleColor(UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.60), for: .normal)
            button.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0)
            button.layer.cornerRadius = 16
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 14, bottom: 8, right: 14)
            button.translatesAutoresizingMaskIntoConstraints = false
            button.addTarget(self, action: #selector(categoryTapped(_:)), for: .touchUpInside)
            
            categoryButtons[cat] = button
            categoryStackView.addArrangedSubview(button)
        }
        
        // 4. UI Constraints Layout
        NSLayoutConstraint.activate([
            closeButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            closeButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40),
            
            saveButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            saveButton.widthAnchor.constraint(equalToConstant: 75),
            saveButton.heightAnchor.constraint(equalToConstant: 40),
            
            // Preview container spans the top 44% of screen
            previewContainer.topAnchor.constraint(equalTo: closeButton.bottomAnchor, constant: 4),
            previewContainer.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor, constant: 6),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            mannequinImageView.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            mannequinImageView.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            mannequinImageView.widthAnchor.constraint(equalTo: previewContainer.widthAnchor, multiplier: 1.0),
            mannequinImageView.heightAnchor.constraint(equalTo: previewContainer.heightAnchor, multiplier: 1.0),
            
            // History controls placed in a clean row on the left
            undoButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            undoButton.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor, constant: -20),
            undoButton.widthAnchor.constraint(equalToConstant: 36),
            undoButton.heightAnchor.constraint(equalToConstant: 36),
            
            redoButton.leadingAnchor.constraint(equalTo: undoButton.trailingAnchor, constant: 12),
            redoButton.bottomAnchor.constraint(equalTo: bottomPanel.topAnchor, constant: -20),
            redoButton.widthAnchor.constraint(equalToConstant: 36),
            redoButton.heightAnchor.constraint(equalToConstant: 36),
            
            // Bottom Panel Curved Bottom Sheet
            bottomPanel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bottomPanel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bottomPanel.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            bottomPanel.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.50), // Spans bottom 50%
            
            sheetHandle.topAnchor.constraint(equalTo: bottomPanel.topAnchor, constant: 10),
            sheetHandle.centerXAnchor.constraint(equalTo: bottomPanel.centerXAnchor),
            sheetHandle.widthAnchor.constraint(equalToConstant: 36),
            sheetHandle.heightAnchor.constraint(equalToConstant: 5),
            
            categoryScrollView.topAnchor.constraint(equalTo: sheetHandle.bottomAnchor, constant: 14),
            categoryScrollView.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 20),
            categoryScrollView.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -20),
            categoryScrollView.heightAnchor.constraint(equalToConstant: 44),
            
            categoryStackView.topAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.topAnchor),
            categoryStackView.leadingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.leadingAnchor),
            categoryStackView.trailingAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.trailingAnchor),
            categoryStackView.bottomAnchor.constraint(equalTo: categoryScrollView.contentLayoutGuide.bottomAnchor),
            categoryStackView.heightAnchor.constraint(equalTo: categoryScrollView.frameLayoutGuide.heightAnchor),
            
            optionsCollectionView.topAnchor.constraint(equalTo: categoryScrollView.bottomAnchor, constant: 14),
            optionsCollectionView.leadingAnchor.constraint(equalTo: bottomPanel.leadingAnchor, constant: 24),
            optionsCollectionView.trailingAnchor.constraint(equalTo: bottomPanel.trailingAnchor, constant: -24),
            optionsCollectionView.bottomAnchor.constraint(equalTo: bottomPanel.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
    
    private func setupBackground() {
        view.addSubview(backgroundContainerView)
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(blurView)
        
        let whiteOverlay = UIView(frame: UIScreen.main.bounds)
        whiteOverlay.backgroundColor = UIColor(white: 0.95, alpha: 1.0) // Even light gray background to perfectly contrast the characters
        whiteOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(whiteOverlay)
    }
    
    private func loadMannequin() {
        baseMannequin = CharacterAssets.baseMannequin(for: selectedGender)
        updateOverlays(animated: false)
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)
        redoButton.addTarget(self, action: #selector(redoTapped), for: .touchUpInside)
    }
    
    private func selectCategory(_ category: CustomizationCategory) {
        activeCategory = category
        
        // Highlight active category button
        for (cat, button) in categoryButtons {
            if cat == category {
                button.backgroundColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.12)
                button.setTitleColor(UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 1.0), for: .normal)
                button.layer.borderWidth = 1.0
                button.layer.borderColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.25).cgColor
            } else {
                button.backgroundColor = UIColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0)
                button.setTitleColor(UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.60), for: .normal)
                button.layer.borderWidth = 0
            }
        }
        
        // Reload Grid
        optionsCollectionView.reloadData()
    }
    
    @objc private func categoryTapped(_ sender: UIButton) {
        for (cat, button) in categoryButtons where button == sender {
            selectCategory(cat)
            break
        }
    }
    
    @objc private func cancelTapped() {
        onCancel()
    }
    
    @objc private func saveTapped() {
        // Dynamic bounce animation on save click
        UIView.animate(withDuration: 0.12, animations: {
            self.saveButton.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.saveButton.transform = .identity
            }
            self.onSave(self.selectedGender, self.mannequinImageView.image)
        }
    }
    
    @objc private func undoTapped() {
        // Premium tactile spring feedback
        UIView.animate(withDuration: 0.1, animations: {
            self.undoButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.undoButton.transform = .identity
            })
            // Reset all overlays to original/bald/clean state as default rollback
            self.selectedHat = nil
            self.selectedHair = nil
            self.selectedGlasses = nil
            self.selectedBeard = nil
            self.selectedClothing = nil
            self.updateOverlays(animated: true)
            self.optionsCollectionView.reloadData()
        }
    }
    
    @objc private func redoTapped() {
        UIView.animate(withDuration: 0.1, animations: {
            self.redoButton.transform = CGAffineTransform(scaleX: 0.85, y: 0.85)
        }) { _ in
            UIView.animate(withDuration: 0.1, animations: {
                self.redoButton.transform = .identity
            })
        }
    }
    
    private func updateOverlays(animated: Bool) {
        let image = baseMannequin?.customizedAvatar(
            gender: selectedGender,
            skinColor: .clear,
            hair: selectedHair,
            hat: selectedHat,
            glasses: selectedGlasses,
            beard: selectedBeard,
            clothing: selectedClothing
        )
        
        let duration = animated ? 0.20 : 0.0
        if animated {
            UIView.transition(with: mannequinImageView, duration: duration, options: .transitionCrossDissolve, animations: {
                self.mannequinImageView.image = image
            }, completion: nil)
        } else {
            mannequinImageView.image = image
        }
    }
}

// MARK: - Collection View Delegate & DataSource
extension CharacterCustomizationViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return categoryOptions[activeCategory]?.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "OptionCell", for: indexPath) as? CustomizationOptionCell else {
            return UICollectionViewCell()
        }
        
        if let option = categoryOptions[activeCategory]?[indexPath.item] {
            // Check if active option is selected
            let isSelected: Bool
            switch activeCategory {
            case .hats:
                isSelected = (selectedHat == option.value) || (selectedHat == nil && option.value.isEmpty)
            case .glasses:
                isSelected = (selectedGlasses == option.value) || (selectedGlasses == nil && option.value.isEmpty)
            case .beard:
                isSelected = (selectedBeard == option.value) || (selectedBeard == nil && option.value.isEmpty)
            case .clothing:
                isSelected = (selectedClothing == option.value) || (selectedClothing == nil && option.value.isEmpty)
            case .hair:
                isSelected = (selectedHair == option.value) || (selectedHair == nil && option.value.isEmpty)
            }
            
            cell.configure(with: option, isSelected: isSelected)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let option = categoryOptions[activeCategory]?[indexPath.item] else { return }
        
        // Save current state for undo
        historyStack[activeCategory.rawValue] = option.value
        
        // Apply choice
        switch activeCategory {
        case .hats:
            selectedHat = option.value.isEmpty ? nil : option.value
        case .glasses:
            selectedGlasses = option.value.isEmpty ? nil : option.value
        case .beard:
            selectedBeard = option.value.isEmpty ? nil : option.value
        case .clothing:
            selectedClothing = option.value.isEmpty ? nil : option.value
        case .hair:
            selectedHair = option.value.isEmpty ? nil : option.value
        }
        
        collectionView.reloadData()
        updateOverlays(animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 16.0 * 3.0 // padding left, right, and middle
        let availableWidth = collectionView.frame.width - padding
        let itemWidth = availableWidth / 4.0 // 4 items per row
        return CGSize(width: itemWidth, height: itemWidth + 20)
    }
}

// MARK: - Custom Option Cell
final class CustomizationOptionCell: UICollectionViewCell {
    
    private let glassView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
        view.layer.cornerRadius = 20
        view.layer.borderWidth = 1.0
        view.layer.borderColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.08).cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let emojiLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 32)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10, weight: .bold)
        label.textColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.50)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupViews() {
        contentView.addSubview(glassView)
        glassView.addSubview(emojiLabel)
        contentView.addSubview(nameLabel)
        
        NSLayoutConstraint.activate([
            glassView.topAnchor.constraint(equalTo: contentView.topAnchor),
            glassView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            glassView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            glassView.heightAnchor.constraint(equalTo: contentView.widthAnchor),
            
            emojiLabel.centerXAnchor.constraint(equalTo: glassView.centerXAnchor),
            emojiLabel.centerYAnchor.constraint(equalTo: glassView.centerYAnchor),
            
            nameLabel.topAnchor.constraint(equalTo: glassView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            nameLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    func configure(with option: CustomizationOption, isSelected: Bool) {
        emojiLabel.text = option.displayEmoji
        nameLabel.text = option.name
        
        if isSelected {
            glassView.backgroundColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.08)
            glassView.layer.borderColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.80).cgColor
            glassView.layer.borderWidth = 1.8
            nameLabel.textColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 1.0)
            
            // Dynamic scale-pop on cell select
            UIView.animate(withDuration: 0.15, animations: {
                self.glassView.transform = CGAffineTransform(scaleX: 1.06, y: 1.06)
            })
        } else {
            glassView.backgroundColor = UIColor(red: 0.96, green: 0.97, blue: 0.98, alpha: 1.0)
            glassView.layer.borderColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.08).cgColor
            glassView.layer.borderWidth = 1.0
            nameLabel.textColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 0.50)
            glassView.transform = .identity
        }
    }
}
