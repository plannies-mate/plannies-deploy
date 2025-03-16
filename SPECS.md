# Plannies Deploy Specifications

See Also:
- SPECS-IN-COMMON.md - Specs shared with plannies-mate
- SPECS.MD - specs specific to this project
- IMPLEMENTATION.md - implementation decisions made
- GUIDELINES.md - Guidelines for AIs and Developers (shared with plannies-mate)

Note: README.md is for setup and usage by the Developer

## Core Requirements

1. Squid Proxy
   - User 'morph' with random password
   - Port 45001-50000
   - Protected by firewall and fail2ban

2. SSH Access
   - Port 40000-45000
   - Handyman user with sudo access
   - Protected by fail2ban

3. Web Server (Caddy)
   - HTTPS with HTTP redirects Port 80
   - Serves /var/www/html content
   - Serves unprotected content on http://localhost:81
   - Reverse proxies to port 8080 for protected paths
   - Shows default.html for missing pages
   - robots.txt limiting indexing

4. Authentication Reverse Proxy (OAuth2-Proxy)
   - HTTP on localhost:8080
   - Uses http://localhost:81 as upstream

5. API Service (Sinatra)
   - JSON API endpoints for:
      - `/api/health` - API health status check
      - `/api/scrape` - GET for status, POST for triggering jobs
   - Runs on localhost:4567
   - Protected by OAuth2-Proxy
   - Status tracking via JSON files
   - No database required (Keeps json files in /var/www/api/data)

6. Background Processing
   - Ruby script triggered via cron
   - Scheduled daily full run
   - On-demand runs via trigger file
   - Simple log rotation (keeps yesterday's log, appends to today's)
   
## Environment

See README.md
