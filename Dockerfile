# Use Debian Buster Slim as the base image
FROM debian:buster-slim

# Install necessary packages: Tor, Python3, pip for Python3, cron, and haproxy
RUN apt-get update && apt-get install -y tor python3 python3-pip cron haproxy net-tools privoxy

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

# Install the stem library using pip3
RUN pip3 install stem

# Set up the cron job to rotate the Tor identity
RUN echo "* * * * * python3 /app/rotate_identity.py >> /var/log/cron.log 2>&1" > tempcronjob && \
    crontab tempcronjob && \
    rm tempcronjob

# Expose the SOCKS proxy port
EXPOSE 9050

# Command to run the startup script
CMD ["/app/startup.sh"]