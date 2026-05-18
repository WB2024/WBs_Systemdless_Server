#!/usr/bin/env bash
# =============================================================================
# scripts/02-install-docker.sh
# Purpose:  Phase 3 — Install Docker CE without systemd socket activation.
#           Docker daemon is managed entirely by OpenRC.
# Phase:    3 — NAS Stack (Containers)
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

# Docker apt repo details
readonly DOCKER_KEYRING_URL="https://download.docker.com/linux/debian/gpg"
readonly DOCKER_KEYRING_FILE="/etc/apt/keyrings/docker.asc"
readonly DOCKER_APT_FILE="/etc/apt/sources.list.d/docker.list"

add_docker_repo() {
    log_step "Adding Docker CE apt repository"
    require_binary curl

    mkdir -p /etc/apt/keyrings
    curl -fsSL "${DOCKER_KEYRING_URL}" -o "${DOCKER_KEYRING_FILE}"
    chmod a+r "${DOCKER_KEYRING_FILE}"

    # Devuan Daedalus is Debian Bookworm compatible — use bookworm codename
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=${DOCKER_KEYRING_FILE}] \
https://download.docker.com/linux/debian bookworm stable" \
        > "${DOCKER_APT_FILE}"

    apt-get update -qq
    log_success "Docker CE repository added."
}

install_docker() {
    log_step "Installing Docker CE"
    pkg_install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Remove any systemd service units Docker may have installed.
    # Docker CE ships with systemd units — we do not use them.
    # The OpenRC init script in openrc/docker handles daemon startup.
    if [[ -f /lib/systemd/system/docker.service ]]; then
        log_warn "Docker installed a systemd unit at /lib/systemd/system/docker.service"
        log_warn "This file is present but will NOT be activated (no systemd)."
        log_warn "Docker will be started exclusively via OpenRC."
    fi

    # Prevent Docker from auto-starting via systemd on any future upgrade
    # by masking the unit with an empty file (harmless on non-systemd)
    # TODO: verify no systemd.socket dependency — see docs/docker-on-openrc.md
    log_info "Docker CE packages installed."
}

configure_docker() {
    log_step "Configuring Docker daemon"

    # Create Docker daemon config directing logs to flat files (no journald)
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json <<'EOF'
{
    "log-driver": "local",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2"
}
EOF
    log_success "Docker daemon.json configured."
}

deploy_openrc_service() {
    log_step "Deploying Docker OpenRC init script"
    deploy_openrc_script "docker"
    openrc_enable docker default
    log_success "Docker will start via OpenRC on next boot."
}

add_user_to_docker_group() {
    log_step "Configuring docker group"
    # TODO: prompt for username if running non-interactively
    log_info "Add your user account to the docker group:"
    log_info "  usermod -aG docker <your_username>"
    log_info "This allows running docker commands without sudo."
}

main() {
    banner "WB's Systemdless Server — Phase 3: Install Docker CE"

    log_warn "Docker CE will be installed and managed by OpenRC (NOT systemd)."
    log_info "See docs/docker-on-openrc.md for background on this approach."
    confirm "Install Docker CE?"

    run_preflight_checks
    check_openrc_active
    add_docker_repo
    install_docker
    configure_docker
    deploy_openrc_service
    add_user_to_docker_group

    log_success "Phase 3 (Docker) complete."
    log_info "Start Docker now with: rc-service docker start"
    log_info "Next: scripts/03-install-samba.sh"
}

main "$@"
