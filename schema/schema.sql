/* 
  Regions table.
*/
CREATE TABLE Regions (
    region_id SERIAL PRIMARY KEY,
    region_name TEXT NOT NULL
);
/* 
  Constellations table.
*/
CREATE TABLE Constellations (
    constellation_id SERIAL PRIMARY KEY,
    constellation_name TEXT NOT NULL,
    region_id INTEGER NOT NULL,
    FOREIGN KEY (region_id) REFERENCES Regions(region_id)
);
/* 
  Systems table.
*/
CREATE TABLE Systems (
    system_id SERIAL PRIMARY KEY,
    system_name TEXT NOT NULL,
    security_status DOUBLE PRECISION,
    security_class TEXT,
    x_pos DOUBLE PRECISION,
    y_pos DOUBLE PRECISION,
    z_pos DOUBLE PRECISION,
    constellation_id INTEGER NOT NULL,
    spectral_class TEXT, -- Star spectral class directly in Systems table (system coloring)
    FOREIGN KEY (constellation_id) REFERENCES Constellations(constellation_id)
);
/* 
  Connections table.
*/
CREATE TABLE Stargates (
    stargate_id SERIAL PRIMARY KEY,
    stargate_name TEXT NOT NULL,
    system_id INTEGER NOT NULL, -- The system this gate is IN
    destination_stargate_id INTEGER NOT NULL, -- The ID of the gate on the other side
    destination_system_id INTEGER NOT NULL, -- The system this gate LEADS TO
    FOREIGN KEY (system_id) REFERENCES Systems(system_id),
    FOREIGN KEY (destination_system_id) REFERENCES Systems(system_id)
);
/* 
  Planets table.
*/
CREATE TABLE Planets (
    planet_id SERIAL PRIMARY KEY,
    planet_name TEXT NOT NULL,
    system_id INTEGER NOT NULL,
    "type" TEXT,
    moon_count INTEGER NOT NULL DEFAULT 0,
    asteroid_belt_count INTEGER NOT NULL DEFAULT 0,
    FOREIGN KEY (system_id) REFERENCES Systems(system_id)
)
/* 
  Stations table.
*/
CREATE TABLE Stations (
    station_id SERIAL PRIMARY KEY,
    station_name TEXT NOT NULL,
    system_id INTEGER NOT NULL,
    FOREIGN KEY (system_id) REFERENCES Systems(system_id)
);
/*
  Killmails, from zkillboard for real time data.
*/
CREATE TABLE killmails (
    killmail_id BIGINT PRIMARY KEY,
    corporation_id BIGINT,
    alliance_id BIGINT,
    solar_system_id BIGINT,
    killmail_time TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    destroyed_value NUMERIC,
    dropped_value NUMERIC
);
/*
  Factions stored
*/
CREATE TABLE factions (
    corporation_id BIGINT,
    faction_id BIGINT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    capital_system VARCHAR(255),
    militia_corporation_id BIGINT
);
/*
  Alliances, updated every hour for naming.
*/
CREATE TABLE alliances (
    alliance_id BIGINT PRIMARY KEY,
    name VARCHAR(255)
);
/*
  Sovereignty Campaigns table, every hour.
*/
CREATE TABLE sovereignty_campaigns (
    campaign_id BIGINT PRIMARY KEY,
    attackers_score FLOAT,
    constellation_id BIGINT,
    defender_id BIGINT,
    defender_score FLOAT,
    event_type TEXT,
    solar_system_id BIGINT,
    start_time TIMESTAMP,
    structure_id BIGINT
);
/*
  Sovereignty structures, for player owned capital and gates.
*/
CREATE TABLE sovereignty_structures (
    structure_id BIGINT PRIMARY KEY,
    alliance_id BIGINT,
    solar_system_id BIGINT,
    structure_type_id BIGINT,
    vulnerability_start_time TIMESTAMP,
    vulnerability_end_time TIMESTAMP
);
/*
  Sovereignty mapping
*/
CREATE TABLE sovereignty (
    system_id BIGINT PRIMARY KEY,
    faction_id BIGINT,
    alliance_id BIGINT
);
/*
  Indexes for performance.
*/
CREATE INDEX idx_killmail_time ON killmails (killmail_time);
CREATE INDEX idx_constellations_region_id ON Constellations(region_id);
CREATE INDEX idx_systems_constellation_id ON Systems(constellation_id);
CREATE INDEX idx_stargates_system_id ON Stargates(system_id);
CREATE INDEX idx_stargates_destination_system_id ON Stargates(destination_system_id);
CREATE INDEX idx_planets_system_id ON Planets(system_id);
CREATE INDEX idx_stations_system_id ON Stations(system_id);
-- Optional: Indexes on name columns if you search by them frequently
CREATE INDEX idx_regions_name ON Regions(region_name);
-- CREATE INDEX idx_constellations_name ON Constellations(constellation_name);
CREATE INDEX idx_systems_name ON Systems(system_name);
-- CREATE INDEX idx_planets_name ON Planets(planet_name);
-- CREATE INDEX idx_stations_name ON Stations(station_name);
