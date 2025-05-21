#!/bin/bash

# Default to 5 instances if NUM_TOR_INSTANCES is not set
NUM_TOR_INSTANCES=${NUM_TOR_INSTANCES:-5}

# Generate a random password and its hashed version
TOR_PASSWORD=$(openssl rand -base64 16)
HASHED_PASSWORD=$(tor --hash-password "$TOR_PASSWORD" | tail -n 1)

# Set the username and password
HAPROXY_USERNAME=${HAPROXY_USERNAME:-admin}
HAPROXY_PASSWORD=${HAPROXY_PASSWORD:-admin}
HAPROXY_TIMEOUT_CONNECT=${HAPROXY_TIMEOUT_CONNECT:-5s}
HAPROXY_TIMEOUT_CLIENT=${HAPROXY_TIMEOUT_CLIENT:-20s}
HAPROXY_TIMEOUT_SERVER=${HAPROXY_TIMEOUT_SERVER:-20s}
HAPROXY_RETRIES=${HAPROXY_RETRIES:-3}

# Save credentials securely
echo "Password: $TOR_PASSWORD" > /app/credentials.txt
chmod 600 /app/credentials.txt
echo "HashedPassword: $HASHED_PASSWORD" >> /app/credentials.txt

# Generate Tor configurations dynamically
/app/generate_configs.sh $NUM_TOR_INSTANCES $HASHED_PASSWORD $HAPROXY_USERNAME $HAPROXY_PASSWORD $HAPROXY_TIMEOUT_CONNECT $HAPROXY_TIMEOUT_CLIENT $HAPROXY_TIMEOUT_SERVER $HAPROXY_RETRIES

# Start cron service
cron

# Start multiple Tor and Privoxy instances
for i in $(seq 0 2 $(($NUM_TOR_INSTANCES * 2 - 2))); do
    tor -f /etc/tor/torrc_$((i/2)) &
    sleep 2
    /usr/sbin/privoxy --no-daemon /etc/privoxy/config_$((i/2)) &
done

# Start HAProxy
haproxy -f /etc/haproxy/haproxy.cfg
