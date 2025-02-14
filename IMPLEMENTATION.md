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
│   └── whats_that/
├── templates/      # Theme templates
│   └── default.html
├── favicon.ico     # Direct copy files
└── robots.txt
```

2. Build Process
    - add_theme program:
        - Reads content from
            - roles/web/files/contents/
            - ../plannies-mate/log/contents/
        - Applies template from roles/web/files/templates/
        - Outputs to tmp/build/ maintaining directory structure

3. Web Root Structure (/var/www/html):

```
/var/www/html/
├── assets/          # Copied directly from roles/web/files/assets
├── authorities/     # Themed content from tmp/build/authorities
├── repos/          # Themed content from tmp/build/repos
└── whats_that/     # Themed content from tmp/build/whats_that
```

### Content Management

1. Theme System
    - Templates support substitution of:
        - {{TITLE}} and {{CONTENT}} from contents file
        - {{FAVICON}} and {{SECTION}} for whats_that or default
        - {{LAST_CHECKED}} which indicates the freshness of the plannies-mate contents file
          or time deployed for the other contents
    - Theme applied during build, not runtime
    - Default template provides standard header/footer
    - Error pages follow same theming

2. Content Updates
    - Ansible copies assets directly
    - Themed content copied from tmp/build/
    - Maintains separation between raw and themed content in the repos (themed content is not committed to git)

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
    - build_theme processes content with templates
    - Ansible deploys:
        - System configuration
        - Static assets directly
        - Themed content from build directory

## Dependencies

Fail fast with message if missing where required for processing:

- Ruby 3.3 or newer
- Ansible
- Git
- Required gems
- Linode API access

## Testing System

Use `bin/test_proxy`

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
   
# Misc Notes

Current structure:
/docs/
├── index.html           # Landing page with hero image
├── cricky-whats-that.html  # The analyzer page (to be built)
├── css/
│   ├── base.css        # Layout and structure
│   └── theme.css       # Colors, fonts, decorative elements
└── js/
    └── analyzer.js     # Analyzer logic (to be built)

The landing page uses:
- Hero image: Twelve Apostles (https://images.unsplash.com/photo-1519406155028-jmHJLXHHRXA)
- Font Awesome icons via CDN
- My GitHub avatar: https://avatars.githubusercontent.com/u/183138466
- Topography pattern from heropatterns.com for subtle background texture
- Green and gold Australian color scheme

The analyzer uses:
- List of repos from https://github.com/orgs/planningalerts-scrapers/repositories.json
- removes the prefix "multiple_" from repo name and then searches for the name (case insenesitive) in the contents of the drag and dropped url.
  - the text could be in body text, src, hrefs etc - so don't botehr analysing the oage, just do a text search.
- allow for some custom search functions for specific examples, but at the moment the text search will be sufficient.
- sort by relevance.
- score text that is a valid dictonary word lower than unique strings
- score text that is not preceeded or followed by alpha characters much higher, as otherwise "act" wil match "action" for instance (act is an australian state)
- also add to the score if one or more words from the repo description are present.

This will become an analyser to determine which of the https://github.com/orgs/planningalerts-scrapers/repositories scrapers to use.

What I have manually discovered:
* multiple_civica is detected by discovering a script src with */civica.jquery.*
* multiple_planbuild is detected because of the words "PlanBuild Tasmania".
* multiple_epathway_scraper is detected because of a link that includes */ePathway/*
