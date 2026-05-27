import UIKit

/// Tactical View Controller displaying scaled item grids, weapon tiers, and fusion panels
public final class InventoryViewController: UIViewController {
    
    private let viewModel: InventoryViewModel
    
    private let headerLabel: UILabel = {
        let label = UILabel()
        label.text = "TACTICAL BACKPACK"
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 18, weight: .black)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let statsLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.white.withAlphaComponent(0.60)
        label.font = UIFont.systemFont(ofSize: 12, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    public init(viewModel: InventoryViewModel = InventoryViewModel()) {
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
        view.backgroundColor = UIColor(white: 0.08, alpha: 0.95)
        
        view.addSubview(headerLabel)
        view.addSubview(statsLabel)
        
        NSLayoutConstraint.activate([
            headerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            headerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            statsLabel.topAnchor.constraint(equalTo: headerLabel.bottomAnchor, constant: 8),
            statsLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        updateInventoryDisplay()
    }
    
    private func bindViewModel() {
        viewModel.onInventoryUpdated = { [weak self] in
            DispatchQueue.main.async {
                self?.updateInventoryDisplay()
            }
        }
    }
    
    private func updateInventoryDisplay() {
        let occupied = InventoryManager.shared.currentOccupiedSlots
        let total = InventoryManager.shared.maxSlots
        statsLabel.text = "CAPACITY UTILIZATION: \(occupied) / \(total) SLOTS"
    }
}
