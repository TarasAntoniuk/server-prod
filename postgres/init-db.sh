#!/bin/bash
set -e

# This script runs during PostgreSQL initialization
# It reads passwords from environment variables instead of hardcoding them

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- ============================================
    -- Finance Database
    -- ============================================
    CREATE DATABASE finance;
    CREATE USER $FINANCE_DB_USER WITH PASSWORD '$FINANCE_DB_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE finance TO $FINANCE_DB_USER;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "finance" <<-EOSQL
    GRANT ALL ON SCHEMA public TO $FINANCE_DB_USER;
    ALTER SCHEMA public OWNER TO $FINANCE_DB_USER;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    -- ============================================
    -- Time Tracking Database
    -- ============================================
    CREATE DATABASE time_tracking;
    CREATE USER $TIMETRACKING_DB_USER WITH PASSWORD '$TIMETRACKING_DB_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE time_tracking TO $TIMETRACKING_DB_USER;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "time_tracking" <<-EOSQL
    GRANT ALL ON SCHEMA public TO $TIMETRACKING_DB_USER;
    ALTER SCHEMA public OWNER TO $TIMETRACKING_DB_USER;
EOSQL

echo "============================================"
echo "Database initialization completed successfully"
echo "============================================"
echo "Created databases: finance, time_tracking"
echo "Created users: $FINANCE_DB_USER, $TIMETRACKING_DB_USER"
