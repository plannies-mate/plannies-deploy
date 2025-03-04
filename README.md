PLANNIES DEPLOY
===============

Plannies-Deploy is an Ansible playbook to create and destroy the Aussie planners-mate linode VPS with caddy web and
squid proxy server.

The proxy is intended for testing morph.io scrapers you are working on.
The web server is intended to host planners-mate web server, with updates by planners-kit

For example setting MORPH_AUSTRALIAN_PROXY
to http://user:password@planners-mate.exmple.com:43210/

See Also:

- SPECS-IN-COMMON.md - Specs shared with plannies-mate
- SPECS.MD - specs specific to this project
- IMPLEMENTATION.md - implementation decisions made
- GUIDELINES.md - Guidelines for AIs and Developers (shared with plannies-mate)

Requirements
------------

* Linode account with API token
* Domain with DNS managed by Linode
* Ubuntu linux box (real or virtual)

Installing
----------

```bash
git clone https://github.com/planners-mate/planners-deploy.git
sudo apt-get install direnv python3 python3-venv python3-pip
```

Configuration
-------------

Uses direnv to set environment variables.

1. Create a `.envrc` file with

```bash
export LINODE_DOMAIN=domain.on.linode
export LINODE_API_TOKEN=value.from.creating.personal.token
export GITHUB_CLIENT_ID="your_client_id"
export GITHUB_CLIENT_SECRET="your_client_secret"
export UBUNTU_PRO_TOKEN=value-from-ubuntu.com/pro/dashboard
```

* The Linode API token access required: must be set to allow write access for
    * Read Only for Account, Events, Images and IPs
    * Read/Write for Domains and Linodes
    * You can leave everything else disabled or read access
    * Note, linode will only serve the domain when you have one or more VPS instances (AKA "linodes")
* The `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` from your Organisations - Github Oauth v2 App
    * This is used to authenticate who has access
* Note - this warning will go away once your linode IVPS) is deployed
    * Your DNS zones are not being served.
    * Your domains will not be served by Linode’s nameservers unless you have at least one active Linode on your account
* The `UBUNTU_PRO_TOKEN` is optional - it is free for the first 5 private servers from https://ubuntu.com/pro/dashboard

Create web / proxy server
-------------------------

**You are responsible for the costs incurred!**
**This project creates a 1GB Nanobox VPS system!**

```bash
bin/provision create
```

This will take about 4 - 5 minutes.

## Destroy proxy box

```bash
bin/provision destroy
```

## Other commands

* `bin/provision` - provides a list of commands and what they do
* `bin/test_proxy` - tests the proxy behaves as expected and starts automatically
* `bin/test_web` - tests the web server behaves as expected and starts automatically
* `bin/host-status` - runs various status commands on the proxy host
* `bin/ssh-proxy` - ssh to handyman user on proxy host
  with sudo perms

# Links

* [Linode ansible guide](https://www.linode.com/docs/guides/deploy-linodes-using-linode-ansible-collection/)

