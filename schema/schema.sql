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
);

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
  Indexes for performance.
*/
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
