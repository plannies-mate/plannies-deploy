# Plannies-Deploy Implementation

See Also:

- SPECS-IN-COMMON.md - Specs shared with plannies-mate
- SPECS.MD - specs specific to this project
- IMPLEMENTATION.md - implementation decisions made
- GUIDELINES.md - Guidelines for AIs and Developers (shared with plannies-mate)

Note: README.md is for setup and usage by the Developer

## Architecture

### Directory Structure and Content Flow

1. Source Content Structure (in roles/web/files/):

```
roles/web/files/
├── assets/          # Static assets copied directly to web root
│   ├── css/        
│   ├── js/         
│   └── images/     
├── contents/       # Raw content to be themed
│   ├── authorities/
│   ├── repos/
│   └── crikey-whats-that/
├── layouts/      # Theme layouts
│   └── default.html
├── favicon.ico     # Direct copy files
└── robots.txt
```

2. Build Process
    - add_theme program:
        - Reads content from
            - roles/web/files/contents/
            - ../plannies-mate/log/contents/
        - Applies layout from roles/web/files/layouts/
        - Outputs to tmp/build/ maintaining directory structure

3. Web Root Structure (/var/www/html):

```
/var/www/html/
├── assets/          # Copied directly from roles/web/files/assets
├── authorities/     # Themed content from tmp/build/authorities
├── repos/          # Themed content from tmp/build/repos
└── crikey-whats-that/     # Themed content from tmp/build/crikey-whats-that
```

### Content Management

1. Theme System
    - layouts support substitution of:
        - {{TITLE}} and {{CONTENT}} from contents file
        - {{FAVICON}} and {{SECTION}} for crikey-whats-that or default
        - {{LAST_CHECKED}} which indicates the freshness of the plannies-mate contents file
          or time deployed for the other contents
    - Theme applied during build, not runtime
    - Default layout provides standard header/footer
    - Error pages follow same theming

2. Content Updates
    - Ansible copies assets directly
    - Themed content copied from tmp/build/
    - Maintains separation between raw and themed content in the repos (themed content is not committed to git)

#### Theme Notes

- Uses Font Awesome icons via CDN
- Uses Topography pattern from heropatterns.com for subtle background texture
- Uses Green and gold Australian color scheme
- Landing page is a clean bold design with a splash of fun, whilst being informative
- Everything else continues the theme but is focused on being useful to me and my fellow co-workers
- Whimsical Aussie wording and phrasing, with the typical Aussie not taking ourselves too seriously
    - Despite this, Usefulness and clarity is TOP priority

### Security Implementation

1. SSH Configuration
    - Key-based authentication only
    - No root login
    - Fail2ban settings
    - Limited retry attempts

2. Proxy Setup
    - Authentication configuration
    - NO Rate limiting rules (as its used by scrapers)
    - Fail2ban protection
    - Header cleanup

3. Web Security
    - HTTPS configuration
    - Security headers
    - Rate limiting rules (Still to Do)
    - Protected route setup (TBD)

### Port Management

- Stored in .ports file:
- SSH_PORT: Random 40000-45000
- PROXY_PORT: Random 45001-50000
- PROXY_PASSWORD: Random base64 string
- Generated on first run
- Used by Ansible via group_vars/all

### Inventory Structure

- Dynamic: linodes.linode.yml (tag: proxies)
- Static: localhost.yml for local execution
- Host groups: proxies, localhost

## Key Workflows

1. Instance Creation (`bin/provision create` uses `create.yml`)
    - Creates Linode instance with random root password
    - Adds SSH key from ~/.ssh/id_ed25519.pub or id_rsa.pub
    - Configures custom SSH port
    - Sets up Squid proxy with auth and random port and password
    - Adds DNS record: plannies-mate.<LINODE_DOMAIN>
    - Uses uncommon enough deploy username (handyman)

2. Instance Destruction (`bin/provision destroy` uses `destroy.yml`)
    - Removes Linode instance
    - Cleans up DNS record

3. Content Deployment
    - build_theme processes content with layouts
    - Ansible deploys:
        - System configuration
        - Static assets directly
        - Themed content from build directory

## Dependencies

Fail fast with message if missing where required for processing:

- Ruby 3.2.3 (default on Ubuntu 24.04 Noble)
- Ansible
- Git
- Required gems
- Linode API access

## API Service Implementation

### Architecture

1. Lightweight Sinatra API
    - JSON-only API endpoints
    - Runs on localhost:4567
    - Minimal gem dependencies
    - File-based state management
    - Protected behind OAuth2-Proxy

2. State Management
    - Uses JSON files in /var/www/api/data
    - scrape_status.json contains:
        - Last check timestamps
        - Current status
        - Pending job status
    - trigger_scrape file for on-demand processing

3. Background Processing
    - Ruby script executed via cron
    - Daily scheduled run at midnight
    - Checks every 15 minutes for triggers
    - Simple log rotation approach
    - Stateless execution model

### Integration Points

1. Caddy Configuration
    - /api endpoints proxied to OAuth2-Proxy for authentication
    - OAuth2-Proxy proxies /api to Sinatra
    - No direct external access

2. Authentication Flow
    - Users authenticated via OAuth2-Proxy
    - No additional auth required for API
    - both GET and POST endpoints protected by same OAuth flow

### Resource Usage

- Memory: ~40MB for Sinatra process
- CPU: Low, except during analysis
- Disk: Minimal for logs and state files

### Development

Run

* `roles/api/files/app.rb` for api server
* `roles/api/files/bin/analyze-scrapers.rb` for periodic task
* git ignores `roles/api/files/data`

## Testing System

Use `bin/test_proxy` and `bin/test_web`

1. Proxy Tests
    - Authentication validation
    - Functionality verification
    - Performance metrics
    - Security checks

2. Web Tests
    - HTTPS validation
    - Content verification
    - Auth testing
    - Error handling

## Plannies mate authentications

We are using Cloudflare for plannies-mate.thesite.info in front of plannies-make.psst.link as back end and proxy.

When you authenticate, don't give access to organisations.

Test shows info matched against access rules:

```json
{
  "name": null,
  "email": "ian+oaf@heggie.biz",
  "groups": []
}
```

## Testing Philosophy:

* Test against reality, not what we think it should be!
    * Use VCR for external API calls instead of mocking
    * Use real components unless there's a compelling reason to mock
* Keep tests under 200 lines by splitting into multiple focused files
* Use appropriately named subdirectories when splitting test files - rubymine expects `SomeClass` to be tested using
  `some_class_spec.rb` but allows multiple files in differently named sibling directories.

## Code Organization Principles:

* Split large files into focused components (< 200 lines)
* use extend with Helper Modules and `class InstanceMethods ... end` and `send :include, InstanceMethods` within the
  helper module for those methods that require access to instance state. This unfortunately means that many helper
  methods need to be accessed using `self.class.method_name` but we sometimes need to access them from class methods.
