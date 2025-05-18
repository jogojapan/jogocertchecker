#!/bin/sh

/usr/local/bin/configure-msmtp.sh &

# Generate domains.txt if SSL_DOMAINS is set
if [ -n "$SSL_DOMAINS" ]; then
    echo "# Domains list generated from SSL_DOMAINS environment variable" > /ssl-checker/domains.txt
    echo "$SSL_DOMAINS" | tr ',' '\n' >> /ssl-checker/domains.txt
    echo "Generated domains.txt from SSL_DOMAINS environment variable"
elif [ ! -f /ssl-checker/domains.txt ]; then
    echo "# Default empty domains list" > /ssl-checker/domains.txt
    echo "Created empty domains.txt file"
fi

# Set default check period if not specified (24 hours)
: ${CERT_CHECKER_PERIOD_HOURS:="24"}

# Calculate sleep time in seconds
SLEEP_TIME=$((CERT_CHECKER_PERIOD_HOURS * 3600))

echo "SSL certificate checker will run every ${CERT_CHECKER_PERIOD_HOURS} hours (${SLEEP_TIME} seconds)"

# Run check initially
echo "Running initial SSL check..."
/ssl-checker/check_and_notify.sh >> /var/log/ssl-checker/ssl-checker.log 2>&1

# Start the check loop
echo "Starting check loop..."
while true; do
    echo "Sleeping for ${CERT_CHECKER_PERIOD_HOURS} hours..."
    sleep ${SLEEP_TIME}
    echo "Running scheduled SSL check..."
    /ssl-checker/check_and_notify.sh >> /var/log/ssl-checker/ssl-checker.log 2>&1
done
