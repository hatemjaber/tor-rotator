#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

echo "Starting Tor Proxy Container..."

# --- Initial Variable Setup (Your original logic) ---

# Default to 5 instances if NUM_TOR_INSTANCES is not set
# This value comes from docker-compose.yml if defined there, otherwise uses default.
NUM_TOR_INSTANCES=${NUM_TOR_INSTANCES:-5}

# Generate a random password and its hashed version
# This is crucial for rotate_identity.py to connect.
TOR_PASSWORD=$(openssl rand -base64 16)
# Ensure 'tor' command is available to hash the password.
# Use the full path if 'tor' is not directly in PATH (e.g., /usr/bin/tor)
HASHED_PASSWORD=$(tor --hash-password "$TOR_PASSWORD" | tail -n 1)

# Set HAProxy credentials and timeouts, using defaults if not provided by env vars.
HAPROXY_USERNAME=${HAPROXY_USERNAME:-admin}
HAPROXY_PASSWORD=${HAPROXY_PASSWORD:-admin}
HAPROXY_TIMEOUT_CONNECT=${HAPROXY_TIMEOUT_CONNECT:-5s}
HAPROXY_TIMEOUT_CLIENT=${HAPROXY_TIMEOUT_CLIENT:-20s}
HAPROXY_TIMEOUT_SERVER=${HAPROXY_TIMEOUT_SERVER:-20s}
HAPROXY_RETRIES=${HAPROXY_RETRIES:-3}

# Set rotation interval with default of 5 minutes
ROTATION_INTERVAL_MINUTES=${ROTATION_INTERVAL_MINUTES:-5}

# Save credentials securely. This is good for debugging/accessing later if needed.
# Ensure /app/credentials.txt is readable *only* by root.
echo "Password: $TOR_PASSWORD" > /app/credentials.txt
chmod 600 /app/credentials.txt
echo "Tor Hashed Password: $HASHED_PASSWORD" >> /app/credentials.txt
echo "HAProxy Username: $HAPROXY_USERNAME" >> /app/credentials.txt
echo "HAProxy Password: $HAPROXY_PASSWORD" >> /app/credentials.txt

# --- Dynamic Cron Job Creation ---

# Create the cron job dynamically based on the environment variable
if [ "$ROTATION_INTERVAL_MINUTES" -eq 1 ]; then
    CRON_SCHEDULE="* * * * *"
elif [ "$ROTATION_INTERVAL_MINUTES" -eq 5 ]; then
    CRON_SCHEDULE="*/5 * * * *"
elif [ "$ROTATION_INTERVAL_MINUTES" -eq 10 ]; then
    CRON_SCHEDULE="*/10 * * * *"
elif [ "$ROTATION_INTERVAL_MINUTES" -eq 15 ]; then
    CRON_SCHEDULE="*/15 * * * *"
elif [ "$ROTATION_INTERVAL_MINUTES" -eq 30 ]; then
    CRON_SCHEDULE="*/30 * * * *"
elif [ "$ROTATION_INTERVAL_MINUTES" -eq 60 ]; then
    CRON_SCHEDULE="0 * * * *"
else
    # For custom intervals, calculate the cron expression
    if [ $((60 % ROTATION_INTERVAL_MINUTES)) -eq 0 ]; then
        CRON_SCHEDULE="*/$ROTATION_INTERVAL_MINUTES * * * *"
    else
        echo "Warning: Custom rotation interval $ROTATION_INTERVAL_MINUTES minutes may not work perfectly with cron"
        CRON_SCHEDULE="*/5 * * * *"  # Fallback to 5 minutes
    fi
fi

echo "Setting rotation interval to $ROTATION_INTERVAL_MINUTES minutes (cron: $CRON_SCHEDULE)"
echo "$CRON_SCHEDULE root /app/myenv/bin/python /app/rotate_identity.py >> /dev/stdout 2>&1" > /etc/cron.d/rotate-tor-identity
chmod 0644 /etc/cron.d/rotate-tor-identity

# --- Configuration Generation ---

# Generate all necessary configuration files (torrcs, privoxy.confs, haproxy.cfg).
# The 'generate_configs.sh' script consumes these variables as arguments.
echo "Running generate_configs.sh to create configs for ${NUM_TOR_INSTANCES} Tor instances..."
/app/generate_configs.sh \
    "$NUM_TOR_INSTANCES" \
    "$HASHED_PASSWORD" \
    "$HAPROXY_USERNAME" \
    "$HAPROXY_PASSWORD" \
    "$HAPROXY_TIMEOUT_CONNECT" \
    "$HAPROXY_TIMEOUT_CLIENT" \
    "$HAPROXY_TIMEOUT_SERVER" \
    "$HAPROXY_RETRIES"

# --- Service Launching ---

# Start cron daemon first, as it manages identity rotation.
echo "Starting cron daemon for identity rotation..."
service cron start # Uses the system's cron service command

# Start multiple Tor and Privoxy instances in the background.
# This loop is crucial and should match your NUM_TOR_INSTANCES from config generation.
echo "Starting Tor and Privoxy instances..."
for i in $(seq 0 2 $(($NUM_TOR_INSTANCES * 2 - 2))); do
    /usr/bin/tor -f /etc/tor/torrc_$((i/2)) &
    echo "  - Started Tor instance ${i}"

    sleep 2
    /usr/sbin/privoxy --no-daemon /etc/privoxy/config_$((i/2)) &
    echo "  - Started Privoxy instance ${i}"
done

# Start HAProxy in the foreground as the primary container process.
# This is a critical Docker best practice:
# - 'exec' replaces the current shell script with HAProxy, making HAProxy PID 1.
# - If HAProxy exits, the container exits, signaling a problem.
# - '-db' flag enables debug logging for HAProxy, sending logs to stdout/stderr.
echo "Starting HAProxy in foreground..."
exec /usr/sbin/haproxy -f /etc/haproxy/haproxy.cfg -db
