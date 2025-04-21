#!/bin/sh

# Create domains.txt from environment variable if provided
if [ -n "$SSL_DOMAINS" ]; then
    echo "# Domains list generated from SSL_DOMAINS environment variable" > /ssl-checker/domains.txt
    echo "$SSL_DOMAINS" | tr ',' '\n' >> /ssl-checker/domains.txt
    echo "Generated domains.txt from SSL_DOMAINS environment variable"
elif [ ! -f /ssl-checker/domains.txt ]; then
    echo "# Default empty domains list" > /ssl-checker/domains.txt
    echo "Created empty domains.txt file"
fi

# Start cron service
echo "Starting cron service..."
exec crond -f
