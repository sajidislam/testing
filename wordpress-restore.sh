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

# Function to extract a value from wp-config.php
extract_from_wp_config() {
    local key=$1
    local file=$2
    grep "define.*'$key'" "$file" | grep -v '\/\*' | cut -d "'" -f 4
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
    DB_NAME=$(extract_from_wp_config 'DB_NAME' "$WP_PATH/wp-config.php")
    DB_USER=$(extract_from_wp_config 'DB_USER' "$WP_PATH/wp-config.php")
    DB_PASSWORD=$(extract_from_wp_config 'DB_PASSWORD' "$WP_PATH/wp-config.php")
    DB_HOST=$(extract_from_wp_config 'DB_HOST' "$WP_PATH/wp-config.php")
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
