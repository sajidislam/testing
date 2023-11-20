#!/bin/bash

# Initialize default WP_PATH
WP_PATH="/default/path/to/wordpress" # Update this with your default path
BACKUP_DIR="/default/path/to/backups" # Update this with your default backup path

# Check for '-c' parameter
if [ "$1" == "-c" ]; then
    WP_PATH="."
    BACKUP_DIR="./backups"
fi

# Create a new directory with the current date and time
BACKUP_PATH="$BACKUP_DIR/backup_$(date +"%Y%m%d_%H%M%S")"
mkdir -p "$BACKUP_PATH"

# Change to the WordPress directory
cd "$WP_PATH"

# Read database credentials from wp-config.php
DB_NAME=$(cat wp-config.php | grep DB_NAME | cut -d "'" -f 4)
DB_USER=$(cat wp-config.php | grep DB_USER | cut -d "'" -f 4)
DB_PASSWORD=$(cat wp-config.php | grep DB_PASSWORD | cut -d "'" -f 4)
DB_HOST=$(cat wp-config.php | grep DB_HOST | cut -d "'" -f 4)

# Perform MySQL dump
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$BACKUP_PATH/db-backup.sql"

# Create a tar.gz archive of the WordPress directory
tar -czvf "$BACKUP_PATH/wordpress-backup.tar.gz" .

echo "Backup completed successfully. Files located at $BACKUP_PATH"
