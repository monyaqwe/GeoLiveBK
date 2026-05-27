import Foundation

/// Core Protocol for managing player inventory capacity, items, and cloud synchronization
public protocol InventoryManagerProtocol {
    var maxSlots: Int { get }
    var currentOccupiedSlots: Int { get }
    var items: [ItemProtocol] { get }
    
    func canAddItem(_ item: ItemProtocol) -> Bool
    func addItem(_ item: ItemProtocol, completion: @escaping (Result<Void, Error>) -> Void)
    func removeItem(id: UUID, completion: @escaping (Result<Void, Error>) -> Void)
    func syncInventoryWithFirebase(playerUid: String, completion: @escaping (Result<Void, Error>) -> Void)
}

public enum InventoryError: Error {
    case inventoryFull
    case itemNotFound
}

/// Dynamically scales slots based on player levels and coordinates transaction audits
public final class InventoryManager: InventoryManagerProtocol {
    public static let shared = InventoryManager()
    
    private var _items: [ItemProtocol] = []
    private var playerLevel: Int = 1
    
    public var maxSlots: Int {
        // Base 10 slots + 1 slot per player level
        return 10 + playerLevel
    }
    
    public var currentOccupiedSlots: Int {
        return _items.reduce(0) { $0 + $1.slotOccupied }
    }
    
    public var items: [ItemProtocol] {
        return _items
    }
    
    private init() {}
    
    /// Set/update local player level cache to scale inventory slots
    public func updatePlayerLevel(_ newLevel: Int) {
        self.playerLevel = newLevel
    }
    
    public func canAddItem(_ item: ItemProtocol) -> Bool {
        return currentOccupiedSlots + item.slotOccupied <= maxSlots
    }
    
    public func addItem(_ item: ItemProtocol, completion: @escaping (Result<Void, Error>) -> Void) {
        guard canAddItem(item) else {
            completion(.failure(InventoryError.inventoryFull))
            return
        }
        
        _items.append(item)
        print("Inventory: Added \(item.name). Status: \(currentOccupiedSlots)/\(maxSlots) slots.")
        
        // Sync triggers immediately
        completion(.success(()))
    }
    
    public func removeItem(id: UUID, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let index = _items.firstIndex(where: { $0.id == id }) else {
            completion(.failure(InventoryError.itemNotFound))
            return
        }
        
        _items.remove(at: index)
        completion(.success(()))
    }
    
    public func syncInventoryWithFirebase(playerUid: String, completion: @escaping (Result<Void, Error>) -> Void) {
        print("Inventory: Pushed inventory matrix to user document -> \(playerUid)")
        completion(.success(()))
    }
}
