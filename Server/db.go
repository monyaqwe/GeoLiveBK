package main

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

type Database struct {
	db *sql.DB
}

func initDatabase() *Database {
	db, err := sql.Open("sqlite3", "./geolive.db")
	if err != nil {
		log.Fatalf("🚨 SQLite opening error: %v", err)
	}

	// Create tables if they do not exist
	playerTableQuery := `
	CREATE TABLE IF NOT EXISTS players (
		id TEXT PRIMARY KEY,
		nickname TEXT NOT NULL,
		lat REAL DEFAULT 0.0,
		lon REAL DEFAULT 0.0,
		hp INTEGER DEFAULT 100,
		max_hp INTEGER DEFAULT 100,
		level INTEGER DEFAULT 1,
		coins INTEGER DEFAULT 10000,
		gems INTEGER DEFAULT 10
	);`

	buildingTableQuery := `
	CREATE TABLE IF NOT EXISTS buildings (
		id TEXT PRIMARY KEY,
		type TEXT NOT NULL,
		lat REAL NOT NULL,
		lon REAL NOT NULL,
		level INTEGER DEFAULT 1,
		staff_level INTEGER DEFAULT 0,
		equip_level INTEGER DEFAULT 0
	);`

	if _, err := db.Exec(playerTableQuery); err != nil {
		log.Fatalf("🚨 Error creating players table: %v", err)
	}

	// Dynamic column checks to ensure backward compatibility
	_, _ = db.Exec("ALTER TABLE players ADD COLUMN coins INTEGER DEFAULT 10000;")
	_, _ = db.Exec("ALTER TABLE players ADD COLUMN gems INTEGER DEFAULT 10;")
	_, _ = db.Exec("ALTER TABLE buildings ADD COLUMN level INTEGER DEFAULT 1;")
	_, _ = db.Exec("ALTER TABLE buildings ADD COLUMN staff_level INTEGER DEFAULT 0;")
	_, _ = db.Exec("ALTER TABLE buildings ADD COLUMN equip_level INTEGER DEFAULT 0;")

	if _, err := db.Exec(buildingTableQuery); err != nil {
		log.Fatalf("🚨 Error creating buildings table: %v", err)
	}

	log.Println("💾 Database initialized successfully (SQLite).")
	return &Database{db: db}
}

// GetOrCreatePlayer fetches or initializes a player record based on their unique ID (or nickname if new)
func (d *Database) GetOrCreatePlayer(id, nickname string) *PlayerState {
	row := d.db.QueryRow("SELECT id, nickname, lat, lon, hp, max_hp, level, coins, gems FROM players WHERE id = ? OR nickname = ?", id, nickname)
	
	var p PlayerState
	err := row.Scan(&p.ID, &p.Nickname, &p.Location.Latitude, &p.Location.Longitude, &p.HP, &p.MaxHP, &p.Level, &p.Coins, &p.Gems)
	if err == sql.ErrNoRows {
		// Insert a new record
		p = PlayerState{
			ID:       id,
			Nickname: nickname,
			Location: Point{Latitude: 0, Longitude: 0},
			HP:       100,
			MaxHP:    100,
			Level:    1,
			Coins:    10000,
			Gems:     10,
		}
		_, insertErr := d.db.Exec(
			"INSERT INTO players (id, nickname, lat, lon, hp, max_hp, level, coins, gems) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
			p.ID, p.Nickname, p.Location.Latitude, p.Location.Longitude, p.HP, p.MaxHP, p.Level, p.Coins, p.Gems,
		)
		if insertErr != nil {
			log.Printf("🚨 Error inserting new player: %v", insertErr)
		}
		return &p
	} else if err != nil {
		log.Printf("🚨 Error querying player: %v", err)
	}
	
	return &p
}

// SavePlayer persists current player status
func (d *Database) SavePlayer(p *PlayerState) {
	_, err := d.db.Exec(
		"UPDATE players SET nickname = ?, lat = ?, lon = ?, hp = ?, max_hp = ?, level = ?, coins = ?, gems = ? WHERE id = ?",
		p.Nickname, p.Location.Latitude, p.Location.Longitude, p.HP, p.MaxHP, p.Level, p.Coins, p.Gems, p.ID,
	)
	if err != nil {
		log.Printf("🚨 Error updating player: %v", err)
	}
}

// SaveBuilding persists building placement and upgrade levels
func (d *Database) SaveBuilding(id, bType string, lat, lon float64, level, staff, equip int) {
	_, err := d.db.Exec(
		"INSERT OR REPLACE INTO buildings (id, type, lat, lon, level, staff_level, equip_level) VALUES (?, ?, ?, ?, ?, ?, ?)",
		id, bType, lat, lon, level, staff, equip,
	)
	if err != nil {
		log.Printf("🚨 Error saving building: %v", err)
	}
}

// DeleteBuilding deletes demolished building from database
func (d *Database) DeleteBuilding(id string) {
	_, err := d.db.Exec("DELETE FROM buildings WHERE id = ?", id)
	if err != nil {
		log.Printf("🚨 Error deleting building: %v", err)
	}
}

// LoadAllBuildings fetches all buildings to populate active instances on startup
func (d *Database) LoadAllBuildings() []*Message {
	rows, err := d.db.Query("SELECT id, type, lat, lon, level, staff_level, equip_level FROM buildings")
	if err != nil {
		log.Printf("🚨 Error loading buildings: %v", err)
		return nil
	}
	defer rows.Close()

	var list []*Message
	for rows.Next() {
		var id, bType string
		var lat, lon float64
		var level, staff, equip int
		if err := rows.Scan(&id, &bType, &lat, &lon, &level, &staff, &equip); err == nil {
			list = append(list, &Message{
				Event:        "place_building",
				BuildingID:   id,
				BuildingType: bType,
				Location:     &Point{Latitude: lat, Longitude: lon},
				Level:        level,
				StaffLevel:   staff,
				EquipLevel:   equip,
			})
		}
	}
	return list
}
