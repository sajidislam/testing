#!/bin/bash

# Initialize default WP_PATH
WP_PATH="/default/path/to/wordpress" # Update this with your default path
BACKUP_DIR="/default/path/to/backups" # Update this with your default backup path

# Check for '-c' parameter
if [ "$1" == "-c" ]; then
    WP_PATH="."
    BACKUP_DIR="./backups"
fi

# Change to the WordPress directory
cd "$WP_PATH"

# Use WP-CLI to get the site domain and process it for the filename
SITE_URL=$(wp option get home 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "WP-CLI failed to retrieve the site URL. Do you want to continue without the site name in the backup file name? [y/n]"
    read -r user_input
    if [ "$user_input" != "y" ]; then
        echo "Script aborted by the user."
        exit 1
    fi
    DOMAIN_NAME="backup"
else
    DOMAIN_NAME=$(echo $SITE_URL | awk -F/ '{print $3}' | awk -F. '{OFS="_"; print $1, $2}')
fi

# Create a new directory with the current date, time, and domain name
BACKUP_PATH="$BACKUP_DIR/${DOMAIN_NAME}_$(date +"%Y%m%d_%H%M%S")"
mkdir -p "$BACKUP_PATH"

# Read database credentials from wp-config.php
DB_NAME=$(cat wp-config.php | grep DB_NAME | cut -d "'" -f 4)
DB_USER=$(cat wp-config.php | grep DB_USER | cut -d "'" -f 4)
DB_PASSWORD=$(cat wp-config.php | grep DB_PASSWORD | cut -d "'" -f 4)
DB_HOST=$(cat wp-config.php | grep DB_HOST | cut -d "'" -f 4)

# Perform MySQL dump
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_PATH/${DOMAIN_NAME}_db_$(date +"%Y%m%d_%H%M%S").sql"

# Create a tar.gz archive of the WordPress directory
tar -czvf "$BACKUP_PATH/${DOMAIN_NAME}_wordpress_$(date +"%Y%m%d_%H%M%S").tar.gz" .

echo "Backup completed successfully. Files located at $BACKUP_PATH"
