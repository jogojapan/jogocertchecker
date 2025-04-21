#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
ORANGE='\033[0;33m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to display usage information
show_usage() {
    echo "Usage: $0 [--domain DOMAIN] [--domain-list FILE] [--simple-output]"
    echo "  --domain DOMAIN       Check SSL certificate for a single domain"
    echo "  --domain-list FILE    Check SSL certificates for domains listed in FILE (one domain per line)"
    echo "  --simple-output       Output in machine-readable format: domain|days_remaining"
    exit 1
}

# Function to check SSL certificate for a domain
check_ssl() {
    local DOMAIN=$1
    local SIMPLE_OUTPUT=$2

    if [ "$SIMPLE_OUTPUT" = false ]; then
        echo "Checking SSL certificate for: $DOMAIN"
    fi

    # Get certificate expiration date
    EXPIRY_DATE=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | 
                  openssl x509 -noout -enddate | 
                  cut -d= -f2)

    if [ -z "$EXPIRY_DATE" ]; then
        if [ "$SIMPLE_OUTPUT" = true ]; then
            echo "$DOMAIN|ERROR"
        else
            echo "Error: Could not retrieve SSL certificate information for $DOMAIN"
            echo "-----------------------------------"
        fi
        return 1
    fi

    # Convert expiry date to seconds since epoch
    EXPIRY_SECONDS=$(date -d "$EXPIRY_DATE" +%s)

    # Get current date in seconds since epoch
    CURRENT_SECONDS=$(date +%s)

    # Calculate difference in seconds and convert to days
    DAYS_REMAINING=$(( (EXPIRY_SECONDS - CURRENT_SECONDS) / 86400 ))

    if [ "$SIMPLE_OUTPUT" = true ]; then
        echo "$DOMAIN|$DAYS_REMAINING"
    else
        # Format output
        echo "Certificate expires on: $EXPIRY_DATE"
        echo -e "${BOLD}Days remaining: $DAYS_REMAINING days${NC}"

        # Add warning based on expiration status
        if [ $DAYS_REMAINING -lt 0 ]; then
            # Certificate has already expired
            echo -e "${RED}CRITICAL: Certificate has expired ${DAYS_REMAINING#-} days ago!${NC}"
        elif [ $DAYS_REMAINING -lt 30 ]; then
            # Certificate will expire in less than 30 days
            echo -e "${ORANGE}WARNING: Certificate will expire in less than 30 days!${NC}"
        else
            # Certificate is valid for more than 30 days
            echo -e "${GREEN}OK: Certificate is valid for more than 30 days.${NC}"
        fi

        echo "-----------------------------------"
    fi
}

# Initialize variables
SINGLE_DOMAIN=""
DOMAIN_LIST_FILE=""
SIMPLE_OUTPUT=false

# Check if no arguments were provided
if [ $# -eq 0 ]; then
    show_usage
fi

# Parse command line arguments
while [ $# -gt 0 ]; do
    case "$1" in
        --domain)
            if [ -z "$2" ]; then
                echo "Error: No domain specified after --domain"
                show_usage
            fi
            SINGLE_DOMAIN="$2"
            shift 2
            ;;
        --domain-list)
            if [ -z "$2" ]; then
                echo "Error: No file specified after --domain-list"
                show_usage
            fi
            DOMAIN_LIST_FILE="$2"
            if [ ! -f "$DOMAIN_LIST_FILE" ]; then
                echo "Error: File '$DOMAIN_LIST_FILE' not found"
                exit 1
            fi
            shift 2
            ;;
        --simple-output)
            SIMPLE_OUTPUT=true
            shift
            ;;
        *)
            echo "Error: Unknown option $1"
            show_usage
            ;;
    esac
done

# Check if at least one mode was specified
if [ -z "$SINGLE_DOMAIN" ] && [ -z "$DOMAIN_LIST_FILE" ]; then
    echo "Error: Either --domain or --domain-list must be specified"
    show_usage
fi

# Process single domain if specified
if [ -n "$SINGLE_DOMAIN" ]; then
    check_ssl "$SINGLE_DOMAIN" "$SIMPLE_OUTPUT"
fi

# Process domain list if specified
if [ -n "$DOMAIN_LIST_FILE" ]; then
    if [ "$SIMPLE_OUTPUT" = false ]; then
        echo "Processing domains from file: $DOMAIN_LIST_FILE"
        echo "-----------------------------------"
    fi

    while IFS= read -r domain || [ -n "$domain" ]; do
        # Skip empty lines and lines starting with #
        if [ -z "$domain" ] || [[ "$domain" == \#* ]]; then
            continue
        fi

        check_ssl "$domain" "$SIMPLE_OUTPUT"
    done < "$DOMAIN_LIST_FILE"
fi
