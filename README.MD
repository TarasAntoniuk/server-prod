# Shared Infrastructure (Production)

Centralized infrastructure for all production backend applications: PostgreSQL, Nginx, and SSL management.

## Architecture
```
┌─────────────────────────────────────┐
│   Shared Infrastructure             │
│                                     │
│   - Nginx (reverse proxy)           │
│   - Certbot (SSL certificates)      │
│   - PostgreSQL (shared database)    │
└─────────────────────────────────────┘
           ↓         ↓
    ┌──────────┐  ┌──────────────┐
    │ Finance  │  │ Time-Tracking│
    │ App      │  │ App          │
    │ :8080    │  │ :8081        │
    └──────────┘  └──────────────┘
```

## Directory Structure
```
server-prod/
├── docker-compose.yml       # Main infrastructure services
├── .env.example             # Environment variables template
├── .env                     # Actual env vars (not in git)
├── nginx/
│   ├── nginx.conf           # Main Nginx config
│   └── conf.d/
│       ├── finance.conf     # api.tarasantoniuk.com
│       └── timetracking.conf # timetracking.tarasantoniuk.com
├── postgres/
│   └── init-db.sh           # Database initialization script
├── certs/                   # SSL certificates (auto-created)
├── webroot/                 # Certbot webroot (auto-created)
└── logs/                    # Nginx logs (auto-created)
```

## Prerequisites

- Docker and Docker Compose installed
- Domain names pointing to server:
  - api.tarasantoniuk.com
  - timetracking.tarasantoniuk.com
- Ports 80 and 443 available
- SSH access to server

## Setup

### 1. Configure Environment
```bash
cp .env.example .env
nano .env
```

Update passwords:
```env
POSTGRES_PASSWORD=your_strong_postgres_password
FINANCE_DB_PASSWORD=your_strong_finance_password
TIMETRACKING_DB_PASSWORD=your_strong_timetracking_password
```

### 2. Deploy Infrastructure
```bash
# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 3. Verify PostgreSQL
```bash
# Connect to PostgreSQL
docker exec -it shared-postgres psql -U postgres

# List databases
\l

# Check users
\du

# Exit
\q
```

### 4. Verify Nginx
```bash
# Test configuration
docker exec shared-nginx nginx -t

# Check which configs are loaded
docker exec shared-nginx ls -la /etc/nginx/conf.d/

# View logs
docker exec shared-nginx tail -f /var/log/nginx/access.log
```

## Migration Notes

### Temporary Ports During Migration

To avoid conflicts with existing services:

- **PostgreSQL**: `127.0.0.1:5433:5432` (temporary, will change to 5432)
- **Nginx HTTP**: `8080:80` (temporary, will change to 80)
- **Nginx HTTPS**: `8443:443` (temporary, will change to 443)

After migration is complete, update `docker-compose.yml` to use standard ports.

## Database Credentials

### PostgreSQL Admin
- Host: `shared-postgres` (inside Docker) or `127.0.0.1:5433` (from host)
- User: `postgres`
- Password: from `.env`

### Finance Database
- Database: `finance`
- User: `finance_user`
- Password: from `.env`

### Time Tracking Database
- Database: `time_tracking`
- User: `timetracking_user`
- Password: from `.env`

## Adding New Projects

1. **Update `.env`:**
```env
NEWPROJECT_DB_USER=newproject_user
NEWPROJECT_DB_PASSWORD=your_password
```

2. **Update `postgres/init-db.sh`:**
```bash
psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE newproject;
    CREATE USER $NEWPROJECT_DB_USER WITH PASSWORD '$NEWPROJECT_DB_PASSWORD';
    GRANT ALL PRIVILEGES ON DATABASE newproject TO $NEWPROJECT_DB_USER;
EOSQL
```

3. **Add Nginx config** in `nginx/conf.d/newproject.conf`

4. **Restart infrastructure:**
```bash
docker-compose down
docker-compose up -d
```

## Management

### Start/Stop Services
```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Restart
docker-compose restart

# Restart specific service
docker-compose restart shared-nginx
```

### View Logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f shared-postgres
docker-compose logs -f shared-nginx
```

### Nginx Operations
```bash
# Reload config (no downtime)
docker exec shared-nginx nginx -s reload

# Test config
docker exec shared-nginx nginx -t

# View error log
docker exec shared-nginx tail -f /var/log/nginx/error.log
```

### PostgreSQL Operations
```bash
# Backup database
docker exec shared-postgres pg_dump -U postgres finance > finance_backup.sql

# Restore database
docker exec -i shared-postgres psql -U postgres finance < finance_backup.sql

# Connect to database
docker exec -it shared-postgres psql -U postgres -d finance
```

### SSL Certificate Renewal

Certificates renew automatically every 12 hours. Manual renewal:
```bash
docker exec shared-certbot certbot renew
docker exec shared-nginx nginx -s reload
```

## Troubleshooting

### PostgreSQL Connection Issues
```bash
# Check if running
docker ps | grep shared-postgres

# Check logs
docker logs shared-postgres

# Test connection
docker exec shared-postgres pg_isready -U postgres

# Connect manually
docker exec -it shared-postgres psql -U postgres
```

### Nginx Issues
```bash
# Check config
docker exec shared-nginx nginx -t

# Check logs
docker logs shared-nginx
docker exec shared-nginx tail -50 /var/log/nginx/error.log

# Reload config
docker exec shared-nginx nginx -s reload
```

### Network Issues
```bash
# Check network
docker network inspect app-network

# Check which containers are connected
docker network inspect app-network --format '{{json .Containers}}'
```

## Security

- ✅ All passwords in `.env` (not committed to git)
- ✅ PostgreSQL only accessible from Docker network
- ✅ Each app has separate database user
- ✅ SSL/TLS encryption for all traffic
- ✅ Automatic blocking of scanner bots
- ✅ Security headers enabled

## Monitoring
```bash
# Container stats
docker stats

# Disk usage
docker system df

# Check health
docker-compose ps
```

## Backup Strategy

### Automated Backups (Recommended)

Create cron job:
```bash
0 2 * * * docker exec shared-postgres pg_dump -U postgres finance > /backups/finance_$(date +\%Y\%m\%d).sql
0 2 * * * docker exec shared-postgres pg_dump -U postgres time_tracking > /backups/timetracking_$(date +\%Y\%m\%d).sql
```

### Manual Backup
```bash
# Create backup directory
mkdir -p backups

# Backup all databases
docker exec shared-postgres pg_dumpall -U postgres > backups/all_databases_$(date +%Y%m%d).sql
```

## Support

For issues:
1. Check logs: `docker-compose logs -f`
2. Check health: `docker-compose ps`
3. Review this README
