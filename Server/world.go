package main

import (
	"math"
	"sync"
)

// GridSize represents the size of our spatial hashing cell in degrees.
// 0.01 degrees is roughly 1.1 kilometers at the equator.
const GridSize = 0.01

type GridKey struct {
	X int
	Y int
}

// PlayerState represents the active in-memory state of a connected player.
type PlayerState struct {
	ID       string   `json:"id"`
	Nickname string   `json:"nickname"`
	Location Point    `json:"location"`
	HP       int      `json:"hp"`
	MaxHP    int      `json:"max_hp"`
	Level    int      `json:"level"`
}

// WorldManager manages spatial indexing and thread-safe operations on player states.
type WorldManager struct {
	sync.RWMutex
	players map[string]*PlayerState
	grid    map[GridKey]map[string]bool
}

func newWorldManager() *WorldManager {
	return &WorldManager{
		players: make(map[string]*PlayerState),
		grid:    make(map[GridKey]map[string]bool),
	}
}

// getGridKey computes the 2D spatial hash cell for a given coordinate.
func getGridKey(lat, lon float64) GridKey {
	return GridKey{
		X: int(math.Floor(lon / GridSize)),
		Y: int(math.Floor(lat / GridSize)),
	}
}

// UpdatePlayer updates or creates a player's spatial state and moves them across grid cells if needed.
func (w *WorldManager) UpdatePlayer(id, nickname string, lat, lon float64, hp, maxHP, level int) *PlayerState {
	w.Lock()
	defer w.Unlock()

	state, exists := w.players[id]
	newKey := getGridKey(lat, lon)

	if !exists {
		// New player initialization
		state = &PlayerState{
			ID:       id,
			Nickname: nickname,
			Location: Point{Latitude: lat, Longitude: lon},
			HP:       hp,
			MaxHP:    maxHP,
			Level:    level,
		}
		w.players[id] = state
		w.addPlayerToGrid(id, newKey)
		return state
	}

	// Update existing player state
	oldKey := getGridKey(state.Location.Latitude, state.Location.Longitude)
	state.Location.Latitude = lat
	state.Location.Longitude = lon
	state.HP = hp
	state.MaxHP = maxHP
	state.Level = level

	// Manage cell transition if crossed boundaries
	if oldKey != newKey {
		w.removePlayerFromGrid(id, oldKey)
		w.addPlayerToGrid(id, newKey)
	}

	return state
}

// RemovePlayer cleans up player state from both memory registry and spatial grid.
func (w *WorldManager) RemovePlayer(id string) {
	w.Lock()
	defer w.Unlock()

	state, exists := w.players[id]
	if !exists {
		return
	}

	key := getGridKey(state.Location.Latitude, state.Location.Longitude)
	w.removePlayerFromGrid(id, key)
	delete(w.players, id)
}

// GetPlayersInRadius returns all players inside the 9-cell spatial neighborhood of a coordinates anchor.
func (w *WorldManager) GetPlayersInRadius(lat, lon float64) []*PlayerState {
	w.RLock()
	defer w.RUnlock()

	centerKey := getGridKey(lat, lon)
	var nearby []*PlayerState

	// Scan 3x3 grid cells around player for O(1) performance
	for dx := -1; dx <= 1; dx++ {
		for dy := -1; dy <= 1; dy++ {
			key := GridKey{X: centerKey.X + dx, Y: centerKey.Y + dy}
			if playerIds, ok := w.grid[key]; ok {
				for id := range playerIds {
					if p, found := w.players[id]; found {
						nearby = append(nearby, p)
					}
				}
			}
		}
	}

	return nearby
}

func (w *WorldManager) addPlayerToGrid(id string, key GridKey) {
	if w.grid[key] == nil {
		w.grid[key] = make(map[string]bool)
	}
	w.grid[key][id] = true
}

func (w *WorldManager) removePlayerFromGrid(id string, key GridKey) {
	if w.grid[key] != nil {
		delete(w.grid[key], id)
		if len(w.grid[key]) == 0 {
			delete(w.grid, key)
		}
	}
}
