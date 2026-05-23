import UIKit

final class NicknameEntryViewController: UIViewController {
    
    private let selectedGender: Gender
    private let avatarImage: UIImage?
    private let onContinue: (String) -> Void
    private let onCancel: () -> Void
    
    // UI Constraints
    private var continueButtonBottomConstraint: NSLayoutConstraint?
    
    // UI Elements
    private let backgroundContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
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
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "NAME YOUR AVATAR"
        label.font = UIFont.systemFont(ofSize: 22, weight: .black)
        label.textColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "How should others in GeoLive see you?"
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor(red: 0.25, green: 0.30, blue: 0.40, alpha: 1.0)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let textFieldContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 25
        view.layer.borderWidth = 2.0
        view.layer.borderColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.85).cgColor
        
        // Add premium distinct shadow to lift from the background
        view.layer.shadowColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.15).cgColor
        view.layer.shadowOpacity = 1.0
        view.layer.shadowOffset = CGSize(width: 0, height: 6)
        view.layer.shadowRadius = 12
        view.layer.masksToBounds = false
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private let nicknameTextField: UITextField = {
        let textField = UITextField()
        
        let placeholderColor = UIColor(red: 0.35, green: 0.40, blue: 0.50, alpha: 0.8)
        textField.attributedPlaceholder = NSAttributedString(
            string: "Enter nickname",
            attributes: [NSAttributedString.Key.foregroundColor: placeholderColor]
        )
        
        textField.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        textField.textColor = UIColor(red: 0.05, green: 0.10, blue: 0.20, alpha: 1.0)
        textField.textAlignment = .center
        textField.autocorrectionType = .no
        textField.returnKeyType = .continue
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private let continueButton: UIButton = {
        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        let title = "CONTINUE"
        let attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 16, weight: .black)
        ]
        button.setAttributedTitle(NSAttributedString(string: title, attributes: attributes), for: .normal)
        
        button.backgroundColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 1.0)
        button.layer.cornerRadius = 25
        button.layer.shadowColor = UIColor(red: 0.05, green: 0.40, blue: 0.95, alpha: 0.4).cgColor
        button.layer.shadowOpacity = 1.0
        button.layer.shadowOffset = CGSize(width: 0, height: 6)
        button.layer.shadowRadius = 12
        button.tintColor = .white
        return button
    }()
    
    private let backButton: UIButton = {
        let button = UIButton(type: .system)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.tintColor = UIColor(red: 0.08, green: 0.12, blue: 0.20, alpha: 1.0)
        
        let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .bold)
        let icon = UIImage(systemName: "chevron.left", withConfiguration: config)
        button.setImage(icon, for: .normal)
        
        button.backgroundColor = UIColor.white.withAlphaComponent(0.60)
        button.layer.cornerRadius = 20
        button.layer.borderWidth = 1.0
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.40).cgColor
        button.clipsToBounds = true
        return button
    }()
    
    init(gender: Gender, avatarImage: UIImage?, onContinue: @escaping (String) -> Void, onCancel: @escaping () -> Void) {
        self.selectedGender = gender
        self.avatarImage = avatarImage
        self.onContinue = onContinue
        self.onCancel = onCancel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
        loadAvatar()
        
        // Add gesture to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        // Listen to keyboard events to adjust layout
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        backgroundContainerView.frame = view.bounds
    }
    
    private func setupUI() {
        view.backgroundColor = .clear
        setupBackground()
        
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(subtitleLabel)
        
        view.addSubview(previewContainer)
        previewContainer.addSubview(mannequinImageView)
        
        view.addSubview(textFieldContainer)
        textFieldContainer.addSubview(nicknameTextField)
        
        view.addSubview(continueButton)
        
        let bottomConstraint = continueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30)
        self.continueButtonBottomConstraint = bottomConstraint
        
        let previewBottomConstraint = previewContainer.bottomAnchor.constraint(equalTo: textFieldContainer.topAnchor, constant: -30)
        previewBottomConstraint.priority = .defaultHigh
        
        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            backButton.widthAnchor.constraint(equalToConstant: 40),
            backButton.heightAnchor.constraint(equalToConstant: 40),
            
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            subtitleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            previewContainer.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 20),
            previewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            previewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            previewBottomConstraint,
            
            mannequinImageView.centerXAnchor.constraint(equalTo: previewContainer.centerXAnchor),
            mannequinImageView.centerYAnchor.constraint(equalTo: previewContainer.centerYAnchor),
            mannequinImageView.widthAnchor.constraint(equalTo: previewContainer.widthAnchor),
            mannequinImageView.heightAnchor.constraint(equalTo: previewContainer.heightAnchor),
            
            textFieldContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            textFieldContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            textFieldContainer.bottomAnchor.constraint(equalTo: continueButton.topAnchor, constant: -24),
            textFieldContainer.topAnchor.constraint(greaterThanOrEqualTo: subtitleLabel.bottomAnchor, constant: 20),
            textFieldContainer.heightAnchor.constraint(equalToConstant: 56),
            
            nicknameTextField.topAnchor.constraint(equalTo: textFieldContainer.topAnchor),
            nicknameTextField.leadingAnchor.constraint(equalTo: textFieldContainer.leadingAnchor, constant: 16),
            nicknameTextField.trailingAnchor.constraint(equalTo: textFieldContainer.trailingAnchor, constant: -16),
            nicknameTextField.bottomAnchor.constraint(equalTo: textFieldContainer.bottomAnchor),
            
            continueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            continueButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            bottomConstraint,
            continueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func setupBackground() {
        view.addSubview(backgroundContainerView)
        
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let blob1 = UIView()
        blob1.backgroundColor = UIColor(red: 0.05, green: 0.30, blue: 0.85, alpha: 0.50)
        blob1.layer.cornerRadius = 140
        blob1.frame = CGRect(x: -80, y: 100, width: 280, height: 280)
        backgroundContainerView.addSubview(blob1)
        
        let blob2 = UIView()
        blob2.backgroundColor = UIColor(red: 0.20, green: 0.60, blue: 1.00, alpha: 0.50)
        blob2.layer.cornerRadius = 140
        blob2.frame = CGRect(x: screenWidth - 200, y: screenHeight * 0.5, width: 280, height: 280)
        backgroundContainerView.addSubview(blob2)
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurView = UIVisualEffectView(effect: blurEffect)
        blurView.frame = UIScreen.main.bounds
        blurView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(blurView)
        
        let whiteOverlay = UIView(frame: UIScreen.main.bounds)
        whiteOverlay.backgroundColor = UIColor(white: 0.95, alpha: 1.0)
        whiteOverlay.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundContainerView.addSubview(whiteOverlay)
    }
    
    private func loadAvatar() {
        if let avatar = avatarImage {
            mannequinImageView.image = avatar
        } else {
            mannequinImageView.image = CharacterAssets.baseMannequin(for: selectedGender)?.customizedAvatar(
                gender: selectedGender,
                skinColor: .clear,
                hair: nil,
                hat: nil,
                glasses: nil,
                beard: nil,
                clothing: nil
            )
        }
    }
    
    private func setupActions() {
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)
        continueButton.addTarget(self, action: #selector(continueTapped), for: .touchUpInside)
        nicknameTextField.delegate = self
    }
    
    @objc private func backTapped() {
        onCancel()
    }
    
    @objc private func continueTapped() {
        guard let text = nicknameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            // Shake animation if empty
            let animation = CAKeyframeAnimation(keyPath: "transform.translation.x")
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.linear)
            animation.duration = 0.4
            animation.values = [-10.0, 10.0, -10.0, 10.0, -5.0, 5.0, -2.0, 2.0, 0.0]
            textFieldContainer.layer.add(animation, forKey: "shake")
            return
        }
        
        UIView.animate(withDuration: 0.12, animations: {
            self.continueButton.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.continueButton.transform = .identity
            }
            self.onContinue(text)
        }
    }
    
    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }
    
    // Adjust layout for keyboard
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
              let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        let safeAreaBottom = view.safeAreaInsets.bottom
        continueButtonBottomConstraint?.constant = -(keyboardSize.height - safeAreaBottom + 16)
        
        UIView.animate(withDuration: duration) {
            self.previewContainer.alpha = 0.0
            self.view.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double else { return }
        
        continueButtonBottomConstraint?.constant = -30
        
        UIView.animate(withDuration: duration) {
            self.previewContainer.alpha = 1.0
            self.view.layoutIfNeeded()
        }
    }
}

extension NicknameEntryViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        continueTapped()
        return true
    }
}
