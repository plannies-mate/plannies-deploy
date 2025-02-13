PLANNIES SETUP
==============

Plannies-Setup is an Ansible playbook to create and destroy the Aussie planners-mate linode VPS with caddy web and squid proxy server.

The proxy is intended for testing morph.io scrapers you are working on.
The web server is intended to host planners-mate web server, with updates by planners-kit 

For example setting MORPH_AUSTRALIAN_PROXY
to http://user:passowrd@planners-mate.exmple.com:43210/

Requirements
------------
 
* Linode account with API token
* Domain with DNS managed by Linode
* Ubuntu linux box (real or virtual)
 
Installing
----------

```bash
git clone https://github.com/planners-mate/planners-setup.git
sudo apt-get install direnv python3 python3-venv python3-pip
```

Configuration
-------------

Uses direnv to set environment variables.

1. Create a `.envrc` file with

```bash
export LINODE_DOMAIN=domain.on.linode
export LINODE_API_TOKEN=value
export GITHUB_CLIENT_ID="your_client_id"
export GITHUB_CLIENT_SECRET="your_client_secret"
```
* The Linode API token access required: must be set to allow write access for 
  * Read for everything
  * Read/Write for Domains and Linodes
  * Can disable access for VPS
  * Note, linode will only serve the domain when you have one or more VPS instances (AKA "linodes")
* The `GITHUB_CLIENT_ID` and `GITHUB_CLIENT_SECRET` from your Organisations - Github Oauth v2 App
  * This is used to authenticate who has access
* Note - this warning will go away once your linode IVPS) is deployed
  * Your DNS zones are not being served.
  * Your domains will not be served by Linode’s nameservers unless you have at least one active Linode on your account

Create web / proxy server
-------------------------

**You are responsible for the costs incurred!**
**This project creates a 1GB Nanobox VPS system!**

```bash
bin/provision create
```

## Destroy proxy box

```bash
bin/provision destroy
```

## Other commands

* `bin/provision` - provides a list of commands and what they do
* `bin/test_proxy` - tests the proxy behaves as expected, 
  runs automatically after create
* `bin/host-status` - runs various status commands on the proxy host
* `bin/ssh-proxy` - ssh to handyman user on proxy host
  with sudo perms

# Links

* [Linode ansible guide](https://www.linode.com/docs/guides/deploy-linodes-using-linode-ansible-collection/)

