#!/bin/bash

# Set the number of Tor instances; default to 5 if no argument is provided.
# This sets the number of Tor instances you'll be running.
NUM_TOR_INSTANCES=${NUM_TOR_INSTANCES:-5}

# The hashed password for Tor authentication.
# This password will be used to authenticate against the Tor ControlPort.
HASHED_PASSWORD=$2

# Initialize the HAProxy configuration with frontend and backend headers.
cat <<EOF > /etc/haproxy/haproxy.cfg
listen stats
    bind 0.0.0.0:9001
    mode http
    stats enable
    stats hide-version
    stats uri /stats
    stats realm HAProxy\ Statistics
    stats auth admin:admin
    timeout connect 10s
    timeout client  30s
    timeout server  30s

frontend http_frontend
    bind 0.0.0.0:9000
    mode http
    default_backend http_backend
    timeout client 50000ms

backend http_backend
    log global
    mode http
    balance roundrobin
    timeout connect 5000ms
    timeout server 50000ms
EOF

# Loop from 0 to NUM_TOR_INSTANCES * 2 - 2, skipping 2 each time.
# This loop generates the Tor configuration files for each instance.
# We skip 2 each time to ensure that SOCKS_PORT and CONTROL_PORT do not overlap.
for i in $(seq 0 2 $(($NUM_TOR_INSTANCES * 2 - 2))); do
    # Calculate the SOCKS_PORT by adding the loop variable to 9050.
    # This sets the SOCKS port for the current Tor instance.
    SOCKS_PORT=$((9050 + $i))
    
    # Calculate the CONTROL_PORT by adding the loop variable to 9051.
    # This sets the Control port for the current Tor instance.
    CONTROL_PORT=$((9051 + $i))
    
    # Calculate the PRIVOXY_PORT by adding the loop variable to 9051.
    # This sets the Control port for the current Tor instance.
    PRIVOXY_PORT=$((8120 + $i))

    # Create a directory for each Tor instance's data.
    DATA_DIR="/var/lib/tor_instance_$((i/2))"
    mkdir -p $DATA_DIR

    # Create a file for each privoxy instance's config.
    PRIVOXY_CONF="/etc/privoxy/config_$((i/2))"

    # Generate a Tor configuration file for each instance.
    # The instance number is determined by dividing i by 2.
    # Here we use a here-document to write multiple lines to a configuration file.
    cat <<EOF > /etc/tor/torrc_$((i/2))
SocksPort 127.0.0.1:$SOCKS_PORT
ControlPort 127.0.0.1:$CONTROL_PORT
Log notice stdout
Log info stdout
HashedControlPassword $HASHED_PASSWORD
DataDirectory $DATA_DIR
EOF

    # Create Privoxy config file
    echo "listen-address  127.0.0.1:$PRIVOXY_PORT" > $PRIVOXY_CONF
    echo "forward-socks5t / 127.0.0.1:$SOCKS_PORT ." >> $PRIVOXY_CONF

    # Add Privoxy instance to HAProxy backend
    echo "    server privoxy$i 127.0.0.1:$PRIVOXY_PORT check inter 4s" >> /etc/haproxy/haproxy.cfg
done

# The script ends here. Both Tor and HAProxy configurations have been generated.