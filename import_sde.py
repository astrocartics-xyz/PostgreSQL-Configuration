
import os
import re
import yaml
import psycopg2
from psycopg2 import extras

# --- Database Configuration ---
DB_HOST = "localhost"
DB_NAME = "eve_online_db"
DB_USER = "root"
DB_PASSWORD = "" # Replace with your password

# --- SDE Path ---
SDE_ROOT = "sde-20250707-TRANQUILITY"
UNIVERSE_BASE_PATH = os.path.join(SDE_ROOT, "universe")
BSD_PATH = os.path.join(SDE_ROOT, "bsd")

def expand_region_name(name):
    """
    Adds spaces to region names like 'TheForge' -> 'The Forge'.
    Ignores names that are all caps and numbers (e.g., UUA-F4).
    """
    if re.match(r'^[A-Z0-9-]+$', name):
        return name
    return re.sub(r'([a-z])([A-Z])', r'\1 \2', name)

def load_names(file_path):
    """
    Loads item names from invNames.yaml into a dictionary.
    """
    print("Loading names from invNames.yaml...")
    names = {}
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            # Use yaml.safe_load which is more robust for YAML files
            data = yaml.safe_load(f)
            if data:
                for item in data:
                    names[item['itemID']] = item['itemName']
    except yaml.YAMLError as e:
        print(f"Error parsing YAML file {file_path}: {e}")
    except Exception as e:
        print(f"An error occurred loading names: {e}")
        
    print(f"Loaded {len(names)} names.")
    return names

def connect_db():
    """Establishes a connection to the PostgreSQL database."""
    try:
        conn = psycopg2.connect(
            host=DB_HOST,
            database=DB_NAME,
            user=DB_USER,
            password=DB_PASSWORD
        )
        return conn
    except psycopg2.OperationalError as e:
        print(f"Error connecting to the database: {e}")
        print("Please ensure PostgreSQL is running and the connection details are correct.")
        return None

