#!/usr/bin/env bash
# =============================================================================
# scripts/99-full-install.sh
# Purpose:  Orchestrator — runs all install phases in sequence.
#           Calls scripts 00 through 10 in order with a confirmation gate
#           before each phase.
#           Use this for a fresh full install. For individual phases, run
#           the numbered scripts directly.
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

# Ordered list of install scripts to run
readonly PHASES=(
    "00-base-validate.sh"
    "01-install-openrc.sh"
    "02-install-docker.sh"
    "03-install-samba.sh"
    "04-install-mergerfs.sh"
    "05-install-snapraid.sh"
    "06-install-tailscale.sh"
    "07-install-smartmon.sh"
    "08-install-monitoring.sh"
    "09-install-webui.sh"
    "10-harden.sh"
)

# Log file for the full install run
readonly INSTALL_LOG="/var/log/wbs-install-$(date '+%Y%m%d-%H%M%S').log"

run_phase() {
    local script="${SCRIPT_DIR}/${1}"
    local phase_name="${1}"

    log_step "Phase: ${phase_name}"

    if [[ ! -f "${script}" ]]; then
        log_error "Script not found: ${script}"
        exit 1
    fi

    confirm "Run phase: ${phase_name}?"

    log_info "Starting ${phase_name}..."
    if bash "${script}" 2>&1 | tee -a "${INSTALL_LOG}"; then
        log_success "Phase complete: ${phase_name}"
    else
        log_error "Phase FAILED: ${phase_name}"
        log_error "Check log: ${INSTALL_LOG}"
        log_error "Fix the issue and re-run this phase individually, then re-run 99-full-install.sh"
        exit 1
    fi
}

print_phase_list() {
    log_info "Full install will run the following phases:"
    for i in "${!PHASES[@]}"; do
        log_info "  Phase $((i+1))/${#PHASES[@]}: ${PHASES[$i]}"
    done
    echo ""
    log_warn "Each phase will require a separate confirmation."
    log_warn "Note: Phase 2 (install-openrc) requires a REBOOT before subsequent phases."
    log_warn "The full install is NOT automatic — stop after Phase 2, reboot, then continue."
}

main() {
    banner "WB's Systemdless Server — Full Install Orchestrator"

    log_info "Install log: ${INSTALL_LOG}"
    touch "${INSTALL_LOG}"

    print_phase_list

    confirm "Begin full install? (Phases run one at a time with individual confirmations)"

    run_preflight_checks

    for phase in "${PHASES[@]}"; do
        run_phase "${phase}"
        echo ""
    done

    log_success "All phases complete."
    log_info "Install log saved to: ${INSTALL_LOG}"
    log_info ""
    log_info "Post-install checklist:"
    log_info "  1. Reboot and verify: rc-status --all"
    log_info "  2. Verify Docker: docker ps"
    log_info "  3. Verify Samba: smbstatus"
    log_info "  4. Verify mergerfs: mount | grep fuse"
    log_info "  5. Verify SnapRAID: snapraid status"
    log_info "  6. Verify Tailscale: tailscale status"
    log_info "  7. Verify Netdata: curl -s http://127.0.0.1:19999 | head"
    log_info "  8. Verify web UI: curl -s http://127.0.0.1:8080"
    log_info ""
    log_info "See docs/install-guide.md for the full post-install checklist."
}

main "$@"
