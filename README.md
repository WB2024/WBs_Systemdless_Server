# WB's Systemdless Server

A from-scratch, non-systemd NAS/server OS project — building an OpenMediaVault-like experience on a clean Devuan + OpenRC base, without systemd.

## What is this?

This repo is the home of a custom headless Linux server distribution aimed at replacing OpenMediaVault 7 on low-power Haswell-era desktop hardware. The goal is a stable, appliance-style NAS/server OS that:

- Has **no systemd** anywhere in the stack
- Uses **Devuan Daedalus** (Debian 12 compatible) as the base
- Runs **OpenRC** as the init and service manager
- Supports Docker, Samba, mergerfs, SnapRAID, and Tailscale
- Provides a lightweight web management interface (Cockpit or custom)
- Keeps a small package footprint and low idle resource usage

## Current Status

> **Pre-development.** Repository structure and knowledge base are being established. Active development has not yet begun.

## What's coming

- Base OS install automation and configuration scripts
- OpenRC service definitions for the full NAS stack
- Docker integration without systemd dependencies
- Samba / NFS share management
- Storage pooling with mergerfs + SnapRAID
- Web UI layer (TBD — Cockpit or custom Flask/FastAPI)
- Netdata monitoring integration
- Tailscale remote access setup
- Documentation and reproducible install guide

## Target Hardware

Lenovo ThinkCentre M73 class machines (4th gen Intel Core, 8 GB RAM, Intel NIC, integrated iGPU). Designed to run efficiently on modest, low-power hardware.

---

*This README will be expanded significantly as development progresses.*
