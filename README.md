# PostgreSQL-Data-Tables
This is the implementation of the database tables and their respective schema. We can't forget about the bouncer which handles transactions across a pooled connection.

## Notable Documentation Sources
https://www.pgbouncer.org/

https://www.postgresql.org/docs/

https://pgdash.io/blog/pgbouncer-connection-pool.html

## Important Notes:
The pgbouncer handles connections on a different port which is then routed internally to the postgresql database. This allows us to set the size of connections we may handle transactions at anyone time. Ths pgbouncer pools transactions and may cache the connections to reconnect to the datbase when restarting. This allows for seamless maintenance on the database without having to reset connections or deal with potentially orphaned processes. 

Please be aware that not every hosting service will provide sudo privileges and it is not necessary for every setup. This documentation is just a template for those trying to set up the service.

# PostgreSQL & PgBouncer Setup (Linux & BSD)

## 1. Install PostgreSQL

### Linux (Ubuntu/Debian)
```sh
sudo apt update
sudo apt install postgresql postgresql-contrib
```
### BSD (FreeBSD example)
```sh
sudo pkg install postgresql15-server
sudo sysrc postgresql_enable=YES
sudo service postgresql initdb
sudo service postgresql start
```

## 2. Install PgBouncer

### Linux
```sh
sudo apt install pgbouncer
```
### BSD
```sh
sudo pkg install pgbouncer
sudo sysrc pgbouncer_enable=YES
```

## 3. Configure PgBouncer

Edit the files from the pgbouncer path.

```

### pool/userlist.txt
```text
"your_db_user_here" "SCRAM-SHA-256$4096:<salt>$<stored_key>$<server_key>"
```
- Populate with the real PostgreSQL users and SCRAM hashes from:
  ```sql
  SELECT usename, passwd FROM pg_shadow;
  ```

## 4. Apply Database Schema

From the schema directory....

```

Apply this schema with:
```sh
psql -U your_db_user_here -d your_db_name_here -f schema/schema.sql
```

## 5. Start and Enable Services

### Linux
```sh
sudo systemctl enable postgresql
sudo systemctl start postgresql
sudo systemctl enable pgbouncer
sudo systemctl start pgbouncer
```

### BSD
```sh
sudo service postgresql start
sudo service pgbouncer start
```

---
