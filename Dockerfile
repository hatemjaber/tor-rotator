# Use Debian Bookworm Slim as the base image
FROM debian:bookworm-slim

# Install necessary packages: Tor, Python3, pip for Python3, cron, and haproxy
RUN apt-get update -y && apt-get install -y \
    tor \
    python3 \
    python3-pip \
    python3-venv \
    cron \
    haproxy \
    net-tools \
    privoxy

# Set working directory
WORKDIR /app

# Copy the script to generate Tor configurations
COPY scripts/generate_configs.sh /app/generate_configs.sh
RUN chmod +x /app/generate_configs.sh

# Add the Python script for rotating identity
COPY scripts/rotate_identity.py /app/
RUN chmod +x /app/rotate_identity.py

# Add a startup script to start services
COPY scripts/startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# Create a virtual environment and install stem
RUN python3 -m venv myenv && \
    . myenv/bin/activate && \
    pip install stem

# Set up the cron job to rotate the Tor identity
RUN echo "* * * * * python3 /app/rotate_identity.py >> /var/log/cron.log 2>&1" > tempcronjob && \
    crontab tempcronjob && \
    rm tempcronjob

# Command to run the startup script
CMD ["/app/startup.sh"]