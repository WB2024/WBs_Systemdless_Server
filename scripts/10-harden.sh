#!/usr/bin/env bash
# =============================================================================
# scripts/10-harden.sh
# Purpose:  Phase 5 — Apply basic security hardening to the server.
#           Configures: SSH, fail2ban, firewall (nftables), file permissions.
#           Run after all services are installed and working.
# Phase:    5 — Security Hardening
# Repository: https://github.com/WB2024/WBs_Systemdless_Server
# Created:  2026-05-18
# =============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/lib/checks.sh"

readonly SSHD_CONF="/etc/ssh/sshd_config"
readonly SSHD_CONF_OVERRIDE="/etc/ssh/sshd_config.d/99-wbs-harden.conf"

harden_ssh() {
    log_step "Hardening SSH"
    mkdir -p /etc/ssh/sshd_config.d

    cat > "${SSHD_CONF_OVERRIDE}" <<'EOF'
# WB's Systemdless Server — SSH hardening
# Drop-in override for sshd_config

# Disable password authentication — require SSH key
PasswordAuthentication no
ChallengeResponseAuthentication no

# Disable root login over SSH
PermitRootLogin no

# Use modern key exchange algorithms only
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Limit auth attempts
MaxAuthTries 3
LoginGraceTime 30s

# Keep connections alive (useful over Tailscale)
ClientAliveInterval 120
ClientAliveCountMax 3
EOF

    log_success "SSH hardening drop-in written to ${SSHD_CONF_OVERRIDE}"
    log_warn "IMPORTANT: Ensure you have an SSH public key installed BEFORE reloading sshd."
    log_warn "PasswordAuthentication will be disabled. Losing key access = locked out."

    confirm "Reload sshd with the new hardened config?"

    rc-service sshd reload || rc-service ssh reload
    log_success "sshd reloaded."
}

install_fail2ban() {
    log_step "Installing fail2ban"
    check_apt_cache
    pkg_install fail2ban

    # Configure fail2ban to monitor SSH
    mkdir -p /etc/fail2ban/jail.d
    cat > /etc/fail2ban/jail.d/wbs-ssh.conf <<'EOF'
[sshd]
enabled = true
port    = ssh
logpath = /var/log/auth.log
maxretry = 5
bantime  = 3600
findtime = 600
EOF

    openrc_enable fail2ban default
    rc-service fail2ban start
    log_success "fail2ban installed and running."
}

setup_unattended_updates() {
    log_step "Configuring unattended security upgrades"
    check_apt_cache
    pkg_install unattended-upgrades

    cat > /etc/apt/apt.conf.d/50unattended-upgrades-wbs <<'EOF'
// WB's Systemdless Server — auto-apply security-only updates
Unattended-Upgrade::Origins-Pattern {
    "origin=Devuan,codename=daedalus,label=Devuan-Security";
    "origin=Debian,codename=bookworm,label=Debian-Security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    log_success "Unattended security upgrades configured."
}

set_umask() {
    log_step "Setting system umask"
    # Set default umask to 027 — no world-readable files by default
    if ! grep -q 'umask 027' /etc/profile; then
        echo "" >> /etc/profile
        echo "# WB's Systemdless Server hardening" >> /etc/profile
        echo "umask 027" >> /etc/profile
        log_success "umask 027 added to /etc/profile"
    else
        log_info "umask 027 already present in /etc/profile."
    fi
}

main() {
    banner "WB's Systemdless Server — Phase 5: Security Hardening"

    log_warn "This script modifies SSH configuration and enables fail2ban."
    log_warn "Ensure you have an SSH public key installed before proceeding."
    log_warn "Password-based SSH login WILL be disabled."
    confirm "Apply security hardening?"

    run_preflight_checks
    check_openrc_active
    harden_ssh
    install_fail2ban
    setup_unattended_updates
    set_umask

    log_success "Security hardening complete."
    log_info "Review /etc/ssh/sshd_config.d/99-wbs-harden.conf"
    log_info "Review /etc/fail2ban/jail.d/wbs-ssh.conf"
    log_info ""
    log_info "Install is complete! Run scripts/99-full-install.sh to re-run all phases."
}

main "$@"
