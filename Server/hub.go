package main

import (
	"encoding/json"
	"log"
	"sync"
)

type Hub struct {
	clients    map[*Client]bool
	broadcast  chan []byte
	register   chan *Client
	unregister chan *Client
	mutex      sync.RWMutex
}

func newHub() *Hub {
	return &Hub{
		broadcast:  make(chan []byte),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		clients:    make(map[*Client]bool),
	}
}

func (h *Hub) run() {
	for {
		select {
		case client := <-h.register:
			h.mutex.Lock()
			h.clients[client] = true
			h.mutex.Unlock()
			log.Printf("📱 Client connected: %s (%s)", client.nickname, client.id)
			
			// Notify other players about new player joining
			joinMsg, _ := json.Marshal(Message{
				Event:    "player_joined",
				PlayerID: client.id,
				Nickname: client.nickname,
				Message:  "Player " + client.nickname + " has joined the server!",
			})
			h.broadcastToOthers(client, joinMsg)

		case client := <-h.unregister:
			h.mutex.Lock()
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				close(client.send)
				log.Printf("🔌 Client disconnected: %s (%s)", client.nickname, client.id)
				
				// Notify other players about disconnect
				leaveMsg, _ := json.Marshal(Message{
					Event:    "player_left",
					PlayerID: client.id,
					Nickname: client.nickname,
				})
				h.broadcastToOthers(client, leaveMsg)
			}
			h.mutex.Unlock()

		case message := <-h.broadcast:
			h.mutex.RLock()
			for client := range h.clients {
				select {
				case client.send <- message:
				default:
					close(client.send)
					delete(h.clients, client)
				}
			}
			h.mutex.RUnlock()
		}
	}
}

func (h *Hub) broadcastToOthers(sender *Client, message []byte) {
	h.mutex.RLock()
	defer h.mutex.RUnlock()
	for client := range h.clients {
		if client != sender {
			select {
			case client.send <- message:
			default:
				close(client.send)
				delete(h.clients, client)
			}
		}
	}
}
