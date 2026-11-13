# mysql role: backups

## What runs

`/root/bin/mysql-backup` (from `templates/backup.sh`) runs from root's crontab
every day at 22:11 (host time, UTC), wrapped in `crontroller`, which emails the
output when the script exits non-zero (see "Alerting" below).

It dumps all databases (`mysqldump --all-databases --single-transaction`),
pipes the dump through `zstd`, and writes
`/var/backups/mysql/mysql-<hostname>-<UTC timestamp>.sql.zstd`.

- The file is written to a temp file in the same directory, checked (size,
  `zstd --test`, and the `-- Dump completed` footer mysqldump writes last), and
  only then renamed to its final name. A failed run leaves nothing behind.
- The script refuses to run when less than `mysql_backup_min_free_mb` (1024)
  is free on the filesystem.
- Retention is in the script: it keeps the newest `mysql_backup_keep` (14)
  valid dumps and deletes older ones, only after a new dump succeeded, and only
  files named exactly like the dumps it creates.
- The directory is `0700 root:root` and dumps are `0600`; they contain
  WordPress password hashes.
- The extension is `.sql.zstd` on purpose. Do not use `*.zst` for backups, and
  do not put the backup directory in logrotate: the old logrotate rule on
  `*.zst` renamed every dump and created an empty file each day. The role
  deletes that rule and fails the deploy if any logrotate config mentions the
  backup directory.
- The script runs under `nice -n 19` and `ionice` because the host has one CPU.
- There is no offsite copy yet. `offsite_hook` in the script is the (empty)
  place to add one after the dump has been validated.

## Deploying only the backups

The tasks are tagged `mysql_backup`, so this works without the rest of the
playbook (the host is shared, so one playbook is enough):

    ansible-playbook eastbayforeveryone.org.yml --inventory hosts \
        --extra-vars @secrets/eastbayforeveryone.org.yml \
        --vault-password-file passwords/ansible-vault.password \
        --tags mysql_backup

## Verifying the latest backup

    cd /var/backups/mysql
    latest=$(ls -1 mysql-*.sql.zstd | tail -n 1)
    ls -l "$latest"
    zstd --test "$latest"
    zstd --decompress --stdout "$latest" | tail -n 3 | grep '^-- Dump completed'

## Restoring one database

Never restore straight over the live database first. Restore into a scratch
copy, check it, then decide.

    cd /var/backups/mysql
    latest=$(ls -1 mysql-*.sql.zstd | tail -n 1)
    # List the databases in the dump:
    zstd -dc "$latest" | grep '^-- Current Database:'

    DB=<database name>
    # 1. Extract that database's section.
    zstd -dc "$latest" \
      | sed -n "/^-- Current Database: \`$DB\`\$/,/^-- Current Database: \`/p" \
      > /root/restore-$DB.sql
    # 2. Rename it to a scratch database (only the CREATE DATABASE and USE lines).
    sed -e "/^CREATE DATABASE/s/\`$DB\`/\`${DB}_restore\`/" \
        -e "/^USE /s/\`$DB\`/\`${DB}_restore\`/" \
        /root/restore-$DB.sql > /root/restore-${DB}_scratch.sql
    # 3. Load the scratch copy and inspect it (row counts, recent posts, ...).
    mysql --user=root < /root/restore-${DB}_scratch.sql
    mysql --user=root -e "SHOW TABLES FROM \`${DB}_restore\`"

To replace the live database: take a fresh backup first (`/root/bin/mysql-backup`),
then either load `/root/restore-$DB.sql` (it drops and recreates each table in
`$DB`) or copy individual tables across with `RENAME TABLE`. Afterwards,
`DROP DATABASE \`${DB}_restore\`` and delete the files in `/root`.

## Alerting

`crontroller` sends mail through Sendgrid using `SENDGRID_TOKEN` from
`/home/crontroller/cfg/env`. The backup cron job sources that file. On
2026-11-12 every crontroller job on the host (including security updates) got
`401 Unauthorized` from Sendgrid (see `/root/curl.output` and
`/home/crontroller/curl.output` on the host), so no failure email is delivered
until that token is replaced. The script also logs failures to syslog
(`journalctl -t mysql-backup`).

## Old files from before this fix

Until 2026-11, dumps were named `mysql-<host>-<date>.zst`. They are not
compressed. Logrotate renamed them to `.zst.1`, `.zst.2`, ... and left an empty
`.zst` in their place, so the directory holds thousands of zero-byte files.

- The non-empty `*.zst.N` (and any older `*.zst`) files are real, plain-SQL
  dumps (`head -n 1` shows `-- MySQL dump`). They are not touched by the new
  script. Delete them whenever you decide you no longer need them.
- To delete only the zero-byte ones, set `mysql_backup_cleanup_legacy=true` for
  one run (`--extra-vars mysql_backup_cleanup_legacy=true --tags mysql_backup`),
  or by hand, listing first:

        find /var/backups/mysql -maxdepth 1 -type f -empty -mmin +60 \
            \( -name 'mysql-*.zst' -o -name 'mysql-*.zst.[0-9]*' \) -print | wc -l
        find /var/backups/mysql -maxdepth 1 -type f -empty -mmin +60 \
            \( -name 'mysql-*.zst' -o -name 'mysql-*.zst.[0-9]*' \) -delete
