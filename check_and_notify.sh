#!/bin/sh

# Load environment variables
if [ -f /ssl-checker/.env ]; then
    . /ssl-checker/.env
fi

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting SSL certificate check"

# Check required environment variables
if [ -z "$CERT_CHECKER_MAIL_ADDRESS" ]; then
    log "ERROR: CERT_CHECKER_MAIL_ADDRESS is not set"
    exit 1
fi

: ${MIN_SSL_CERT_EXPIRY:=30}
if [ "$MIN_SSL_CERT_EXPIRY" -eq 30 ]; then
    log "NOTICE: MIN_SSL_CERT_EXPIRY not set, using default value of 30 days"
fi

# Temporary file handling
OUTPUT_FILE="/tmp/ssl_check_output.$$"
trap 'rm -f "$OUTPUT_FILE"' EXIT

# Run SSL checker
/ssl-checker/ssl_checker.sh --domain-list /ssl-checker/domains.txt --simple-output > "$OUTPUT_FILE"

# Process results
WARNING_DOMAINS=""
while IFS='|' read -r domain days_remaining; do
    case $days_remaining in
        ERROR)
            log "ERROR: Could not check certificate for $domain"
            ;;
        *[!0-9-]*)
            log "WARNING: Invalid days remaining value for $domain: $days_remaining"
            ;;
        *)
            if [ "$days_remaining" -lt "$MIN_SSL_CERT_EXPIRY" ]; then
                WARNING_DOMAINS="$WARNING_DOMAINS$domain (expires in $days_remaining days)\n"
            fi
            ;;
    esac
done < "$OUTPUT_FILE"

# Send email if needed
if [ -n "$WARNING_DOMAINS" ]; then
    log "Found expiring certificates, sending notification"
    printf "The following SSL certificates will expire in less than %s days:\n\n%s\n\nPlease renew these certificates as soon as possible." \
        "$MIN_SSL_CERT_EXPIRY" "$WARNING_DOMAINS" | \
        swaks --to "$CERT_CHECKER_MAIL_ADDRESS" \
              --h-Subject "SSL Certificate Expiration Warning" \
              --body -
    log "Notification email sent to $CERT_CHECKER_MAIL_ADDRESS"
else
    log "No certificates expiring soon found"
fi

log "SSL certificate check completed"
