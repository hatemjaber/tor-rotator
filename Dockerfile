# Use Debian Buster Slim as the base image
FROM debian:buster-slim

# Install necessary packages: Tor, Python3, pip for Python3, and cron
RUN apt-get update && apt-get install -y tor python3 python3-pip cron

# Set working directory
WORKDIR /app

# Generate a random password and its hashed version
RUN PASSWORD=$(openssl rand -base64 16) && \
    HASHED_PASSWORD=$(tor --hash-password "$PASSWORD" | tail -n 1) && \
    echo "Password: $PASSWORD" > /app/credentials.txt && \
    echo "HashedPassword: $HASHED_PASSWORD" >> /app/credentials.txt && \
    cat <<EOF > /etc/tor/torrc
SocksPort 0.0.0.0:9050
ControlPort 0.0.0.0:9051
Log notice stdout
Log info stdout
HashedControlPassword $HASHED_PASSWORD
EOF

# Install the stem library using pip3
RUN pip3 install stem

# Add the Python script for rotating identity
COPY scripts/rotate_identity.py /app/
RUN chmod +x /app/rotate_identity.py

# Set up the cron job to rotate the Tor identity
# COPY rotate-cron /etc/cron.d/rotate-cron
# RUN chmod 0644 /etc/cron.d/rotate-cron
# RUN touch /var/log/cron.log

RUN echo "* * * * * python3 /app/rotate_identity.py >> /var/log/cron.log 2>&1" > tempcronjob && \
    crontab tempcronjob && \
    rm tempcronjob

# Expose the SOCKS proxy port 
EXPOSE 9050

# Add a startup script to start services
COPY scripts/startup.sh /app/startup.sh
RUN chmod +x /app/startup.sh

# Command to run the startup script
CMD ["/app/startup.sh"]
