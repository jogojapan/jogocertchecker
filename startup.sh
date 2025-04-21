#!/bin/bash

# Create domains.txt from environment variable if provided
if [ -n "$SSL_DOMAINS" ]; then
    echo "# Domains list generated from SSL_DOMAINS environment variable" > /ssl-checker/domains.txt
    # Convert comma-separated list to newline-separated
    echo "$SSL_DOMAINS" | tr ',' '\n' >> /ssl-checker/domains.txt
    echo "Generated domains.txt from SSL_DOMAINS environment variable"
else
    # Use default domains.txt if no environment variable provided
    if [ ! -f /ssl-checker/domains.txt ]; then
        echo "# Default empty domains list" > /ssl-checker/domains.txt
        echo "Created empty domains.txt file"
    fi
fi

# Start cron service
echo "Starting cron service..."
cron -f
