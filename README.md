# down_under
Ansible provisioner to create and destroy Aussie or other linode proxies


# Links

* [Linode ansible guide](https://www.linode.com/docs/guides/deploy-linodes-using-linode-ansible-collection/)
* 

# Core Components Analysis

## Configuration Flow
1. Environment Variables
    - LINODE_API_TOKEN: Linode API access
    - PROXY_PASSWORD: Squid auth password
    - PROXY_DOMAIN: Base domain for proxy DNS

2. Port Management (.ports)
    - SSH_PORT: Random 40000-45000
    - PROXY_PORT: Random 45001-50000
    - Generated on first run
    - Used by Ansible via group_vars/all

3. Inventory Structure
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

## Testing Plan

1. Creation Testing
    - Run: bin/provision create au
    - Verify:
        * Instance created with correct specs
        * SSH accessible on custom port
        * Squid proxy running on custom port
        * DNS record matches IP
        * Auth works with PROXY_PASSWORD

2. Port Transition
    - Delete .ports and regenerate
    - Verify SSH and proxy ports update
    - Check connectivity on new ports

3. Proxy Authentication
    - Test with curl:
      ```bash
      export proxy="http://morph:${PROXY_PASSWORD}@au-proxy.${PROXY_DOMAIN}:${PROXY_PORT}"
      curl -x $proxy http://example.com
      ```

4. Status Check
    - Run: bin/provision status
    - Verify reports:
        * DNS resolution
        * SSH connectivity
        * Proxy availability
        * Uptime information