#!/bin/bash

# Function to prompt for database details
prompt_for_db_details() {
    read -p "Enter the Database Name [$DB_NAME]: " input_db_name
    DB_NAME=${input_db_name:-$DB_NAME}

    read -p "Enter the Database User [$DB_USER]: " input_db_user
    DB_USER=${input_db_user:-$DB_USER}

    read -p "Enter the Database Password [$DB_PASSWORD]: " input_db_password
    DB_PASSWORD=${input_db_password:-$DB_PASSWORD}
}

# Function to create or clear the database
create_or_clear_database() {
    echo "Creating or clearing the database: $DB_NAME"
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "DROP DATABASE IF EXISTS $DB_NAME; CREATE DATABASE $DB_NAME;"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create or clear the database."
        exit 1
    fi
}

# Check for '-c' parameter and set WP_PATH
WP_PATH="/path/to/wordpress" # default path, update as needed
if [ "$1" == "-c" ]; then 
    WP_PATH="."
fi

# Paths to SQL dump and WordPress archive
DB_DUMP_FILE="$WP_PATH/path/to/your/db-backup.sql" # Update this path
WP_ARCHIVE="$WP_PATH/path/to/your/wordpress-backup.tar.gz" # Update this path

# Unpack WordPress Files
echo "Restoring WordPress files from $WP_ARCHIVE..."
if ! tar -xzf "$WP_ARCHIVE" -C "$WP_PATH"; then
    echo "Error: Failed to extract WordPress files."
    exit 1
fi

# Extract database details from wp-config.php
if [ -f "$WP_PATH/wp-config.php" ]; then
    DB_NAME=$(cat "$WP_PATH/wp-config.php" | grep DB_NAME | cut -d "'" -f 4)
    DB_USER=$(cat "$WP_PATH/wp-config.php" | grep DB_USER | cut -d "'" -f 4)
    DB_PASSWORD=$(cat "$WP_PATH/wp-config.php" | grep DB_PASSWORD | cut -d "'" -f 4)
    DB_HOST=$(cat "$WP_PATH/wp-config.php" | grep DB_HOST | cut -d "'" -f 4)
else
    echo "Error: wp-config.php not found."
    exit 1
fi

# Prompt user to keep or modify the database details
prompt_for_db_details

# Restore Database
echo "Restoring database from $DB_DUMP_FILE..."
create_or_clear_database
if ! mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" "$DB_NAME" < "$DB_DUMP_FILE"; then
    echo "Error: Failed to restore the database."
    exit 1
fi

echo "Restore process completed successfully."
