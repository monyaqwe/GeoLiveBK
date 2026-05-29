import Foundation
import CoreLocation

public protocol GameWebSocketServiceDelegate: AnyObject {
    func webSocketDidConnect(welcomeMessage: String, state: PlayerState?)
    func webSocketDidReceiveOpponentsList(_ opponents: [PlayerState])
    func webSocketDidReceiveOpponentMove(_ opponent: PlayerState)
    func webSocketPlayerJoined(id: String, nickname: String, message: String)
    func webSocketPlayerLeft(id: String, nickname: String)
    func webSocketDidReceiveChat(nickname: String, message: String)
}

public final class GameWebSocketService: NSObject {
    public static let shared = GameWebSocketService()
    
    public weak var delegate: GameWebSocketServiceDelegate?
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)
    private var isConnected = false
    private var reconnectTimer: Timer?
    private var currentNickname: String = "Operative"
    
    private override init() {
        super.init()
    }
    
    public func connect(nickname: String) {
        self.currentNickname = nickname
        guard !isConnected else { return }
        
        // Generate or fetch stable unique playerId from local client storage
        var localUUID = UserDefaults.standard.string(forKey: "GeoLive_PlayerUUID")
        if localUUID == nil {
            let newUUID = UUID().uuidString
            UserDefaults.standard.set(newUUID, forKey: "GeoLive_PlayerUUID")
            localUUID = newUUID
        }
        
        // Connect to port 8082 with stable uuid and nickname
        let queryNickname = nickname.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "Operative"
        let urlString = "ws://localhost:8082/ws?nickname=\(queryNickname)&uuid=\(localUUID!)"
        guard let url = URL(string: urlString) else { return }
        
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        
        isConnected = true
        reconnectTimer?.invalidate()
        
        receiveMessages()
    }
    
    public func disconnect() {
        reconnectTimer?.invalidate()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        isConnected = false
    }
    
    // MARK: - Outgoing Actions
    
    public func sendLocation(coordinate: CLLocationCoordinate2D, hp: Int, maxHP: Int, level: Int, coins: Int, gems: Int) {
        let payload: [String: Any] = [
            "event": "player_move",
            "location": [
                "lat": coordinate.latitude,
                "lon": coordinate.longitude
            ],
            "player": [
                "id": "", // Set by server anyway
                "nickname": currentNickname,
                "location": [
                    "lat": coordinate.latitude,
                    "lon": coordinate.longitude
                ],
                "hp": hp,
                "max_hp": maxHP,
                "level": level,
                "coins": coins,
                "gems": gems
            ]
        ]
        send(json: payload)
    }
    
    public func sendAttack(targetPlayerID: String, damage: Int) {
        let payload: [String: Any] = [
            "event": "attack_player",
            "target_player_id": targetPlayerID,
            "damage": damage
        ]
        send(json: payload)
    }
    
    public func sendDestroyBuilding(buildingID: String) {
        let payload: [String: Any] = [
            "event": "destroy_building",
            "building_id": buildingID
        ]
        send(json: payload)
    }
    
    public func sendPlaceBuilding(id: String, type: String, lat: Double, lon: Double, level: Int, staffLevel: Int, equipLevel: Int, hp: Int = 100) {
        let payload: [String: Any] = [
            "event": "place_building",
            "building_id": id,
            "building_type": type,
            "location": [
                "lat": lat,
                "lon": lon
            ],
            "level": level,
            "staff_level": staffLevel,
            "equip_level": equipLevel,
            "hp": hp
        ]
        send(json: payload)
    }
    
    public func sendSpawnRemains(id: String, lat: Double, lon: Double) {
        let payload: [String: Any] = [
            "event": "spawn_remains",
            "remains_id": id,
            "location": [
                "lat": lat,
                "lon": lon
            ]
        ]
        send(json: payload)
    }
    
    public func sendCollectRemains(id: String) {
        let payload: [String: Any] = [
            "event": "collect_remains",
            "remains_id": id
        ]
        send(json: payload)
    }
    
    public func sendChatMessage(_ text: String) {
        let payload: [String: Any] = [
            "event": "chat_message",
            "message": text
        ]
        send(json: payload)
    }
    
    private func send(json: [String: Any]) {
        guard isConnected, let data = try? JSONSerialization.data(withJSONObject: json, options: []),
              let jsonString = String(data: data, encoding: .utf8) else { return }
        
        let message = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("🚨 WebSocket send error: \(error)")
            }
        }
    }
    
    // MARK: - Incoming Reader Loop
    
    private func receiveMessages() {
        guard isConnected else { return }
        
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure(let error):
                print("🚨 WebSocket connection failure: \(error)")
                self.handleDisconnect()
                
            case .success(let message):
                switch message {
                case .string(let text):
                    self.parseJSONMessage(text)
                default:
                    break
                }
                // Recursively listen for the next message
                self.receiveMessages()
            }
        }
    }
    
    private func parseJSONMessage(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
              let event = json["event"] as? String else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            switch event {
            case "welcome":
                let message = json["message"] as? String ?? ""
                var welcomeState: PlayerState? = nil
                if let pRaw = json["player"] as? [String: Any] {
                    welcomeState = self.parsePlayerState(pRaw)
                }
                self.delegate?.webSocketDidConnect(welcomeMessage: message, state: welcomeState)
                
            case "active_players_list":
                if let activePlayersRaw = json["active_players"] as? [[String: Any]] {
                    let players = activePlayersRaw.compactMap { self.parsePlayerState($0) }
                    self.delegate?.webSocketDidReceiveOpponentsList(players)
                }
                
            case "opponent_move":
                if let playerRaw = json["player"] as? [String: Any],
                   let state = self.parsePlayerState(playerRaw) {
                    self.delegate?.webSocketDidReceiveOpponentMove(state)
                }
                
            case "player_joined":
                let id = json["player_id"] as? String ?? ""
                let nickname = json["nickname"] as? String ?? ""
                let message = json["message"] as? String ?? ""
                self.delegate?.webSocketPlayerJoined(id: id, nickname: nickname, message: message)
                
            case "player_left":
                let id = json["player_id"] as? String ?? ""
                let nickname = json["nickname"] as? String ?? ""
                self.delegate?.webSocketPlayerLeft(id: id, nickname: nickname)
                
            case "spawn_remains":
                let rID = json["remains_id"] as? String ?? ""
                if let loc = json["location"] as? [String: Any],
                   let lat = loc["lat"] as? Double,
                   let lon = loc["lon"] as? Double {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RemoteRemainsSpawned"),
                        object: nil,
                        userInfo: ["id": rID, "lat": lat, "lon": lon]
                    )
                }
                
            case "collect_remains":
                let rID = json["remains_id"] as? String ?? ""
                NotificationCenter.default.post(
                    name: NSNotification.Name("RemoteRemainsCollected"),
                    object: nil,
                    userInfo: ["id": rID]
                )
                
            case "place_building":
                let bID = json["building_id"] as? String ?? ""
                let bType = json["building_type"] as? String ?? ""
                let owner = json["player_id"] as? String ?? ""
                let lvl = json["level"] as? Int ?? 1
                let staff = json["staff_level"] as? Int ?? 0
                let equip = json["equip_level"] as? Int ?? 0
                let curHP = json["hp"] as? Int ?? 100
                
                if let loc = json["location"] as? [String: Any],
                   let lat = loc["lat"] as? Double,
                   let lon = loc["lon"] as? Double {
                    // Send to delegate
                    NotificationCenter.default.post(
                        name: NSNotification.Name("RemoteBuildingPlaced"),
                        object: nil,
                        userInfo: [
                            "id": bID,
                            "type": bType,
                            "lat": lat,
                            "lon": lon,
                            "owner": owner,
                            "level": lvl,
                            "staff": staff,
                            "equip": equip,
                            "hp": curHP
                        ]
                    )
                }
                
            case "building_destroyed":
                let bID = json["building_id"] as? String ?? ""
                NotificationCenter.default.post(
                    name: NSNotification.Name("RemoteBuildingDestroyed"),
                    object: nil,
                    userInfo: ["id": bID]
                )
                
            case "chat_message":
                let nickname = json["nickname"] as? String ?? ""
                let message = json["message"] as? String ?? ""
                self.delegate?.webSocketDidReceiveChat(nickname: nickname, message: message)
                
            default:
                break
            }
        }
    }
    
    private func parsePlayerState(_ dict: [String: Any]) -> PlayerState? {
        guard let id = dict["id"] as? String,
              let nickname = dict["nickname"] as? String,
              let locationRaw = dict["location"] as? [String: Any],
              let lat = locationRaw["lat"] as? Double,
              let lon = locationRaw["lon"] as? Double,
              let hp = dict["hp"] as? Int,
              let maxHP = dict["max_hp"] as? Int,
              let level = dict["level"] as? Int else { return nil }
              
        let coins = dict["coins"] as? Int ?? 10000
        let gems = dict["gems"] as? Int ?? 10
        
        return PlayerState(
            id: id,
            nickname: nickname,
            location: Point(lat: lat, lon: lon),
            hp: hp,
            max_hp: maxHP,
            level: level,
            coins: coins,
            gems: gems
        )
    }
    
    private func handleDisconnect() {
        isConnected = false
        print("🔌 WebSocket disconnected. Trying to reconnect in 4 seconds...")
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.reconnectTimer?.invalidate()
            self.reconnectTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { [weak self] _ in
                guard let self = self else { return }
                self.connect(nickname: self.currentNickname)
            }
        }
    }
}
 
// MARK: - Swift Mirror Models

public struct Point: Codable {
    public let lat: Double
    public let lon: Double
}

public struct PlayerState: Codable {
    public let id: String
    public let nickname: String
    public let location: Point
    public let hp: Int
    public let max_hp: Int
    public let level: Int
    public let coins: Int
    public let gems: Int
}