def main():
    """
    Main function to parse SDE and populate the database.
    """
    conn = connect_db()
    if not conn:
        return

    names = load_names(os.path.join(BSD_PATH, 'invNames.yaml'))
    
    cur = conn.cursor()
    cur.execute("SET search_path TO eve_sde")

    regions_data = []
    constellations_data = []
    systems_data = []
    planets_data = []
    stargates_data = []
    stations_data = []

    print("Parsing universe data...")
    for universe_subdir in os.listdir(UNIVERSE_BASE_PATH):
        universe_path = os.path.join(UNIVERSE_BASE_PATH, universe_subdir)
        if not os.path.isdir(universe_path) or universe_subdir.startswith('.'):
            continue
        
        print(f"--- Parsing '{universe_subdir}' directory ---")

        for region_name in os.listdir(universe_path):
            region_path = os.path.join(universe_path, region_name)
            if not os.path.isdir(region_path):
                continue

            region_yaml_path = os.path.join(region_path, 'region.yaml')
            if not os.path.exists(region_yaml_path):
                continue

            with open(region_yaml_path, 'r') as f:
                region_sde = yaml.safe_load(f)
            
            region_id = region_sde['regionID']
            # The folder name is the un-spaced name
            formatted_region_name = expand_region_name(region_name)
            regions_data.append((region_id, formatted_region_name))

            for constellation_name in os.listdir(region_path):
                constellation_path = os.path.join(region_path, constellation_name)
                if not os.path.isdir(constellation_path):
                    continue
                
                constellation_yaml_path = os.path.join(constellation_path, 'constellation.yaml')
                if not os.path.exists(constellation_yaml_path):
                    continue
                    
                with open(constellation_yaml_path, 'r') as f:
                    constellation_sde = yaml.safe_load(f)
                
                constellation_id = constellation_sde['constellationID']
                constellations_data.append((constellation_id, names.get(constellation_id, constellation_name), region_id))

                for system_name in os.listdir(constellation_path):
                    system_path = os.path.join(constellation_path, system_name)
                    if not os.path.isdir(system_path):
                        continue

                    system_yaml_path = os.path.join(system_path, 'solarsystem.yaml')
                    if not os.path.exists(system_yaml_path):
                        continue
                    
                    with open(system_yaml_path, 'r') as f:
                        system_sde = yaml.safe_load(f)

                    if not system_sde: # Handle empty system files
                        continue

                    system_id = system_sde['solarSystemID']
                    star = system_sde.get('star', {})
                    pos = system_sde.get('center', [0,0,0])

                    systems_data.append((
                        system_id,
                        names.get(system_id, system_name),
                        system_sde['security'],
                        system_sde.get('securityClass'),
                        pos[0], pos[1], pos[2],
                        constellation_id,
                        star.get('statistics', {}).get('spectralClass')
                    ))

                    if 'stargates' in system_sde:
                        for sg_id, sg_data in system_sde['stargates'].items():
                            stargates_data.append((
                                sg_id,
                                names.get(sg_id, f"Stargate to {sg_data['destination']}"),
                                system_id,
                                sg_data['destination'],
                                # We need to find the destination system ID. This is tricky.
                                # For now, we will set it to the destination stargate id, which is often linked in EVE.
                                sg_data['destination'] 
                            ))


                    if 'planets' in system_sde:
                        for planet_id, planet_data in system_sde['planets'].items():
                            planet_name = names.get(planet_id, f"Planet {planet_id}")
                            moon_count = len(planet_data.get('moons', []))
                            asteroid_belt_count = len(planet_data.get('asteroidBelts', []))
                            planet_type_id = planet_data.get('typeID')
                            planet_type = names.get(planet_type_id) if planet_type_id else "Unknown"

                            planets_data.append((
                                planet_id,
                                planet_name,
                                system_id,
                                planet_type,
                                moon_count,
                                asteroid_belt_count
                            ))

    print("Parsing station data...")
    staStations_path = os.path.join(BSD_PATH, 'staStations.yaml')
    with open(staStations_path, 'r') as f:
        stations_sde = yaml.safe_load(f)
    
    for station in stations_sde:
        stations_data.append((
            station['stationID'],
            station['stationName'],
            station['solarSystemID'],
            # # planet_id is not directly in staStations.yaml
        ))

    print("Inserting data into database...")
    try:
        extras.execute_values(cur, "INSERT INTO Regions (region_id, region_name) VALUES %s ON CONFLICT(region_id) DO NOTHING", regions_data)
        extras.execute_values(cur, "INSERT INTO Constellations (constellation_id, constellation_name, region_id) VALUES %s ON CONFLICT(constellation_id) DO NOTHING", constellations_data)
        extras.execute_values(cur, """
            INSERT INTO Systems (system_id, system_name, security_status, security_class, x_pos, y_pos, z_pos, constellation_id, spectral_class) 
            VALUES %s 
            ON CONFLICT (system_id) 
            DO UPDATE SET 
                system_name = EXCLUDED.system_name, 
                security_status = EXCLUDED.security_status, 
                security_class = EXCLUDED.security_class, 
                x_pos = EXCLUDED.x_pos, 
                y_pos = EXCLUDED.y_pos, 
                z_pos = EXCLUDED.z_pos, 
                constellation_id = EXCLUDED.constellation_id, 
                spectral_class = EXCLUDED.spectral_class
        """, systems_data)
        extras.execute_values(cur, "INSERT INTO Planets (planet_id, planet_name, system_id, \"type\", moon_count, asteroid_belt_count) VALUES %s ON CONFLICT(planet_id) DO NOTHING", planets_data)
        
        # Stargates need special handling for destination_system_id
        # A bit of a hack: let's create a map of stargate_id -> system_id
        stargate_to_system_map = {}
        for sg in stargates_data:
            stargate_to_system_map[sg[0]] = sg[2]

        final_stargates_data = []
        for sg_id, sg_name, sys_id, dest_sg_id, _ in stargates_data:
            dest_sys_id = stargate_to_system_map.get(dest_sg_id)
            if dest_sys_id:
                final_stargates_data.append((sg_id, sg_name, sys_id, dest_sg_id, dest_sys_id))

        extras.execute_values(cur, "INSERT INTO Stargates (stargate_id, stargate_name, system_id, destination_stargate_id, destination_system_id) VALUES %s ON CONFLICT(stargate_id) DO NOTHING", final_stargates_data)
        
        # --- Filter stations to only include those in systems we have processed ---
        print("Filtering station data...")
        valid_system_ids = {s[0] for s in systems_data}
        filtered_stations_data = [
            station for station in stations_data if station[2] in valid_system_ids
        ]
        
        extras.execute_values(cur, "INSERT INTO Stations (station_id, station_name, system_id) VALUES %s ON CONFLICT(station_id) DO NOTHING", filtered_stations_data)

        conn.commit()
        print("Data insertion complete.")

    except Exception as e:
        conn.rollback()
        print(f"An error occurred during database insertion: {e}")
    finally:
        cur.close()
        conn.close()


if __name__ == '__main__':
    # Before running, make sure to install dependencies:
    # pip install psycopg2-binary PyYAML
    main() 