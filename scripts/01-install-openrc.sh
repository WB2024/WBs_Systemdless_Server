#!/usr/bin/env bash
# =============================================================================
# scripts/01-install-openrc.sh
# Purpose:  Phase 2 — Install OpenRC and migrate base services from SysVinit.
#           After this script completes, OpenRC is the active service manager.
# Phase:    2 — Init Migration
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

install_openrc() {
    log_step "Installing OpenRC"
    check_apt_cache
    pkg_install openrc

    # elogind is sometimes pulled in as a logind replacement.
    # We do NOT want it — it brings in dbus dependencies we don't need
    # for a headless NAS. Remove it if it was installed.
    if dpkg -l elogind 2>/dev/null | grep -q '^ii'; then
        log_warn "elogind was installed as a dependency. Removing..."
        apt-get remove -y elogind || true
    fi

    log_success "OpenRC installed."
}

migrate_core_services() {
    log_step "Migrating core services to OpenRC"

    # SSH daemon
    if [[ -f /etc/init.d/ssh ]]; then
        openrc_enable ssh default
        log_success "ssh enabled in OpenRC default runlevel."
    else
        log_warn "/etc/init.d/ssh not found. Install openssh-server first."
    fi

    # Networking
    if [[ -f /etc/init.d/networking ]]; then
        openrc_enable networking boot
        log_success "networking enabled in OpenRC boot runlevel."
    fi

    # Cron
    if [[ -f /etc/init.d/cron ]]; then
        openrc_enable cron default
        log_success "cron enabled in OpenRC default runlevel."
    fi

    # rsyslog (flat-file logging — no journald)
    if [[ -f /etc/init.d/rsyslog ]]; then
        openrc_enable rsyslog default
        log_success "rsyslog enabled in OpenRC default runlevel."
    else
        log_warn "rsyslog not found. Installing..."
        pkg_install rsyslog
        openrc_enable rsyslog default
    fi
}

configure_openrc() {
    log_step "Configuring OpenRC"

    # Parallel startup — safe on Devuan, speeds up boot
    sed -i 's/^#rc_parallel=.*/rc_parallel="YES"/' /etc/rc.conf || true

    log_info "OpenRC config written."
    log_info "Review /etc/rc.conf for further tuning."
}

main() {
    banner "WB's Systemdless Server — Phase 2: Install OpenRC"

    log_warn "This script will install OpenRC and make it the active init manager."
    log_warn "A reboot is required after this step to complete the migration."
    confirm "Install OpenRC and migrate base services?"

    run_preflight_checks
    install_openrc
    migrate_core_services
    configure_openrc

    log_success "Phase 2 complete. OpenRC is installed and base services are configured."
    log_warn "REBOOT REQUIRED before proceeding to Phase 3."
    log_info "After reboot, verify with: rc-status"
    log_info "Then run: scripts/02-install-docker.sh"
}

main "$@"
