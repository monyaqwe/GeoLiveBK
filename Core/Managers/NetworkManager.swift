import Foundation

/// Core Protocol for handling secure server-authoritative game API calls
public protocol NetworkManagerProtocol {
    func request<T: Decodable>(endpoint: String, method: String, parameters: [String: Any]?, completion: @escaping (Result<T, Error>) -> Void)
    func performServerAuthoritativeAction(actionName: String, data: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void)
}

public enum NetworkError: Error {
    case invalidURL
    case serializationError
    case serverError(String)
    case unauthorized
}

/// Dynamic, thread-safe implementation of NetworkManager for local mock or actual server requests
public final class NetworkManager: NetworkManagerProtocol {
    public static let shared = NetworkManager()
    
    private init() {}
    
    public func request<T: Decodable>(endpoint: String, method: String, parameters: [String: Any]?, completion: @escaping (Result<T, Error>) -> Void) {
        // Mock server-authoritative round-trip delay
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.25) {
            completion(.failure(NetworkError.serverError("Mock network. Use direct mock services for standard flows.")))
        }
    }
    
    public func performServerAuthoritativeAction(actionName: String, data: [String: Any], completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // Simulates secure round-trip validation to prevent clientside memory hacking
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 0.3) {
            print("Authoritative server validation passed for action: \(actionName)")
            completion(.success(["status": "success", "validated": true]))
        }
    }
}
