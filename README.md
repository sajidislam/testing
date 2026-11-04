# WordPress Backup & Restore Scripts

Bash scripts to back up and restore a WordPress site (files + database). Useful for manual backups, migrations, or scheduled cron jobs.

## Scripts

| Script | Purpose | When to use |
|--------|---------|-------------|
| `wordpress-backup.sh` | Creates a full backup: MySQL dump + tar.gz of the WordPress directory. Supports cron mode with email notifications. | Regular backups, scheduled jobs, or before making changes. |
| `wordpress-restore.sh` | Full restore: extracts the WordPress archive **and** restores the database. Can update `wp-config.php` if you change DB credentials during the prompt. | Migrating a site, restoring to a new server, or full recovery. |
| `wp-db-restore.sh` | Database-only restore. File extraction is commented out. Uses hardcoded paths (customize before use). | When files are already in place and you only need to restore or replace the database. |

## Prerequisites

Install the following on the server:

- `mysql` / `mysqldump` (MySQL client tools)
- `tar`
- `wp` (WP-CLI) — required by the backup script
- `mail` (optional, used for cron email notifications)

Example (Ubuntu/Debian):
```bash
sudo apt update
sudo apt install mysql-client tar mailutils
# Install WP-CLI separately: https://wp-cli.org/
```

## Path Customization

All scripts have default paths near the top that **must be edited** for your environment before first use:

- `WP_PATH` — location of the WordPress installation
- `BACKUP_DIR` (backup script) — where backup folders are written
- SQL dump and archive paths (restore scripts)

You can also pass `-c` to run relative to the current directory:
```bash
./wordpress-backup.sh -c
./wordpress-restore.sh -c
./wp-db-restore.sh -c
```

## How to Run

1. Make the scripts executable:
   ```bash
   chmod +x wordpress-backup.sh wordpress-restore.sh wp-db-restore.sh
   ```
2. Edit the path variables inside each script.
3. Run the desired script:
   ```bash
   ./wordpress-backup.sh          # or with -c or cron true
   ./wordpress-restore.sh
   ./wp-db-restore.sh
   ```

### Backup script extras
- `./wordpress-backup.sh cron true` — enables cron mode (emails admin on success/failure).
- Creates a timestamped directory containing the `.sql` dump and `.tar.gz` archive.

### Restore scripts
- Prompt for database name/user/password (defaults come from `wp-config.php`).
- `wordpress-restore.sh` will also rewrite `wp-config.php` if you change any credentials.
- Both drop and recreate the database before importing the dump.

## After Running — Verification

**Backup**
- Confirm the new directory appeared under your `BACKUP_DIR`.
- Check that both the `.sql` and `.tar.gz` files exist and are non-empty.
- Optionally test the dump: `head -n 20 path/to/dump.sql`

**Restore**
- Visit the site in a browser.
- Log into wp-admin.
- Spot-check recent posts, pages, and media.
- Verify `wp-config.php` contains the expected database credentials (especially after `wordpress-restore.sh`).
- Check the database size or table count if you have access:
  ```bash
  mysql -u user -p -e "SHOW TABLES;" dbname | wc -l
  ```

## Notes

- Always test restores on a staging copy first.
- The scripts assume a standard WordPress layout with `wp-config.php` in the root.
- Database credentials are read from `wp-config.php`; keep that file secure.
- `wp-db-restore.sh` currently has site-specific paths — update them before use.

## License

Scripts are provided as-is for personal/server use.
