#!/bin/bash

# Launch Chrome with the Tor proxy
# This script launches a new instance of Google Chrome with a temporary user profile,
# and routes its traffic through the local Tor proxy.

# --- Configuration ---
# The address of the proxy
PROXY_ADDRESS="127.0.0.1:3128"
# The URL to open in the new Chrome window
TARGET_URL="https://check.torproject.org/"

# --- Script ---
mkdir -p /tmp/chrome_profile

# Create a temporary directory for the Chrome user profile.
# This ensures that the new Chrome instance doesn't interfere with your existing one.
PROFILE_DIR=/tmp/chrome_profile

# Launch Google Chrome with the specified proxy settings.
#
# --proxy-server: Specifies the proxy server to use for all traffic.
#   Format: "http://<user>:<pass>@<address>"
#
# --user-data-dir: Specifies the directory to use for the user profile.
#   This creates a new, temporary profile for this session.
#
# --no-first-run: Prevents the first-run welcome screen from appearing.
#
# --new-window: Opens a new Chrome window.
#
# <TARGET_URL>: The URL to open in the new window.
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --proxy-server="${PROXY_ADDRESS}" \
  --user-data-dir="${PROFILE_DIR}" \
  --no-first-run \
  --new-window \
  "${TARGET_URL}"

# Clean up the temporary profile directory when the script exits.
trap 'rm -rf "${PROFILE_DIR}"' EXIT

