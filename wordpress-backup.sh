#!/bin/bash

# Set the path to your WordPress installation
WP_PATH="/path/to/wordpress"

# Set the backup directory (you can change this to a path of your choice)
BACKUP_DIR="/path/to/backups"

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
