#!/bin/bash

# Start cron service
cron

# Start the Tor service with the specified configuration
tor -f /etc/tor/torrc
