FROM jogojapan/jogosmtp

# Install required packages
RUN apk add --no-cache \
    openssl \
    bash \
    coreutils \
    dcron \
    tzdata

# Create working directory
WORKDIR /ssl-checker

# Copy all scripts
COPY ssl_checker.sh check_and_notify.sh startup.sh /ssl-checker/
RUN chmod +x /ssl-checker/*.sh

# Add cron job
COPY crontab /etc/cron.d/ssl-checker
RUN chmod 0644 /etc/cron.d/ssl-checker

# Create log directory
RUN mkdir -p /var/log/ssl-checker

# Start services
CMD ["/ssl-checker/startup.sh"]
