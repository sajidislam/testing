#!/bin/bash

# Initialize default WP_PATH
WP_PATH="/default/path/to/wordpress"
BACKUP_DIR="/default/path/to/backups"
CRON_MODE=false
ERROR_MESSAGE=""

# Check for '-c' parameter
if [ "$1" == "-c" ]; then 
    WP_PATH="."
    BACKUP_DIR="./backups"
elif [ "$1" == "cron" ] && [ "$2" == "true" ]; then
    CRON_MODE=true
fi

# Check for essential commands
for cmd in mysqldump tar wp mail; do
    if ! command -v "$cmd" &> /dev/null; then
        ERROR_MESSAGE="Error: $cmd is not installed."
        echo "$ERROR_MESSAGE" >&2
        break
    fi
done

# Exit if any essential command is missing
if [ -n "$ERROR_MESSAGE" ]; then
    [ "$CRON_MODE" = true ] && echo "$ERROR_MESSAGE" | mail -s "WordPress Backup Script Error" "$(wp option get admin_email)"
    exit 1
fi

# Change to the WordPress directory
if ! cd "$WP_PATH"; then
    ERROR_MESSAGE="Error: Failed to change directory to $WP_PATH."
    echo "$ERROR_MESSAGE" >&2
fi

# Exit if changing directory fails
if [ -n "$ERROR_MESSAGE" ]; then
    [ "$CRON_MODE" = true ] && echo "$ERROR_MESSAGE" | mail -s "WordPress Backup Script Error" "$(wp option get admin_email)"
    exit 1
fi

# Use WP-CLI to get the site domain and process it for the filename
SITE_URL=$(wp option get home 2>/dev/null)
if [ $? -ne 0 ]; then
    ERROR_MESSAGE="WP-CLI failed to retrieve the site URL."
    echo "$ERROR_MESSAGE" >&2
    [ "$CRON_MODE" = true ] && echo "$ERROR_MESSAGE" | mail -s "WordPress Backup Script Error" "$(wp option get admin_email)"
    exit 1
fi

DOMAIN_NAME=$(echo $SITE_URL | awk -F/ '{print $3}' | awk -F. '{OFS="_"; print $1, $2}')

# Create a new directory with the current date, time, and domain name
BACKUP_PATH="$BACKUP_DIR/${DOMAIN_NAME}_$(date +"%Y%m%d_%H%M%S")"
if ! mkdir -p "$BACKUP_PATH"; then
    ERROR_MESSAGE="Error: Failed to create backup directory $BACKUP_PATH."
    echo "$ERROR_MESSAGE" >&2
fi

# Exit if creating backup directory fails
if [ -n "$ERROR_MESSAGE" ]; then
    [ "$CRON_MODE" = true ] && echo "$ERROR_MESSAGE" | mail -s "WordPress Backup Script Error" "$(wp option get admin_email)"
    exit 1
fi

# Read database credentials from wp-config.php
DB_NAME=$(cat wp-config.php | grep DB_NAME | cut -d "'" -f 4)
DB_USER=$(cat wp-config.php | grep DB_USER | cut -d "'" -f 4)
DB_PASSWORD=$(cat wp-config.php | grep DB_PASSWORD | cut -d "'" -f 4)
DB_HOST=$(cat wp-config.php | grep DB_HOST | cut -d "'" -f 4)

# Perform MySQL dump
SQL_DUMP_FILE="$BACKUP_PATH/${DOMAIN_NAME}_db_$(date +"%Y%m%d_%H%M%S").sql"
if ! mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$SQL_DUMP_FILE"; then
    ERROR_MESSAGE="Error: MySQL dump failed."
    echo "$ERROR_MESSAGE" >&2
fi

# Create a tar.gz archive of the WordPress directory
if ! tar -czvf "$BACKUP_PATH/${DOMAIN_NAME}_wordpress_$(date +"%Y%m%d_%H%M%S").tar.gz" .; then
    ERROR_MESSAGE="Error: Failed to create tar.gz archive."
    echo "$ERROR_MESSAGE" >&2
fi

# Final message and email notification
if [ -n "$ERROR_MESSAGE" ]; then
    FINAL_MESSAGE="The backup script executed. Here is the error it encountered: $ERROR_MESSAGE"
else
    FINAL_MESSAGE="The backup script executed and completed without any errors."
fi

echo "$FINAL_MESSAGE"

if [ "$CRON_MODE" = true ]; then
    echo "$FINAL_MESSAGE" | mail -s "WordPress Backup Script Execution" "$(wp option get admin_email)"
fi

# Exit with error status if there was an error
[ -n "$ERROR_MESSAGE" ] && exit 1
