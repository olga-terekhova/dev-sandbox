# Dev Sandbox

This repo defines a devcontainer with the following features:
- based on a `python-slim` image to focus on developing in Python
- uses `uv` to manage per-project environments
- mounts project directories into the `workspace` of the container
- runs Claude Code
  - uses native installer (not the deprecated node.js installation from the official Anthropic devcontainer)
  - removes node.js dependencies
  - uses firewall rules inherited from the official Anthropic devcontainer, but expands them to allow access to `pip`
  - persists Claude configs and uv configs in host directories mounted into the container
  - describes the container setup in `CLAUDE.md`
  - adds the 'analyze' skill to Claude to perform analysis before planning and implementation

The devcontainer is made for WSL2 on Windows, assuming the host directories are on the Windows filesystem - no need in UID matching between the users on the host machine and in the container.  