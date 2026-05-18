#!/usr/bin/env bash
# =============================================================================
# scripts/05-install-snapraid.sh
# Purpose:  Phase 3 — Install SnapRAID and deploy scheduled sync via OpenRC.
#           SnapRAID provides parity protection for the mergerfs pool.
#           Run AFTER 04-install-mergerfs.sh and once data drives are mounted.
# Phase:    3 — NAS Stack (Parity)
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SNAPRAID_CONF_TEMPLATE="${REPO_ROOT}/config/snapraid/snapraid.conf.template"
readonly SNAPRAID_CONF="/etc/snapraid.conf"
readonly CRON_FILE="/etc/cron.daily/snapraid-sync"

install_snapraid() {
    log_step "Installing SnapRAID"
    check_apt_cache
    # SnapRAID is available in Debian/Devuan repos from Bookworm onwards
    pkg_install snapraid
    log_success "SnapRAID installed: $(snapraid --version | head -1)"
}

configure_snapraid() {
    log_step "Configuring SnapRAID"

    if [[ ! -f "${SNAPRAID_CONF_TEMPLATE}" ]]; then
        log_error "Template not found: ${SNAPRAID_CONF_TEMPLATE}"
        exit 1
    fi

    if [[ -f "${SNAPRAID_CONF}" ]]; then
        cp "${SNAPRAID_CONF}" "${SNAPRAID_CONF}.bak.$(date +%Y%m%d%H%M%S)"
        log_info "Backed up existing ${SNAPRAID_CONF}"
    fi

    log_warn "The SnapRAID config requires parity and content file paths that"
    log_warn "depend on YOUR drive layout. Edit the config before running 'snapraid sync'."

    confirm "Deploy SnapRAID config template to ${SNAPRAID_CONF}?"

    cp "${SNAPRAID_CONF_TEMPLATE}" "${SNAPRAID_CONF}"
    log_warn "Deployed template. EDIT ${SNAPRAID_CONF} — set parity and data drive paths."
}

setup_sync_cron() {
    log_step "Scheduling SnapRAID sync via cron"
    log_info "Installing daily sync wrapper: ${CRON_FILE}"

    cat > "${CRON_FILE}" <<'EOF'
#!/usr/bin/env bash
# SnapRAID daily sync — installed by WB's Systemdless Server
# Runs: sync, then scrub 10% of data blocks
set -euo pipefail

LOGFILE="/var/log/snapraid-sync.log"

{
    echo "===== SnapRAID sync: $(date '+%Y-%m-%d %H:%M:%S') ====="
    snapraid sync
    snapraid scrub -p 10 -o 8
    echo "===== Sync complete ====="
} >> "${LOGFILE}" 2>&1
EOF

    chmod +x "${CRON_FILE}"
    log_success "Daily sync cron installed: ${CRON_FILE}"
    log_info "Logs will be written to /var/log/snapraid-sync.log"
}

deploy_openrc_sync_service() {
    log_step "Deploying snapraid-sync OpenRC service"
    # snapraid-sync OpenRC service is a manual trigger wrapper, not boot-time
    deploy_openrc_script "snapraid-sync"
    log_info "snapraid-sync service deployed (NOT added to boot — run manually or via cron)"
}

main() {
    banner "WB's Systemdless Server — Phase 3: Install SnapRAID"

    log_warn "SnapRAID parity files will be written to your designated parity drive."
    log_warn "Ensure parity and data drives are mounted before running 'snapraid sync'."
    log_warn "See docs/storage-layout.md for drive layout requirements."
    confirm "Install SnapRAID and configure daily sync?"

    run_preflight_checks
    check_openrc_active
    install_snapraid
    configure_snapraid
    setup_sync_cron
    deploy_openrc_sync_service

    log_success "SnapRAID setup complete."
    log_warn "NEXT: Edit ${SNAPRAID_CONF} with your parity/data drive paths."
    log_warn "THEN: Run 'snapraid sync' to build the initial parity file."
    log_info "Next: scripts/06-install-tailscale.sh"
}

main "$@"
