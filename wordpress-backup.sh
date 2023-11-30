#!/bin/bash

# Initialize default WP_PATH
WP_PATH="/default/path/to/wordpress" # Update this with your default path
BACKUP_DIR="/default/path/to/backups" # Update this with your default backup path

# Check for essential commands
for cmd in mysqldump tar wp; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "Error: $cmd is not installed." >&2
        exit 1
    fi
done

# Check for '-c' parameter
if [ "$1" == "-c" ]; then
    WP_PATH="."
    BACKUP_DIR="./backups"
fi

# Change to the WordPress directory
if ! cd "$WP_PATH"; then
    echo "Error: Failed to change directory to $WP_PATH." >&2
    exit 1
fi

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
if ! mkdir -p "$BACKUP_PATH"; then
    echo "Error: Failed to create backup directory $BACKUP_PATH." >&2
    exit 1
fi

# Read database credentials from wp-config.php
DB_NAME=$(cat wp-config.php | grep DB_NAME | cut -d "'" -f 4)
DB_USER=$(cat wp-config.php | grep DB_USER | cut -d "'" -f 4)
DB_PASSWORD=$(cat wp-config.php | grep DB_PASSWORD | cut -d "'" -f 4)
DB_HOST=$(cat wp-config.php | grep DB_HOST | cut -d "'" -f 4)

# Perform MySQL dump
SQL_DUMP_FILE="$BACKUP_PATH/${DOMAIN_NAME}_db_$(date +"%Y%m%d_%H%M%S").sql"
mysqldump -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" > "$SQL_DUMP_FILE"

# Check mysqldump exit status
if [ $? -ne 0 ]; then
    echo "Error: MySQL dump failed." >&2
    exit 1
fi

# Verify that the SQL dump file is not empty
if [ ! -s "$SQL_DUMP_FILE" ]; then
    echo "Error: The SQL dump file is empty." >&2
    exit 1
fi

# Optionally, check for common MySQL error strings in the dump file
if grep -q "MySQL: " "$SQL_DUMP_FILE"; then
    echo "Warning: Potential errors found in the SQL dump file." >&2
    # You may choose to exit or alert the user and continue
fi

# Create a tar.gz archive of the WordPress directory
if ! tar -czvf "$BACKUP_PATH/${DOMAIN_NAME}_wordpress_$(date +"%Y%m%d_%H%M%S").tar.gz" .; then
    echo "Error: Failed to create tar.gz archive." >&2
    exit 1
fi

echo "Backup completed successfully. Files located at $BACKUP_PATH"
