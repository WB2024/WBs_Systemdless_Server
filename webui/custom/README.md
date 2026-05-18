# Custom FastAPI Web UI

**Repository:** https://github.com/WB2024/WBs_Systemdless_Server

> **Status:** Skeleton — basic structure scaffolded. Expand with real routes
> and templates as features are defined.

A lightweight FastAPI web application for managing WB's Systemdless Server.
No systemd, no logind, no heavy framework.

---

## Structure

```
webui/custom/
├── README.md           ← this file
├── requirements.txt    ← pinned Python dependencies
├── .env.example        ← environment variable template
└── app/
    ├── __init__.py     ← package marker
    ├── main.py         ← FastAPI app entrypoint, mounts routes
    ├── routes/
    │   └── __init__.py ← route registrations
    └── templates/
        └── index.html  ← Jinja2 HTML template (base UI)
```

---

## Development Setup

```bash
# Clone the repo (if not already done)
git clone https://github.com/WB2024/WBs_Systemdless_Server.git
cd WBs_Systemdless_Server/webui/custom

# Create a virtual environment (never use global pip)
python3 -m venv venv
source venv/bin/activate

# Install dependencies (pinned versions)
pip install -r requirements.txt

# Copy .env.example to .env and fill in values
cp .env.example .env
$EDITOR .env

# Run the dev server
uvicorn app.main:app --reload --host 127.0.0.1 --port 8080
```

Access at: http://127.0.0.1:8080

---

## Production Deployment

The install script (`scripts/09-install-webui.sh`) deploys the app to
`/opt/wbs-webui/` and manages it via an OpenRC service (`/etc/init.d/wbs-webui`).

```bash
# Start the web UI
rc-service wbs-webui start

# Check status
rc-service wbs-webui status

# View logs
tail -f /var/log/wbs-webui.log
```

The app runs on `127.0.0.1:8080`. Expose it externally via Caddy or nginx.
See `config/caddy/Caddyfile.template` or `config/nginx/nginx.conf.template`.

---

## Adding Routes

1. Create a new file in `app/routes/` (e.g., `app/routes/storage.py`)
2. Define an `APIRouter`
3. Register the router in `app/routes/__init__.py`
4. Register the router in `app/main.py`

---

## Dependency Notes

All dependencies are pinned in `requirements.txt`.  
**Do not install packages globally.** Always use the project's venv.  
**Do not commit `venv/`** — it is gitignored and recreated by the install script.  
**Do commit `requirements.txt`** — this is the source of truth for the environment.

---

## TODO

<!-- TODO: DECISION REQUIRED — see Knowledge.md §17 Q1 -->
> **This UI is the default but the decision between Cockpit and FastAPI is
> still open.** If Cockpit is chosen, this directory becomes unused.
> See `docs/open-questions.md Q1` and `webui/cockpit/README.md`.
