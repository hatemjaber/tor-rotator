#!/bin/bash

# Set the number of Tor instances; default to 5 if no argument is provided.
# This sets the number of Tor instances you'll be running.
NUM_TOR_INSTANCES=$1

# The hashed password for Tor authentication.
# This password will be used to authenticate against the Tor ControlPort.
HASHED_PASSWORD=$2

# Set the username and password
HAPROXY_USERNAME=$3
HAPROXY_PASSWORD=$4

cat <<EOF > /etc/haproxy/auth-check.lua
local b = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding
local function base64enc(data)
    return ((data:gsub('.', function(x) 
        local r, b = '', x:byte()
        for i = 8, 1, -1 do r = r .. (b % 2 ^ i - b % 2 ^ (i - 1) > 0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c = 0
        for i = 1, 6 do c = c + (x:sub(i, i) == '1' and 2 ^ (6 - i) or 0) end
        return b:sub(c + 1, c + 1)
    end)..({ '', '==', '=' })[#data % 3 + 1])
end

-- auth-check.lua
function auth_check(txn)
    local headers = txn.http:req_get_headers()
    local proxy = headers['proxy-authorization'][0]
    local expected = 'Basic ' .. base64enc('$HAPROXY_USERNAME:$HAPROXY_PASSWORD')  -- Replace username and password
    
    expected = expected:gsub("^%s*(.-)%s*$", "%1")
    proxy = proxy:gsub("^%s*(.-)%s*$", "%1")
    
    if expected == proxy then
        txn:set_var("txn.auth_successful", true)
    end
end

core.register_action("auth_check", { "http-req" }, auth_check)
EOF

# Initialize the HAProxy configuration with frontend and backend headers.
cat <<EOF > /etc/haproxy/haproxy.cfg
global
    lua-load /etc/haproxy/auth-check.lua  # Update the path as necessary

defaults
    mode http
    timeout connect 5s
    timeout client 20s
    timeout server 20s
    retries 3

listen stats
    bind 0.0.0.0:9001
    stats enable
    stats hide-version
    stats uri /stats
    stats realm HAProxy\ Statistics
    stats auth $HAPROXY_USERNAME:$HAPROXY_PASSWORD

frontend http_frontend
    bind 0.0.0.0:9000
    http-request lua.auth_check
    http-request deny if !{ var(txn.auth_successful) -m bool }
    default_backend http_backend

backend http_backend
    log global
    balance roundrobin
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