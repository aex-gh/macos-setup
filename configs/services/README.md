# Service Configuration Files

This directory contains configuration files for services installed via Homebrew or other package managers.

## Nginx

### nginx.conf
Development-optimised Nginx configuration with:
- Auto worker processes based on CPU cores
- Gzip compression enabled
- Security headers configured
- Logs in Homebrew directories
- Default port 8080 (macOS-friendly)

Installation:
```bash
# Install nginx via Homebrew
brew install nginx

# Backup original configuration
cp /opt/homebrew/etc/nginx/nginx.conf /opt/homebrew/etc/nginx/nginx.conf.backup

# Install new configuration
cp nginx.conf /opt/homebrew/etc/nginx/nginx.conf

# Test configuration
nginx -t

# Start/restart nginx
brew services restart nginx
```

## PostgreSQL Configuration (Example)

For PostgreSQL configurations, create `postgresql.conf` with custom settings and install to:
- Intel Mac: `/usr/local/var/postgres/`
- Apple Silicon: `/opt/homebrew/var/postgresql@14/`

## Redis Configuration (Example)

For Redis configurations, create `redis.conf` and install to:
- Intel Mac: `/usr/local/etc/redis.conf`
- Apple Silicon: `/opt/homebrew/etc/redis.conf`