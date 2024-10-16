#!/bin/bash

set -e

# Create the database and user and install the extension
# Enable DuckDB execution for the user:
# ALTER USER "$POSTGRES_USER" SET duckdb.execution TO true;
# This is opt-in to avoid breaking existing queries for other users
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE USER EXISTS "$POSTGRES_USER" WITH PASSWORD '$POSTGRES_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE "$POSTGRES_DB" TO "$POSTGRES_USER";
    CREATE EXTENSION pg_duckdb;
    ALTER USER "$POSTGRES_USER" SET duckdb.execution TO true;
EOSQL
