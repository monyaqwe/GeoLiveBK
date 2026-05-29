package main

type Point struct {
	Latitude  float64 `json:"lat"`
	Longitude float64 `json:"lon"`
}

type Message struct {
	Event          string         `json:"event"`
	PlayerID       string         `json:"player_id,omitempty"`
	TargetPlayerID string         `json:"target_player_id,omitempty"`
	BuildingID     string         `json:"building_id,omitempty"`
	BuildingType   string         `json:"building_type,omitempty"`
	Damage         int            `json:"damage,omitempty"`
	Location       *Point         `json:"location,omitempty"`
	Message        string         `json:"message,omitempty"`
	Nickname       string         `json:"nickname,omitempty"`
	Player         *PlayerState   `json:"player,omitempty"`
	ActivePlayers  []*PlayerState `json:"active_players,omitempty"`
	Level          int            `json:"level,omitempty"`
	StaffLevel     int            `json:"staff_level,omitempty"`
	EquipLevel     int            `json:"equip_level,omitempty"`
	RemainsID      string         `json:"remains_id,omitempty"`
	HP             int            `json:"hp,omitempty"`
}
