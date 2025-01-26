# down_under
Ansible provisioner to create and destroy Aussie , USA or EU linode proxies.

The main purpose for existing is to provide a proxy url for
testing morph.io scrapers you are working on.

For example setting MORPH_AUSTRALIAN_PROXY
to http://user:passowrd@au-proxy.exmple.com:43210/

## Requirements
 
* Linode account with API token
* Domain with DNS managed by Linode
* Ubuntu linux box (real or virtual)
 
## Installing

```bash
git clone https://github.com/ianheggie/down_under.git
sudo apt-get install direnv python3 python3-venv python3-pip
```

## Configuration

1. copy .envrc.example to .envrc 
2. set
    - LINODE_API_TOKEN: Linode API token access
    - PROXY_PASSWORD: Random Squid auth password
    - PROXY_DOMAIN: A domain for proxy DNS that you 
      have set the name servers so linode hosts the domain
      - Note, linode will only serve the domain when you have
        one or more VPS instances (AKA "linodes")

## Create proxy box
**You are responsible for the costs incurred!**
**This project creates a 1GB Nanobox VPS system!**

```bash
bin/provision create au # or usa or eu
```

## Destroy proxy box

```bash
bin/provision destroy au # or usa or eu
```

## Technical details

### Port Management 

- Stored in .ports file:
- SSH_PORT: Random 40000-45000
- PROXY_PORT: Random 45001-50000
- Generated on first run
- Used by Ansible via group_vars/all

### Inventory Structure

- Dynamic: linodes.linode.yml (tag: proxies)
- Static: localhost.yml for local execution
- Host groups: proxies, localhost

## Key Workflows

1. Instance Creation (create.yml)
   ```yaml
   Flow:
   - Create Linode instance with random root password
   - Add SSH key from ~/.ssh/id_ed25519.pub or id_rsa.pub
   - Configure custom SSH port
   - Setup Squid proxy with auth
   - Add DNS record: <region>-proxy.<PROXY_DOMAIN>
   ```

2. Instance Destruction (destroy.yml)
   ```yaml
   Flow:
   - Remove Linode instance
   - Clean up DNS record
   ```
### Other commands

* bin/provision - provides a list of commands and what they do
* bin/test_proxy - tests the proxy behaves as expected, 
  runs automatically after create
* bin/host-status - runs various status commands on the proxy host
* bin/ssh-proxy - ssh to handyman user on proxy host
  with sudo perms

## Testing Plan

2. Port Transition
    - destroy proxy host 
    - Delete .ports and regenerate
    - Verify SSH and proxy ports use new values
    - Check connectivity on new ports

3. Proxy Authentication
    - Test with curl:
      ```bash
      export proxy="http://morph:${PROXY_PASSWORD}@au-proxy.${PROXY_DOMAIN}:${PROXY_PORT}"
      curl -x $proxy http://example.com
      ```
    - OR test with bin/test_proxy

# Links

* [Linode ansible guide](https://www.linode.com/docs/guides/deploy-linodes-using-linode-ansible-collection/)
