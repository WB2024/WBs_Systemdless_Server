#!/usr/bin/env bash
# =============================================================================
# scripts/04-install-mergerfs.sh
# Purpose:  Phase 3 — Install mergerfs and configure the storage pool.
#           mergerfs unions multiple ext4 data drives into /srv/pool.
#           SnapRAID provides parity — run 05-install-snapraid.sh after this.
# Phase:    3 — NAS Stack (Storage Pool)
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly FSTAB_TEMPLATE="${REPO_ROOT}/config/mergerfs/fstab-entry.template"
readonly POOL_MOUNT="/srv/pool"
readonly SHARE_ROOT="/srv/shares"

install_mergerfs() {
    log_step "Installing mergerfs"
    check_apt_cache
    pkg_install mergerfs
    log_success "mergerfs installed."
}

verify_data_drives() {
    log_step "Checking for data drives"
    log_info "Current block devices:"
    lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v '^loop' || true

    log_warn "This script does NOT format or partition any drives."
    log_warn "Data drives must already be:"
    log_warn "  1. Formatted as ext4"
    log_warn "  2. Assigned stable labels or UUIDs in /etc/fstab"
    log_warn "  3. Mounted individually under /mnt/disk1, /mnt/disk2, etc."
    log_warn "See docs/storage-layout.md for the recommended layout."
}

prepare_mount_points() {
    log_step "Creating pool and share mount points"
    mkdir -p "${POOL_MOUNT}"
    mkdir -p "${SHARE_ROOT}"
    log_success "Created ${POOL_MOUNT} and ${SHARE_ROOT}"
}

configure_fstab() {
    log_step "Configuring /etc/fstab"
    log_info "Template: ${FSTAB_TEMPLATE}"

    if [[ ! -f "${FSTAB_TEMPLATE}" ]]; then
        log_error "fstab template not found: ${FSTAB_TEMPLATE}"
        exit 1
    fi

    log_warn "The mergerfs fstab entry requires manual configuration."
    log_warn "Open config/mergerfs/fstab-entry.template and adapt it to your drive layout."
    log_warn "Then append the entry to /etc/fstab."
    log_info ""
    log_info "Template contents:"
    echo "--- template start ---"
    cat "${FSTAB_TEMPLATE}"
    echo "--- template end ---"

    confirm "View instructions confirmed. Add fstab entry to /etc/fstab now?"

    log_warn "Appending mergerfs entry to /etc/fstab — review the file after."
    echo "" >> /etc/fstab
    echo "# WB's Systemdless Server — mergerfs pool (added $(date '+%Y-%m-%d'))" >> /etc/fstab
    echo "# TODO: Replace /mnt/disk* paths with your actual data drive mount points" >> /etc/fstab
    cat "${FSTAB_TEMPLATE}" >> /etc/fstab
    log_warn "Entry appended. EDIT /etc/fstab now to set correct disk paths."
}

test_mergerfs_mount() {
    log_step "Testing mergerfs mount"
    log_info "Attempting: mount ${POOL_MOUNT}"
    if mount "${POOL_MOUNT}" 2>/dev/null; then
        log_success "mergerfs pool mounted at ${POOL_MOUNT}"
    else
        log_warn "Mount failed — likely because disk paths in /etc/fstab are still placeholders."
        log_warn "Edit /etc/fstab, then run: mount ${POOL_MOUNT}"
    fi
}

main() {
    banner "WB's Systemdless Server — Phase 3: Install mergerfs"

    log_warn "This script DOES NOT touch any data drives."
    log_warn "Data drive setup (format, label, fstab) must be done manually first."
    log_warn "See docs/storage-layout.md before running this script."
    confirm "Install mergerfs and configure /etc/fstab?"

    run_preflight_checks
    check_openrc_active
    verify_data_drives
    install_mergerfs
    prepare_mount_points
    configure_fstab
    test_mergerfs_mount

    log_success "mergerfs setup complete (verify /etc/fstab before reboot)."
    log_info "Next: scripts/05-install-snapraid.sh"
}

main "$@"
