# Plannies Deploy Specifications

See Also:

- SPECS-IN-COMMON.md - Specs shared with plannies-mate
- SPECS.MD - specs specific to this project
- IMPLEMENTATION.md - implementation decisions made
- GUIDELINES.md - Guidelines for AIs and Developers (shared with plannies-mate)

Note: README.md is for setup and usage by the Developer

## The Big Picture

There are a variety of reports I want from the system:

### Scraper and Authority Lists and Status pages

Files generated and classes that do the generation (each called from their own task, similar to how fetchers are called)

* `data_dir/scrapers/index.html` - list of scrapers with a table of the associated authorities grouped under each
  class: `lib/generate_scrapers.rb`
* `data_dir/scrapers/scraper_base_name.html` - details of scraper (currently just the github and auth links and a list of
  authorities that use the scraper)
  class: `lib/generate_scraper.rb`
* `data_dir/authorities/index.html` - table of authorities with scraper and detail relative links - order by authority
  class: `lib/generate_authorities.rb`
* DISCUSS if we generate different pages for different sort orders, or use a javascript plugin to sort the table (prefer
  as we will later also add filtering)
* `data_dir/authorities/short_name.html` - detailed page for each authority listing all the details we have
  class: `lib/generate_authority.rb`

Repos Index is grouped by

* h1. Multi / Custom / Unused
* h2. Scraper (in order of score for multi)

The Multis are their own H2 headings. The Custom (single authority related to one scraper) are all in one table. The
Unused will be the scrapers we find from github that are not mentioned on any authority details page.

Links (can be a terse list of links):

* github: "repo", PR link, issue numbers, status (In Progress etc), tags listed beside
* morph: production, ianheggie-oaf (if available)
* info - links to a detailed page for each authority

* table of authorities in order of score within scraper, listing
    * authority name
    * state
    * population
    * months down (if down) otherwise blank if up
    * production month count
    * spec count (expected records in spec if updated since scraper went down)
    * test count (records from Ian's run of scraper)

### How is what I am working progressing?

There should be a "in_progress" report

* Scrapers who have one or more tickets assigned to me with Project Status "In Progress" should be listed here

This is where I want to merge in status from

* my repos on morph - which wil give me last error or last records scraped,
* the spec/expected/*.yml files in the git repo (where they have been refreshed well after the scraper stopped working)

### What has been assigned to me?

I want a "assigned_to_me" report with the following groups, which are roughly in the order I should work on them.

Later I will consider allowing selection of selecting other assignees.

Groups with nothing in them should not be listed.

* **My To Do**
    * Scrapers who have one or more tickets assigned to me with Project Status "ToDo"

* **My Blocked**
    * Scrapers who have one or more tickets assigned to me with Project Status "Blocked"
    * Action: get help to unblock, or assign through to someone who can get help.

* **My Done**
    * Scrapers who have one or more tickets assigned to me with Project Status "Done"
    * Action: Assign through to a reviewer to sign off on closing

### What should I consider next

* List scrapers that have some tickets with positive score in order of the sum of the scores
* Add in some diagnostics based on analysing the repos:
    * Is the url still viable (hostname still valid in DNS?)

### Reviewing other tickets

* **unmatched Tickets**
    * List tickets that are unassigned and could not be matched to a scraper here

### Ignore list

* scrapers whose open tickets are all zero score get grouped here

### Scoring

Score tickets by months since data has been received times population divided by 100,000 - round to two decimal places

* Adjust ticket score based on presence of tags:
    * "custom" *= 0.9 - minor extra work
    * "council website good" *= 1.1 - someone has confirmed the info is available
    * "new scraper needed" *= 0.1 (Do after existing)
    * "PDF" += 0.7 - extra work
    * "PhP" *= 0.05 - dislike the language and libraries
    * "quick fix" *= 1.2
    * "reported" *= 3 - better work of mouth when we fix things
    * "waiting callback" *= 0.5 - someone else is following up

* Score tickets that are have any of these tags as zero score:
    * "anti scraping technology"
    * "council website bad"
    * "blocked by authority"
    * "does not publish"
    * "no da tracking site"

* Score tickets that are assigned to other people as zero score

* Score tickets that are not marked "Possibly Broken" in the PlanningAlerts list as zero score.

### Has a site changed to something an existing scraper already handles?

This is the focus of the "Crikey, Whats That!?" sub-project - extracting significant search strings from each of the
repos to find which scraper best matches a sites new search results page.

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
