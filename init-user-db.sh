#!/bin/bash

set -e

# Add the shared_preload_libraries to the postgresql.conf file
echo "shared_preload_libraries = 'pg_duckdb'" >> /var/lib/postgresql/data/postgresql.conf
echo "listen_addresses = '*'" >> /var/lib/postgresql/data/postgresql.conf


# Create the database and user and install the extension
# Enable DuckDB execution for the user:
# ALTER USER "$POSTGRES_USER" SET duckdb.execution TO true;
# This is opt-in to avoid breaking existing queries for other users
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    ALTER USER "$POSTGRES_USER" SET duckdb.execution TO true;
    SELECT * FROM pg_available_extensions WHERE name = 'pg_duckdb';
    SELECT current_user;
    SELECT current_database();
EOSQL
