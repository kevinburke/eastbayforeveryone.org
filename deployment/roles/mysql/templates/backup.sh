#!/usr/bin/env bash

set -euo pipefail

main() {
    local -r backup_file="mysql-$(uname -n)-$(date +%Y-%m-%d_%H-%M-%S)"
    /usr/bin/mysqldump --all-databases --single-transaction --user=root > "/root/tmp/$backup_file"
    {% if tarsnap_enabled %}
    /usr/local/bin/tarsnap --print-stats -c \
        -f "$backup_file" "/root/tmp/$backup_file"
    {% endif %}
}

main "$@"
