#!/bin/sh

# Generate domains.txt if SSL_DOMAINS is set
if [ -n "$SSL_DOMAINS" ]; then
    echo "# Domains list generated from SSL_DOMAINS environment variable" > /ssl-checker/domains.txt
    echo "$SSL_DOMAINS" | tr ',' '\n' >> /ssl-checker/domains.txt
    echo "Generated domains.txt from SSL_DOMAINS environment variable"
elif [ ! -f /ssl-checker/domains.txt ]; then
    echo "# Default empty domains list" > /ssl-checker/domains.txt
    echo "Created empty domains.txt file"
fi

# Generate crontab dynamically
: ${CERT_CHECKER_SCHEDULE:="0 8 * * *"}
echo "Using cron schedule: $CERT_CHECKER_SCHEDULE"

echo "$CERT_CHECKER_SCHEDULE root /ssl-checker/check_and_notify.sh >> /var/log/ssl-checker/ssl-checker.log 2>&1" \
    > /etc/crontabs/root

# Start cron service
echo "Starting cron service..."
exec crond -f -L /var/log/ssl-checker/cron.log
