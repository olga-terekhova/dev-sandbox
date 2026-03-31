FROM python:3.12-slim AS dev

ARG TZ
ENV TZ="$TZ"
ENV DEVCONTAINER=true

# System deps: base tools required by Claude Code and the firewall script,
# plus ca-certificates, jq, diffutils, tcpdump for dev diagnostics
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    bash \
    build-essential \
    sudo \
    ipset \
    iptables \
    ca-certificates \
    jq \
    diffutils \
    tcpdump \
    gnupg2 \
    aggregate \
    dnsutils \
    iproute2 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install uv
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

# Create non-root user
RUN useradd -m -s /bin/bash dev \
    && mkdir -p /workspace  \
    && mkdir -p /projects

# Firewall script is copied from .devcontainer/ at build context root
COPY init-firewall.sh /usr/local/bin/init-firewall.sh
RUN chmod +x /usr/local/bin/init-firewall.sh \
    && echo "dev ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" \
       > /etc/sudoers.d/firewall \
    && chmod 0440 /etc/sudoers.d/firewall


# Switch to the non-root user
USER dev
    
# Install Claude Code via native installer
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/home/dev/.local/bin:$PATH"

WORKDIR /workspace