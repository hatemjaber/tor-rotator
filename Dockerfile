# Use Debian Bookworm Slim as the base image
FROM debian:bookworm-slim

# Set environment variables for non-interactive apt-get and Python unbuffered output
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install necessary packages: Tor, Python3, pip, python3-venv, cron, haproxy, privoxy, net-tools.
# - tor, python3, pip, python3-venv, cron: Core for Tor and rotation.
# - haproxy, privoxy: Essential for the internal proxy/load balancing chain as per your design.
# - net-tools: Kept as in your original; useful for debugging ifconfig/netstat, though 'ip' command is usually preferred.
# Use --no-install-recommends to reduce image size by avoiding unnecessary packages.
# Clean up apt caches immediately after installation (in the same RUN layer)
# to reduce the final image size and improve caching efficiency.
RUN apt-get update -y && \
    apt-get install -y --no-install-recommends \
    tor \
    python3 \
    python3-pip \
    python3-venv \
    cron \
    haproxy \
    net-tools \
    privoxy \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Set working directory for the application
WORKDIR /app

# Create a Python virtual environment and install 'stem'.
# The venv ensures 'stem' and its dependencies are isolated.
RUN python3 -m venv /app/myenv && \
    /app/myenv/bin/pip install stem

# Create a dedicated directory for dynamically generated configuration files.
# Your 'generate_configs.sh' script will write torrc, privoxy.conf, and haproxy.cfg here.
RUN mkdir -p /app/configs

# Copy all application scripts into the container.
# This includes generate_configs.sh, rotate_identity.py, and startup.sh.
COPY scripts/generate_configs.sh /app/
COPY scripts/rotate_identity.py /app/
COPY scripts/startup.sh /app/

# Make the copied scripts executable.
RUN chmod +x /app/generate_configs.sh \
    /app/rotate_identity.py \
    /app/startup.sh

# Set up environment variable for rotation interval with default of 5 minutes
RUN echo "ROTATION_INTERVAL_MINUTES=\${ROTATION_INTERVAL_MINUTES:-5}" >> /etc/environment

# Expose the primary HAProxy port as defined in your docker-compose.yml.
# This makes it explicit which port the container listens on for external traffic.
EXPOSE 9000 9001

# Command to run the startup script.
# This script will manage launching all internal services (Tor, Privoxy, HAProxy, Cron).
CMD ["/app/startup.sh"]