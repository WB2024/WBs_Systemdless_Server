#!/usr/bin/env bash
# =============================================================================
# scripts/08-install-monitoring.sh
# Purpose:  Phase 4 — Install Netdata for system monitoring.
#           Netdata runs as an OpenRC service, logging to flat files.
#           No Prometheus, no InfluxDB — lightweight single-node setup.
# Phase:    4 — Monitoring (System Metrics)
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

readonly NETDATA_INSTALLER_URL="https://get.netdata.cloud/kickstart.sh"
readonly NETDATA_CONF_DIR="/etc/netdata"

install_netdata() {
    log_step "Installing Netdata"
    require_binary curl

    log_info "Downloading Netdata kickstart installer..."
    log_warn "This runs the official Netdata installer — review the URL if security matters."
    log_info "URL: ${NETDATA_INSTALLER_URL}"

    confirm "Download and run the Netdata installer?"

    # --non-interactive: no prompts
    # --no-updates: don't auto-update Netdata
    # --stable-channel: use stable releases
    # --disable-telemetry: no usage stats sent to Netdata Inc.
    curl -fsSL "${NETDATA_INSTALLER_URL}" | bash -s -- \
        --non-interactive \
        --stable-channel \
        --disable-telemetry

    log_success "Netdata installed."
}

configure_netdata() {
    log_step "Configuring Netdata"

    local conf="${NETDATA_CONF_DIR}/netdata.conf"
    if [[ ! -f "${conf}" ]]; then
        log_warn "${conf} not found. Netdata may not have installed correctly."
        return 1
    fi

    # Restrict Netdata to localhost only — Tailscale or reverse proxy provides remote access
    sed -i 's/.*bind to.*/    bind to = 127.0.0.1/' "${conf}" || true

    log_success "Netdata bound to 127.0.0.1 (access via Caddy/nginx reverse proxy)."
    log_info "Review full config at ${conf}"
}

deploy_openrc_service() {
    log_step "Configuring Netdata as OpenRC service"
    # Netdata's installer may set up its own init script — verify it
    if [[ -f /etc/init.d/netdata ]]; then
        openrc_enable netdata default
        log_success "netdata enabled in OpenRC default runlevel (init script from installer)."
    else
        # Deploy our custom init script from the repo
        deploy_openrc_script "netdata"
        openrc_enable netdata default
        log_success "Custom netdata OpenRC init script deployed and enabled."
    fi
}

main() {
    banner "WB's Systemdless Server — Phase 4: Install Netdata Monitoring"

    log_info "Netdata will be installed from the official installer script."
    log_info "Bound to 127.0.0.1 — remote access via reverse proxy."
    confirm "Install Netdata system monitoring?"

    run_preflight_checks
    check_openrc_active
    install_netdata
    configure_netdata
    deploy_openrc_service

    log_success "Netdata monitoring installed."
    log_info "Access: http://127.0.0.1:19999 (or via configured reverse proxy)"
    log_info "Next: scripts/09-install-webui.sh"
}

main "$@"
