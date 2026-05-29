package main

import (
	"log"
	"net/http"
)

func main() {
	log.Println("🚀 Initializing GeoLive Arena WebSocket Server...")
	
	db := initDatabase()
	world := newWorldManager()
	hub := newHub(world, db)
	go hub.run()
	
	// Load all pre-existing buildings from database
	savedBuildings := db.LoadAllBuildings()
	for _, b := range savedBuildings {
		// Log loaded buildings
		log.Printf("🏢 Restoring building %s type %s at [%.5f, %.5f]", b.BuildingID, b.BuildingType, b.Location.Latitude, b.Location.Longitude)
	}
	
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("🟢 GeoLive Arena Server is healthy and running! Connect to /ws for WebSockets."))
	})
	
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		serveWs(hub, w, r)
	})
	
	port := "8082" // Shifted to 8082 to bypass local address-already-in-use conflicts!
	log.Printf("📡 Live on port %s. Awaiting operatives...", port)
	
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Server ListenAndServe error: %v", err)
	}
}
