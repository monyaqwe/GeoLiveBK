import Foundation

/// Service for generating the custom futuristic, cyber-operative tactical map styles (Cheapshot-inspired)
public final class GoogleMapStyleService {
    
    public static let shared = GoogleMapStyleService()
    
    private init() {}
    
    /// Generates the raw JSON styling configuration for Google Maps SDK.
    /// Features: Deep black background, vibrant neon cyan road network, minimal typography, and zero commercial clutter.
    public func getFuturisticTacticalMapStyleJSON() -> String {
        let style = """
        [
          {
            "elementType": "geometry",
            "stylers": [
              { "color": "#0d0f12" }
            ]
          },
          {
            "elementType": "labels.text.fill",
            "stylers": [
              { "color": "#748ba0" }
            ]
          },
          {
            "elementType": "labels.text.stroke",
            "stylers": [
              { "color": "#0d0f12" },
              { "weight": 2 }
            ]
          },
          {
            "featureType": "administrative",
            "elementType": "geometry",
            "stylers": [
              { "color": "#1a222d" }
            ]
          },
          {
            "featureType": "administrative.country",
            "elementType": "labels.text.fill",
            "stylers": [
              { "color": "#00f0ff" }
            ]
          },
          {
            "featureType": "administrative.land_parcel",
            "stylers": [
              { "visibility": "off" }
            ]
          },
          {
            "featureType": "administrative.neighborhood",
            "stylers": [
              { "visibility": "off" }
            ]
          },
          {
            "featureType": "landscape",
            "elementType": "geometry",
            "stylers": [
              { "color": "#0d0f12" }
            ]
          },
          {
            "featureType": "landscape.natural",
            "elementType": "geometry",
            "stylers": [
              { "color": "#11161d" }
            ]
          },
          {
            "featureType": "poi",
            "stylers": [
              { "visibility": "off" }
            ]
          },
          {
            "featureType": "road",
            "elementType": "geometry",
            "stylers": [
              { "color": "#18202b" }
            ]
          },
          {
            "featureType": "road.arterial",
            "elementType": "geometry",
            "stylers": [
              { "color": "#00a8b5" },
              { "weight": 1.2 }
            ]
          },
          {
            "featureType": "road.highway",
            "elementType": "geometry",
            "stylers": [
              { "color": "#00f0ff" },
              { "weight": 1.8 }
            ]
          },
          {
            "featureType": "road.highway.controlled_access",
            "elementType": "geometry",
            "stylers": [
              { "color": "#00f0ff" },
              { "weight": 2.2 }
            ]
          },
          {
            "featureType": "road.local",
            "elementType": "geometry",
            "stylers": [
              { "color": "#111822" },
              { "weight": 0.8 }
            ]
          },
          {
            "featureType": "road.local",
            "elementType": "labels.text.fill",
            "stylers": [
              { "color": "#4e6a82" }
            ]
          },
          {
            "featureType": "transit",
            "stylers": [
              { "visibility": "off" }
            ]
          },
          {
            "featureType": "water",
            "elementType": "geometry",
            "stylers": [
              { "color": "#05080b" }
            ]
          },
          {
            "featureType": "water",
            "elementType": "labels.text.fill",
            "stylers": [
              { "color": "#00c5c8" }
            ]
          }
        ]
        """
        return style
    }
}
