#!/usr/bin/env bash
# =============================================================================
# scripts/00-base-validate.sh
# Purpose:  Phase 1 — Validate the base Devuan install before any changes.
#           Checks: network, SSH, partition layout, OS version, no systemd.
# Phase:    1 — Base OS Validation
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

# Expected network interface name on ThinkCentre M73 (Intel I217-V, e1000e)
readonly EXPECTED_NIC="eno1"

# Minimum free space required on / before install begins (MB)
readonly MIN_ROOT_FREE_MB=2048

validate_partitions() {
    log_step "Checking partition layout"
    log_info "Current mounts:"
    mount | grep -E '^/dev' | awk '{print $1, $3, $5}' || true

    log_info "Disk usage:"
    df -h | grep -E '^/dev|Filesystem' || true

    # Warn if /srv is not a separate mount point
    if ! mount | grep -q ' /srv '; then
        log_warn "/srv is not a separate mount point."
        log_warn "Recommended: mount data storage separately at /srv."
        log_warn "See docs/storage-layout.md for the recommended partition scheme."
    else
        log_success "/srv is a separate mount point."
    fi
}

validate_network() {
    log_step "Checking network"
    require_network_up "${EXPECTED_NIC}"

    log_info "Checking internet connectivity (apt.devuan.org)..."
    if ping -c 1 -W 5 apt.devuan.org &>/dev/null; then
        log_success "Internet connectivity: OK"
    else
        log_warn "Cannot reach apt.devuan.org. Check DNS and routing."
        log_warn "Install will likely fail without internet access."
    fi
}

validate_ssh() {
    log_step "Checking SSH"
    require_ssh_running
}

validate_sources_list() {
    log_step "Checking apt sources"
    if grep -q 'daedalus' /etc/apt/sources.list 2>/dev/null; then
        log_success "sources.list references Devuan Daedalus."
    else
        log_warn "sources.list does not reference 'daedalus' by codename."
        log_warn "Ensure /etc/apt/sources.list uses the release codename, not 'stable'."
        log_warn "See: docs/install-guide.md"
    fi
}

print_system_summary() {
    log_step "System summary"
    log_info "Hostname:     $(hostname)"
    log_info "Kernel:       $(uname -r)"
    log_info "Devuan:       $(cat /etc/devuan_version 2>/dev/null || echo 'unknown')"
    log_info "Init (PID 1): $(cat /proc/1/comm 2>/dev/null || echo 'unknown')"
    log_info "CPU:          $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | xargs)"
    log_info "RAM:          $(free -h | awk '/^Mem:/{print $2}') total"
    log_info "Architecture: $(uname -m)"
}

main() {
    banner "WB's Systemdless Server — Phase 1: Base Validation"
    run_preflight_checks
    require_disk_space "/" "${MIN_ROOT_FREE_MB}"
    validate_partitions
    validate_network
    validate_ssh
    validate_sources_list
    print_system_summary
    log_success "Phase 1 validation complete. System is ready for install."
    log_info "Next step: run scripts/01-install-openrc.sh"
}

main "$@"
