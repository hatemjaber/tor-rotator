#!/bin/bash

# Default to 5 instances if NUM_TOR_INSTANCES is not set
NUM_TOR_INSTANCES=${NUM_TOR_INSTANCES:-5}

# Generate a random password and its hashed version
PASSWORD=$(openssl rand -base64 16)
HASHED_PASSWORD=$(tor --hash-password "$PASSWORD" | tail -n 1)

# Save credentials
echo "Password: $PASSWORD" > /app/credentials.txt
echo "HashedPassword: $HASHED_PASSWORD" >> /app/credentials.txt

# Generate Tor configurations dynamically
/app/generate_configs.sh $NUM_TOR_INSTANCES $HASHED_PASSWORD

# Start cron service
cron

# Start multiple Tor services, skip 2 each time (e.g., 9050, 9052, 9054, etc.)
for i in $(seq 0 2 $(($NUM_TOR_INSTANCES * 2 - 2))); do
    tor -f /etc/tor/torrc_$((i/2)) &
    sleep 5
done

# Start HAProxy
haproxy -f /etc/haproxy/haproxy.cfg
