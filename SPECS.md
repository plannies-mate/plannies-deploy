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

## Environment

See README.md
