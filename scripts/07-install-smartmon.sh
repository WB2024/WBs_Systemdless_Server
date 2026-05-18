#!/usr/bin/env bash
# =============================================================================
# scripts/07-install-smartmon.sh
# Purpose:  Phase 4 — Install smartmontools for drive health monitoring.
#           Schedules SMART tests and email alerts via cron + rsyslog.
#           No smartd daemon dependency on systemd.
# Phase:    4 — Monitoring (Drive Health)
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

readonly SMARTD_CONF="/etc/smartd.conf"
readonly CRON_FILE="/etc/cron.weekly/smart-test"

install_smartmontools() {
    log_step "Installing smartmontools"
    check_apt_cache
    pkg_install smartmontools
    log_success "smartmontools installed."
}

configure_smartd() {
    log_step "Configuring smartd"
    log_info "Writing ${SMARTD_CONF}"

    # Back up existing config
    [[ -f "${SMARTD_CONF}" ]] && cp "${SMARTD_CONF}" "${SMARTD_CONF}.bak.$(date +%Y%m%d%H%M%S)"

    cat > "${SMARTD_CONF}" <<'EOF'
# smartd.conf — WB's Systemdless Server
# Monitor all SMART-capable drives.
# -a        : all SMART checks
# -o on     : enable automatic offline testing
# -S on     : enable attribute autosave
# -n standby,q : don't spin up sleeping drives
# -W 4,40,50 : temperature warning thresholds (delta, info, crit)
# -l error  : log SMART errors
# -l selftest: log self-test failures

DEVICESCAN -a -o on -S on -n standby,q -W 4,40,50 -l error -l selftest -m root
EOF

    log_success "smartd configured."
}

enable_smartd() {
    log_step "Enabling smartd via OpenRC"
    # smartmontools ships an init script for Debian/Devuan
    if [[ -f /etc/init.d/smartmontools ]]; then
        openrc_enable smartmontools default
        log_success "smartmontools (smartd) enabled."
    else
        log_warn "/etc/init.d/smartmontools not found after install."
        log_warn "Enable it manually: rc-update add smartmontools default"
    fi
}

setup_weekly_test() {
    log_step "Scheduling weekly long SMART self-test via cron"

    cat > "${CRON_FILE}" <<'EOF'
#!/usr/bin/env bash
# Weekly SMART long test — WB's Systemdless Server
# Logs results to /var/log/smart-test.log
set -euo pipefail

LOGFILE="/var/log/smart-test.log"
DATE="$(date '+%Y-%m-%d %H:%M:%S')"

{
    echo "===== SMART weekly test: ${DATE} ====="
    for dev in $(lsblk -dn -o NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}'); do
        echo "--- Drive: ${dev} ---"
        smartctl -t long "${dev}" || true
        smartctl -H "${dev}" || true
        smartctl -A "${dev}" | grep -E 'Raw_Read|Reallocated|Spin_Retry|Offline_Uncorrectable|Current_Pending' || true
    done
    echo "===== Test queued ====="
} >> "${LOGFILE}" 2>&1
EOF

    chmod +x "${CRON_FILE}"
    log_success "Weekly SMART test cron installed: ${CRON_FILE}"
    log_info "Results logged to /var/log/smart-test.log"
}

main() {
    banner "WB's Systemdless Server — Phase 4: Install SMART Monitoring"

    run_preflight_checks
    check_openrc_active
    install_smartmontools
    configure_smartd
    enable_smartd
    setup_weekly_test

    log_success "SMART monitoring configured."
    log_info "Check drive health now: smartctl -H /dev/sda"
    log_info "View smartd status:     rc-service smartmontools status"
    log_info "Next: scripts/08-install-monitoring.sh"
}

main "$@"
