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
