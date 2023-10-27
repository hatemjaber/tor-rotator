#!/bin/bash

# Default to 5 instances if NUM_TOR_INSTANCES is not set
NUM_TOR_INSTANCES=${NUM_TOR_INSTANCES:-5}

# Generate a random password and its hashed version
PASSWORD=$(openssl rand -base64 16)
HASHED_PASSWORD=$(tor --hash-password "$PASSWORD" | tail -n 1)

# Save credentials securely
echo "Password: $PASSWORD" > /app/credentials.txt
chmod 600 /app/credentials.txt
echo "HashedPassword: $HASHED_PASSWORD" >> /app/credentials.txt

# Generate Tor configurations dynamically
/app/generate_configs.sh $NUM_TOR_INSTANCES $HASHED_PASSWORD

# Start cron service
cron

# Clear PID files
> tor_pids.txt
> privoxy_pids.txt

# Start multiple Tor and Privoxy instances
for i in $(seq 0 2 $(($NUM_TOR_INSTANCES * 2 - 2))); do
    tor -f /etc/tor/torrc_$((i/2)) &
    sleep 2
    /usr/sbin/privoxy --no-daemon /etc/privoxy/config_$((i/2)) &
done

# Start HAProxy
haproxy -f /etc/haproxy/haproxy.cfg
