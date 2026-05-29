import Foundation
import MapKit
import CoreLocation

extension MainMapViewController: GameWebSocketServiceDelegate {
    
    public func webSocketDidConnect(welcomeMessage: String, state: PlayerState?) {
        showNotificationHUD(message: "📡 CONFIGURED ONLINE: \(welcomeMessage)")
        
        if let s = state {
            // Apply loaded database metrics to local iOS client variables
            self.playerLevel = s.level
            self.playerCurrentHP = s.hp
            self.playerMaxHP = s.max_hp
            self.coins = s.coins
            self.gems = s.gems
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.updateStatsBarLabels()
                
                // Redraw player avatar's stats if visible
                if let avatarAnn = self.avatarAnnotation,
                   let view = self.mapView.view(for: avatarAnn) as? AvatarAnnotationView {
                    view.updateHP(current: self.playerCurrentHP, max: self.playerMaxHP)
                }
            }
        }
    }
    
    public func webSocketDidReceiveOpponentsList(_ opponents: [PlayerState]) {
        // Remove opponents that are no longer in the list
        let activeIDs = Set(opponents.map { $0.id })
        for (id, annotation) in activeOpponentAnnotations {
            if !activeIDs.contains(id) {
                mapView.removeAnnotation(annotation)
                activeOpponentAnnotations.removeValue(forKey: id)
                if targetedOpponentAnnotation?.id == id {
                    hideCombatBar()
                    targetedOpponentAnnotation = nil
                }
            }
        }
        
        // Add or update opponents
        for opp in opponents {
            let coord = CLLocationCoordinate2D(latitude: opp.location.lat, longitude: opp.location.lon)
            if let existing = activeOpponentAnnotations[opp.id] {
                UIView.animate(withDuration: 0.3) {
                    existing.coordinate = coord
                }
                existing.hp = opp.hp
                existing.maxHP = opp.max_hp
                existing.level = opp.level
                
                // Update its view if visible
                if let view = mapView.view(for: existing) as? OpponentAnnotationView {
                    view.configure(with: existing)
                }
                
                // Update active target details if it's our targeted opponent
                if targetedOpponentAnnotation?.id == opp.id {
                    targetHPLabel.text = "HP: \(opp.hp)/\(opp.max_hp)"
                }
            } else {
                let annotation = OpponentAnnotation(
                    id: opp.id,
                    nickname: opp.nickname,
                    coordinate: coord,
                    hp: opp.hp,
                    maxHP: opp.max_hp,
                    level: opp.level
                )
                activeOpponentAnnotations[opp.id] = annotation
                mapView.addAnnotation(annotation)
            }
        }
    }
    
    public func webSocketDidReceiveOpponentMove(_ opponent: PlayerState) {
        let coord = CLLocationCoordinate2D(latitude: opponent.location.lat, longitude: opponent.location.lon)
        if let existing = activeOpponentAnnotations[opponent.id] {
            // Smoothly animate opponent coordinate update on MapKit
            UIView.animate(withDuration: 0.3) {
                existing.coordinate = coord
            }
            existing.hp = opponent.hp
            existing.maxHP = opponent.max_hp
            existing.level = opponent.level
            
            if let view = mapView.view(for: existing) as? OpponentAnnotationView {
                view.configure(with: existing)
            }
            
            if targetedOpponentAnnotation?.id == opponent.id {
                targetHPLabel.text = "HP: \(opponent.hp)/\(opponent.max_hp)"
            }
        } else {
            let annotation = OpponentAnnotation(
                id: opponent.id,
                nickname: opponent.nickname,
                coordinate: coord,
                hp: opponent.hp,
                maxHP: opponent.max_hp,
                level: opponent.level
            )
            activeOpponentAnnotations[opponent.id] = annotation
            mapView.addAnnotation(annotation)
        }
    }
    
    public func webSocketPlayerJoined(id: String, nickname: String, message: String) {
        showNotificationHUD(message: "⚔️ PLAYER JOINED: \(nickname)")
    }
    
    public func webSocketPlayerLeft(id: String, nickname: String) {
        showNotificationHUD(message: "🏳️ PLAYER LEFT: \(nickname)")
        if let annotation = activeOpponentAnnotations[id] {
            mapView.removeAnnotation(annotation)
            activeOpponentAnnotations.removeValue(forKey: id)
        }
        if targetedOpponentAnnotation?.id == id {
            hideCombatBar()
            targetedOpponentAnnotation = nil
        }
    }
    
    public func webSocketDidReceiveChat(nickname: String, message: String) {
        showNotificationHUD(message: "💬 [\(nickname)]: \(message)")
    }
}
