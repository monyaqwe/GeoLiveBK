import UIKit

/// High-tech cyber Store displaying weapon cases and purchaseable AI Defenders
public final class StoreViewController: UIViewController {
    
    private let viewModel: StoreViewModel
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "BLACK MARKET SUPPLY"
        label.textColor = UIColor(red: 0.00, green: 0.94, blue: 1.00, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 20, weight: .black)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let coinsLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let gemsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(red: 0.20, green: 0.80, blue: 1.00, alpha: 1.0)
        label.font = UIFont.systemFont(ofSize: 14, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public init(viewModel: StoreViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        bindViewModel()
    }
    
    private func setupUI() {
        view.backgroundColor = UIColor(white: 0.07, alpha: 0.98)
        
        view.addSubview(titleLabel)
        view.addSubview(coinsLabel)
        view.addSubview(gemsLabel)
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            coinsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            coinsLabel.trailingAnchor.constraint(equalTo: view.centerXAnchor, constant: -12),
            
            gemsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            gemsLabel.leadingAnchor.constraint(equalTo: view.centerXAnchor, constant: 12)
        ])
        
        updateCurrencies(player: viewModel.activePlayer)
    }
    
    private func bindViewModel() {
        viewModel.onCurrencyUpdated = { [weak self] player in
            DispatchQueue.main.async {
                self?.updateCurrencies(player: player)
            }
        }
        
        viewModel.onStorePurchaseSuccess = { [weak self] msg in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "SUPPLIES DELIVERED", message: msg, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self?.present(alert, animated: true)
            }
        }
        
        viewModel.onStorePurchaseFailed = { [weak self] err in
            DispatchQueue.main.async {
                let alert = UIAlertController(title: "TRANSACTION DECLINED", message: err, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "DISMISS", style: .cancel))
                self?.present(alert, animated: true)
            }
        }
    }
    
    private func updateCurrencies(player: PlayerDTO) {
        coinsLabel.text = "CASH: $\(player.cash)"
        gemsLabel.text = "GEMS: \(player.gems) 💎"
    }
}
