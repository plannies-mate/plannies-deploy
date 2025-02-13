IMPLEMENTATION
==============

## Technical details

### Port Management 

- Stored in .ports file:
- `SSH_PORT`: Random 40000-45000
- `PROXY_PORT`: Random 45001-50000
- Generated on first run
- Used by Ansible via `group_vars/all`

### Inventory Structure

- Dynamic: linodes.linode.yml (tag: proxies)
- Static: localhost.yml for local execution
- Host groups: proxies, localhost

## Key Workflows

1. Instance Creation (create.yml)

- Creates Linode instance with random root password
- Adds SSH key from `~/.ssh/id_ed25519.pub` or `id_rsa.pub`
- Configures custom SSH port
- Sets up Squid proxy with auth
- Adds DNS record: plannies-mate.<LINODE_DOMAIN>

2. Instance Destruction (destroy.yml)

- Removes Linode instance
- Cleans up DNS record

## Testing Plan

2. Port Transition
    - destroy proxy host 
    - Delete .ports and regenerate
    - Verify SSH and proxy ports use new values
    - Check connectivity on new ports

3. Proxy Authentication
    - Test with curl:
      ```bash
      export proxy="http://morph:${PROXY_PASSWORD}@plannies-mate.${LINODE_DOMAIN}:${PROXY_PORT}"
      curl -x $proxy http://example.com
      ```
    - OR test with `bin/test_proxy`

