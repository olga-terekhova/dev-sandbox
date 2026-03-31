# Claude Code Context

## Environment

This is a personal Python development sandbox running inside a Docker devcontainer on
Windows (WSL2 backend). The container is based on python:3.12-slim and is used for
experimentation, learning, and personal side projects.

The container runs as a non-root user `dev`. The only elevated operation available is
running the firewall script: `sudo /usr/local/bin/init-firewall.sh`. Do not attempt
other sudo operations -- they will fail.

## Workspace Layout

/workspace is a bind-mount of the host control directory. It contains only the
control subdirectories -- do not work here directly:

    /workspace/
        .claude/          # Claude Code config and auth -- do not modify
        .uv-data/         # uv cache -- do not modify
        .devcontainer/    # Container config -- do not modify

Each container runs a single project, mounted separately at:

    /projects/
        <project>/        # Active project -- work here

Always work inside /projects/<project>/, not at /workspace.

## Package and Environment Management

Use `uv` for everything. Do not use `pip` directly.

Python version: 3.12

For each project:
- `uv init` to create a new project with pyproject.toml
- `uv venv` to create a virtual environment
- `uv add <package>` to add a runtime dependency
- `uv add --dev <package>` to add a dev-only dependency (e.g. pytest, ruff)
- `uv run <command>` to run commands inside the project environment

The uv cache is at /workspace/.uv-data/cache (set via UV_CACHE_DIR).

## Project Conventions

- Use pyproject.toml for all projects, even small ones. Avoid requirements.txt.
- Preferred dev tooling per project: ruff (linting and formatting), pytest (testing).
  Add them as dev dependencies: `uv add --dev ruff pytest`
- Python 3.12 features are available -- no need to maintain compatibility with older versions.

## Network Restrictions

The firewall restricts outbound access. The following destinations are reachable:

- GitHub (all ranges)
- pypi.org
- api.anthropic.com
- sentry.io, statsig.anthropic.com, statsig.com
- VS Code marketplace and update endpoints
- DNS (UDP 53) and SSH (TCP 22)

Everything else is blocked. Do not attempt to fetch from arbitrary URLs -- the
connection will be rejected. If a task requires a domain not on this list, say so
rather than silently failing.

## Interaction Style

- Ask clarifying questions before giving detailed answers.
- Notice assumptions being made and surface them explicitly before proceeding.
- ASCII-only in comments and docstrings.