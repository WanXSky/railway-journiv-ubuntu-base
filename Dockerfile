FROM ubuntu:22.04

# ========================
# 1. SYSTEM DEPENDENCIES
# ========================
RUN apt-get update && apt-get install -y --no-install-recommends \
    iproute2 iputils-ping openssh-server telnet sudo \
    curl wget ca-certificates git screen \
    libmagic1 ffmpeg libffi8 libpq5 \
    libheif1 libde265-0 libpango-1.0-0 libpangoft2-1.0-0 libharfbuzz-subset0 \
    python3.12 python3.12-venv python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
ENV CLOUDFLARED_TUNNEL=""
# ========================
# 2. PYTHON TOOLS (uv)
# ========================
RUN pip3 install uv

# ========================
# 3. CLOUDFLARED
# ========================
RUN mkdir -p /usr/share/keyrings \
    && curl -fsSL https://pkg.cloudflare.com/cloudflare-public-v2.gpg | tee /usr/share/keyrings/cloudflare-public-v2.gpg >/dev/null \
    && echo 'deb [signed-by=/usr/share/keyrings/cloudflare-public-v2.gpg] https://pkg.cloudflare.com/cloudflared any main' > /etc/apt/sources.list.d/cloudflared.list \
    && apt-get update \
    && apt-get install -y cloudflared \
    && apt-get clean

# ========================
# 4. SSH SERVER (dengan config script)
# ========================
RUN mkdir -p /run/sshd \
    && echo "PasswordAuthentication yes" >> /etc/ssh/sshd_config \
    && echo "PermitRootLogin no" >> /etc/ssh/sshd_config

# Copy SSH config script
COPY ssh-user-config.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/ssh-user-config.sh

# ========================
# 5. CLONE JOURNIV DARI GITHUB
# ========================
ARG REPO_URL=https://github.com/journiv/journiv-app.git
ARG BRANCH=main

WORKDIR /app
RUN git clone --depth 1 --branch $BRANCH $REPO_URL journiv-app
WORKDIR /app/journiv-app

# Setup virtual environment & install dependencies
RUN python3.12 -m venv .venv \
    && . .venv/bin/activate \
    && uv sync --locked --no-editable --no-install-project

# ========================
# 6. ENTRYPOINT (jalanin SSH + Journiv)
# ========================
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 22 8000

ENTRYPOINT ["/entrypoint.sh"]
