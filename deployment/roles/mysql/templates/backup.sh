#!/usr/bin/env bash

set -euo pipefail

main() {
    local -r backup_file="mysql-$(uname -n)-$(date +%Y-%m-%d_%H-%M-%S).zst"
    /usr/bin/mysqldump --all-databases --compression-algorithms=zstd \
        --compress \
        --single-transaction --tz-utc \
        --user=root > "{{ mysql_backup_directory }}/$backup_file"
    {% if tarsnap_enabled %}
    /usr/local/bin/tarsnap --print-stats -c \
        -f "$backup_file" "{{ mysql_backup_directory }}/$backup_file"
    {% endif %}
}

main "$@"
