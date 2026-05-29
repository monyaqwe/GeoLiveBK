package main

type Point struct {
	Latitude  float64 `json:"lat"`
	Longitude float64 `json:"lon"`
}

type Message struct {
	Event          string   `json:"event"`
	PlayerID       string   `json:"player_id,omitempty"`
	TargetPlayerID string   `json:"target_player_id,omitempty"`
	BuildingID     string   `json:"building_id,omitempty"`
	Damage         int      `json:"damage,omitempty"`
	Location       *Point   `json:"location,omitempty"`
	Message        string   `json:"message,omitempty"`
	Nickname       string   `json:"nickname,omitempty"`
	Players        []string `json:"players,omitempty"`
}
