#!/usr/bin/env bash
# =============================================================================
# scripts/09-install-webui.sh
# Purpose:  Phase 5 — Install the web UI for server management.
#           Two options exist — see TODO comment below.
#           Default: custom FastAPI app (webui/custom/).
#           Alternative: Cockpit (webui/cockpit/).
# Phase:    5 — Web UI
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

# TODO: DECISION REQUIRED — see Knowledge.md §17 Q1
# Web UI approach: Cockpit vs custom FastAPI
# Set WEBUI_MODE to 'fastapi' or 'cockpit' before running this script.
readonly WEBUI_MODE="${WEBUI_MODE:-fastapi}"

readonly REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly WEBUI_DIR="${REPO_ROOT}/webui/custom"
readonly INSTALL_DIR="/opt/wbs-webui"
readonly VENV_DIR="${INSTALL_DIR}/venv"
readonly ENV_FILE="${INSTALL_DIR}/.env"

install_fastapi_ui() {
    log_step "Installing custom FastAPI web UI"

    require_binary python3
    require_binary pip3

    log_info "Installing Python venv support..."
    pkg_install python3-venv python3-pip

    log_info "Creating install directory: ${INSTALL_DIR}"
    mkdir -p "${INSTALL_DIR}"

    log_info "Copying application files..."
    cp -r "${WEBUI_DIR}/." "${INSTALL_DIR}/"

    log_info "Creating Python virtual environment: ${VENV_DIR}"
    python3 -m venv "${VENV_DIR}"

    log_info "Installing Python dependencies (pinned versions)..."
    "${VENV_DIR}/bin/pip" install --upgrade pip
    "${VENV_DIR}/bin/pip" install -r "${INSTALL_DIR}/requirements.txt"

    log_info "Setting up .env file from .env.example..."
    if [[ ! -f "${ENV_FILE}" ]]; then
        cp "${INSTALL_DIR}/.env.example" "${ENV_FILE}"
        log_warn ".env created from example. Edit ${ENV_FILE} with real values before starting."
    else
        log_info ".env already exists — not overwriting."
    fi

    log_success "FastAPI web UI installed to ${INSTALL_DIR}"
}

install_cockpit() {
    log_step "Installing Cockpit web UI"
    log_warn "Cockpit may have logind/systemd dependencies on some builds."
    log_warn "See webui/cockpit/README.md and docs/open-questions.md."

    check_apt_cache
    pkg_install cockpit

    if [[ -f /etc/init.d/cockpit ]]; then
        openrc_enable cockpit default
    else
        log_warn "No OpenRC init script for cockpit found — manual configuration required."
    fi

    log_success "Cockpit installed."
    log_info "Access: https://<server-ip>:9090"
}

configure_reverse_proxy_stub() {
    log_step "Reverse proxy note"
    log_info "The web UI should be served via a reverse proxy."
    log_info "Caddy template: config/caddy/Caddyfile.template"
    log_info "nginx template: config/nginx/nginx.conf.template"
    log_info "Install and configure a reverse proxy separately."
    log_info "Run: scripts/10-harden.sh after the web UI is working."
}

deploy_openrc_webui_service() {
    log_step "Deploying web UI OpenRC service"
    local init_script="/etc/init.d/wbs-webui"
    cat > "${init_script}" <<EOF
#!/sbin/openrc-run
# OpenRC init script for WB's Systemdless Server FastAPI web UI
description="WB's Systemdless Server Web UI"

command="${VENV_DIR}/bin/uvicorn"
command_args="app.main:app --host 127.0.0.1 --port 8080 --workers 1"
command_user="www-data"
directory="${INSTALL_DIR}"
pidfile="/run/wbs-webui.pid"
command_background="yes"
stdout_log="/var/log/wbs-webui.log"
stderr_log="/var/log/wbs-webui.log"

depend() {
    need net
    after net
}
EOF
    chmod +x "${init_script}"
    openrc_enable wbs-webui default
    log_success "wbs-webui OpenRC service deployed and enabled."
}

main() {
    banner "WB's Systemdless Server — Phase 5: Install Web UI"

    log_info "Web UI mode: ${WEBUI_MODE}"
    log_warn "Set WEBUI_MODE=cockpit to install Cockpit instead of FastAPI."

    confirm "Install web UI (mode: ${WEBUI_MODE})?"

    run_preflight_checks
    check_openrc_active

    case "${WEBUI_MODE}" in
        fastapi)
            install_fastapi_ui
            deploy_openrc_webui_service
            ;;
        cockpit)
            install_cockpit
            ;;
        *)
            log_error "Unknown WEBUI_MODE: '${WEBUI_MODE}'. Use 'fastapi' or 'cockpit'."
            exit 1
            ;;
    esac

    configure_reverse_proxy_stub

    log_success "Phase 5 (Web UI) complete."
    log_info "Next: scripts/10-harden.sh"
}

main "$@"
