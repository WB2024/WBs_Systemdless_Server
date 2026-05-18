#!/usr/bin/env bash
# =============================================================================
# scripts/03-install-samba.sh
# Purpose:  Phase 3 — Install Samba for network file sharing without logind.
#           Samba on Devuan works without logind; some Samba features that
#           require session tracking via logind will not be available.
# Phase:    3 — NAS Stack (File Sharing)
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

# Where shares will be served from (must be set up via 04-install-mergerfs.sh first)
readonly SHARE_ROOT="/srv/shares"

# Config template location in this repo
readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SMBD_CONF_TEMPLATE="${REPO_ROOT}/config/samba/smb.conf.template"
readonly SMBD_CONF="/etc/samba/smb.conf"

install_samba() {
    log_step "Installing Samba"
    check_apt_cache
    # samba-common-bin for testparm, smbpasswd etc.
    # winbind is NOT installed — it is a logind / PAM pain point
    pkg_install samba samba-common-bin
    log_success "Samba installed."
}

configure_samba() {
    log_step "Configuring Samba"

    if [[ ! -f "${SMBD_CONF_TEMPLATE}" ]]; then
        log_error "Template not found: ${SMBD_CONF_TEMPLATE}"
        log_error "Cannot configure Samba without the template."
        exit 1
    fi

    # Back up any existing config
    if [[ -f "${SMBD_CONF}" ]]; then
        cp "${SMBD_CONF}" "${SMBD_CONF}.bak.$(date +%Y%m%d%H%M%S)"
        log_info "Backed up existing ${SMBD_CONF}"
    fi

    log_warn "The template uses {{PLACEHOLDER}} tokens."
    log_warn "You must edit ${SMBD_CONF} after deployment to set real values."
    log_warn "See config/samba/smb.conf.template for all required settings."

    confirm "Deploy Samba config from template to ${SMBD_CONF}?"

    cp "${SMBD_CONF_TEMPLATE}" "${SMBD_CONF}"
    log_success "Samba config deployed. EDIT ${SMBD_CONF} before starting smbd."
}

create_share_root() {
    log_step "Preparing share root: ${SHARE_ROOT}"
    if [[ ! -d "${SHARE_ROOT}" ]]; then
        log_warn "${SHARE_ROOT} does not exist."
        log_warn "Run 04-install-mergerfs.sh first to set up the storage pool."
        log_warn "Skipping share root creation."
    else
        log_success "${SHARE_ROOT} exists."
    fi
}

enable_samba_services() {
    log_step "Enabling Samba services via OpenRC"
    openrc_enable smbd default
    openrc_enable nmbd default
    log_success "smbd and nmbd enabled."
}

main() {
    banner "WB's Systemdless Server — Phase 3: Install Samba"

    log_warn "Samba shares sensitive data. Review docs/samba-without-logind.md"
    log_warn "for known limitations when running without logind."
    confirm "Install and configure Samba?"

    run_preflight_checks
    check_openrc_active
    install_samba
    create_share_root
    configure_samba
    enable_samba_services

    log_success "Samba install complete."
    log_warn "Set Samba passwords with: smbpasswd -a <username>"
    log_warn "Validate config with: testparm"
    log_info "Next: scripts/04-install-mergerfs.sh"
}

main "$@"
