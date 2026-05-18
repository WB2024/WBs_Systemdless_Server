#!/usr/bin/env bash
# =============================================================================
# scripts/06-install-tailscale.sh
# Purpose:  Phase 4 — Install Tailscale and configure it under OpenRC.
#           Provides zero-config VPN access to the NAS from anywhere.
#           tailscaled daemon is managed by OpenRC (not systemd).
# Phase:    4 — Remote Access
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

readonly TAILSCALE_KEYRING_URL="https://pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg"
readonly TAILSCALE_KEYRING_FILE="/usr/share/keyrings/tailscale-archive-keyring.gpg"
readonly TAILSCALE_APT_FILE="/etc/apt/sources.list.d/tailscale.list"

add_tailscale_repo() {
    log_step "Adding Tailscale apt repository"
    require_binary curl

    curl -fsSL "${TAILSCALE_KEYRING_URL}" -o "${TAILSCALE_KEYRING_FILE}"

    # Use Debian Bookworm codename (Devuan Daedalus is Bookworm-compatible)
    echo \
        "deb [signed-by=${TAILSCALE_KEYRING_FILE}] \
https://pkgs.tailscale.com/stable/debian bookworm main" \
        > "${TAILSCALE_APT_FILE}"

    apt-get update -qq
    log_success "Tailscale repository added."
}

install_tailscale() {
    log_step "Installing Tailscale"
    pkg_install tailscale

    # Tailscale's package may install a systemd service unit. We don't use it.
    # The OpenRC init script (openrc/tailscaled) handles daemon management.
    # TODO: test on live Devuan system — confirm tailscaled binary path
    log_info "tailscale and tailscaled installed."
    log_info "Daemon binary: $(command -v tailscaled || echo 'not found — check PATH')"
}

deploy_openrc_service() {
    log_step "Deploying tailscaled OpenRC init script"
    deploy_openrc_script "tailscaled"
    openrc_enable tailscaled default
    log_success "tailscaled enabled in OpenRC default runlevel."
}

start_tailscaled() {
    log_step "Starting tailscaled daemon"
    if rc-service tailscaled start; then
        log_success "tailscaled started."
    else
        log_error "tailscaled failed to start. Check /var/log/messages for errors."
        exit 1
    fi
}

run_tailscale_up() {
    log_step "Authenticating with Tailscale"
    log_info "Running: tailscale up"
    log_info "A login URL will appear — open it in a browser to authenticate."
    log_info "Use --advertise-tags or --ssh flags if required by your Tailscale policy."
    echo ""
    # TODO: test on live Devuan system — confirm tailscale up completes successfully
    tailscale up
}

main() {
    banner "WB's Systemdless Server — Phase 4: Install Tailscale"

    log_warn "Tailscale will be installed and managed by OpenRC."
    log_warn "Internet access is required to authenticate with Tailscale's control plane."
    log_warn "See docs/tailscale-on-openrc.md for non-systemd notes."
    confirm "Install Tailscale?"

    run_preflight_checks
    check_openrc_active
    add_tailscale_repo
    install_tailscale
    deploy_openrc_service
    start_tailscaled
    run_tailscale_up

    log_success "Tailscale installed and connected."
    log_info "Check status: tailscale status"
    log_info "Next: scripts/07-install-smartmon.sh"
}

main "$@"
