package main

import (
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
	"github.com/gorilla/websocket"
)

const (
	writeWait      = 10 * time.Second
	pongWait       = 60 * time.Second
	pingPeriod     = (pongWait * 9) / 10
	maxMessageSize = 512
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		return true // Allow all origins for the game
	},
}

type Client struct {
	hub      *Hub
	conn     *websocket.Conn
	send     chan []byte
	id       string
	nickname string
	lat      float64
	lon      float64
}

func (c *Client) readPump() {
	defer func() {
		c.hub.unregister <- c
		c.conn.Close()
	}()
	
	c.conn.SetReadLimit(maxMessageSize)
	c.conn.SetReadDeadline(time.Now().Add(pongWait))
	c.conn.SetPongHandler(func(string) error { c.conn.SetReadDeadline(time.Now().Add(pongWait)); return nil })
	
	for {
		_, message, err := c.conn.ReadMessage()
		if err != nil {
			if websocket.IsUnexpectedCloseError(err, websocket.CloseGoingAway, websocket.CloseAbnormalClosure) {
				log.Printf("error: %v", err)
			}
			break
		}
		
		var msg Message
		if err := json.Unmarshal(message, &msg); err != nil {
			log.Printf("JSON unmarshal error: %v", err)
			continue
		}
		
		// Handle incoming message types
		switch msg.Event {
		case "player_move":
			if msg.Location != nil {
				c.lat = msg.Location.Latitude
				c.lon = msg.Location.Longitude
				
				// Broadcast movement to all other players
				moveMsg, _ := json.Marshal(Message{
					Event:    "opponent_move",
					PlayerID: c.id,
					Nickname: c.nickname,
					Location: msg.Location,
				})
				c.hub.broadcastToOthers(c, moveMsg)
			}
			
		case "chat_message":
			chatMsg, _ := json.Marshal(Message{
				Event:    "chat_message",
				PlayerID: c.id,
				Nickname: c.nickname,
				Message:  msg.Message,
			})
			c.hub.broadcast(chatMsg)
			
		case "attack_player":
			attackMsg, _ := json.Marshal(Message{
				Event:          "opponent_attacked",
				PlayerID:       c.id,
				TargetPlayerID: msg.TargetPlayerID,
				Damage:         msg.Damage,
			})
			c.hub.broadcast(attackMsg)
			
		case "destroy_building":
			destroyMsg, _ := json.Marshal(Message{
				Event:      "building_destroyed",
				PlayerID:   c.id,
				BuildingID: msg.BuildingID,
			})
			c.hub.broadcast(destroyMsg)
		}
	}
}

func (c *Client) writePump() {
	ticker := time.NewTicker(pingPeriod)
	defer func() {
		ticker.Stop()
		c.conn.Close()
	}()
	
	for {
		select {
		case message, ok := <-c.send:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if !ok {
				c.conn.WriteMessage(websocket.CloseMessage, []byte{})
				return
			}
			
			w, err := c.conn.NextWriter(websocket.TextMessage)
			if err != nil {
				return
			}
			w.Write(message)
			
			n := len(c.send)
			for i := 0; i < n; i++ {
				w.Write([]byte{'\n'})
				w.Write(<-c.send)
			}
			
			if err := w.Close(); err != nil {
				return
			}
			
		case <-ticker.C:
			c.conn.SetWriteDeadline(time.Now().Add(writeWait))
			if err := c.conn.WriteMessage(websocket.PingMessage, nil); err != nil {
				return
			}
		}
	}
}

func serveWs(hub *Hub, w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println(err)
		return
	}
	
	nickname := r.URL.Query().Get("nickname")
	if nickname == "" {
		nickname = "Operative"
	}
	
	client := &Client{
		hub:      hub,
		conn:     conn,
		send:     make(chan []byte, 256),
		id:       uuid.New().String(),
		nickname: nickname,
	}
	
	client.hub.register <- client
	
	// Send welcome packet back to connecting player
	welcomeMsg, _ := json.Marshal(Message{
		Event:    "welcome",
		PlayerID: client.id,
		Nickname: client.nickname,
		Message:  "🟢 Handshake complete! Welcome to GeoLive Arena.",
	})
	client.send <- welcomeMsg
	
	go client.writePump()
	go client.readPump()
}
