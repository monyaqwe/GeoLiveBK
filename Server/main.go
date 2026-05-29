package main

import (
	"log"
	"net/http"
)

func main() {
	log.Println("🚀 Initializing GeoLive Arena WebSocket Server...")
	
	hub := newHub()
	go hub.run()
	
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Write([]byte("🟢 GeoLive Arena Server is healthy and running! Connect to /ws for WebSockets."))
	})
	
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		serveWs(hub, w, r)
	})
	
	port := "8080"
	log.Printf("📡 Live on port %s. Awaiting operatives...", port)
	
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		log.Fatalf("Server ListenAndServe error: %v", err)
	}
}
