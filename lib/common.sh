#!/bin/bash

# Source in bin files to gain common constants and functions

# shellcheck disable=SC2034
VENV_DIR=".venv"

ensure_linode_token() {
    if [ -z "$LINODE_API_TOKEN" ]; then
        echo "Error: LINODE_API_TOKEN environment variable not set"
        exit 1
    fi
}

ensure_all_env_variabls() {
    ensure_linode_token
    if [ -z "$LINODE_DOMAIN" ]; then
        echo "Error: LINODE_DOMAIN environment variable not set"
        exit 1
    fi
    if [ -z "$CLOUDFLARE_DOMAIN" ]; then
        echo "Error: CLOUDFLARE_DOMAIN environment variable not set"
        exit 1
    fi
}

setup_venv() {
    # First deactivate any active Python environment
    if [ -n "$CONDA_EXE" ]; then
        $CONDA_EXE deactivate || echo Ignoring conda error
    fi
    hash -r
    if type deactivate >/dev/null 2>&1; then
        deactivate
    fi
    PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "conda" | tr '\n' ':')
    export PATH
    if [ ! -d "$VENV_DIR" ]; then
        echo "Creating Python virtual environment..."
        python3 -m venv "$VENV_DIR"
    fi
    # shellcheck disable=SC2010
    if ls -l .venv/bin/python* | grep conda ; then
        echo "ERROR: venv still tangled with conda! Aborting"
        exit 2
    fi
    source "$VENV_DIR/bin/activate"
}


check_dependencies() {
    if ! command -v python3 >/dev/null 2>&1; then
        echo "Installing python3..."
        sudo apt install -y python3 python3-venv python3-pip
    fi
    if ! command -v openssl >/dev/null 2>&1; then
        echo "Installing openssl..."
        sudo apt install -y openssl
    fi

    setup_venv

    if [ -f requirements.txt ]; then
        pip install -r requirements.txt | grep -v 'Requirement already satisfied:' || true
     fi

    # ansible-galaxy collection remove community.general 2>/dev/null || true
    for collection in linode.cloud ansible.posix; do
        if ! ansible-galaxy collection list | grep -q "$collection"; then
            echo "Installing $collection collection..."
            ansible-galaxy collection install "$collection"
        fi
    done
}

# Port handling
PORTS_FILE=".ports"

generate_ports() {
    SSH_PORT=$(shuf -i 40000-45000 -n 1)
    PROXY_PORT=$(shuf -i 45001-50000 -n 1)
    PROXY_PASSWORD=$(openssl rand -base64 24 | tr '+/' '-_' | tr -d '=')

    echo "SSH_PORT=$SSH_PORT" > "$PORTS_FILE"
    echo "PROXY_PORT=$PROXY_PORT" >> "$PORTS_FILE"
    echo "PROXY_PASSWORD=$PROXY_PASSWORD" >> "$PORTS_FILE"
}

load_ports() {
    if [ ! -s "$PORTS_FILE" ]; then
        generate_ports
    fi
    # shellcheck disable=SC1090
    source "$PORTS_FILE"
}

export ANSIBLE_LOCALHOST_WARNING=False
export ANSIBLE_INTERPRETER_WARNINGS=False
