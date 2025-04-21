#!/bin/bash

# Load environment variables if .env exists
if [ -f /ssl-checker/.env ]; then
    source /ssl-checker/.env
fi

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Main execution
log "Starting SSL certificate check"

# Check if required environment variables are set
if [ -z "$CERT_CHECKER_MAIL_ADDRESS" ]; then
    log "ERROR: CERT_CHECKER_MAIL_ADDRESS is not set"
    exit 1
fi

if [ -z "$MIN_SSL_CERT_EXPIRY" ]; then
    MIN_SSL_CERT_EXPIRY=30
    log "WARNING: MIN_SSL_CERT_EXPIRY not set, using default value of 30 days"
fi

# Run the SSL checker and capture output
OUTPUT_FILE="/tmp/ssl_check_output.txt"
/ssl-checker/ssl_checker.sh --domain-list /ssl-checker/domains.txt --simple-output > "$OUTPUT_FILE"

# Process results
WARNING_DOMAINS=()
while IFS='|' read -r domain days_remaining; do
    if [[ "$days_remaining" == "ERROR" ]]; then
        log "ERROR: Could not check certificate for $domain"
        continue
    fi

    if (( days_remaining < MIN_SSL_CERT_EXPIRY )); then
        WARNING_DOMAINS+=("$domain (expires in $days_remaining days)")
    fi
done < "$OUTPUT_FILE"

# Send email if any certificates are expiring soon
if [ ${#WARNING_DOMAINS[@]} -gt 0 ]; then
    log "Found ${#WARNING_DOMAINS[@]} certificates expiring soon, sending notification"

    # Prepare email content
    EMAIL_SUBJECT="SSL Certificate Expiration Warning"
    EMAIL_BODY="The following SSL certificates will expire in less than $MIN_SSL_CERT_EXPIRY days:\n\n"
    EMAIL_BODY+=$(printf '%s\n' "${WARNING_DOMAINS[@]}")
    EMAIL_BODY+="\n\nPlease renew these certificates as soon as possible."

    # Send email
    swaks --to "$CERT_CHECKER_MAIL_ADDRESS" \
          --h-Subject "$EMAIL_SUBJECT" \
          --body "$EMAIL_BODY"

    log "Notification email sent to $CERT_CHECKER_MAIL_ADDRESS"
else
    log "No certificates expiring soon found"
fi

log "SSL certificate check completed"
