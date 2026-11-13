#!/usr/bin/env bash
#
# Nightly MySQL backup. Managed by Ansible: deployment/roles/mysql.
#
# Writes {{ mysql_backup_directory }}/mysql-<host>-<UTC timestamp>.sql.zstd
# (a plain mysqldump piped through zstd), validates it, and only then renames
# it into place and prunes old dumps. See deployment/roles/mysql/README.md.
#
# Failure handling: every failure exits non-zero with a message on stderr (and
# in syslog). The cron job wraps this script in crontroller, which mails the
# output when the exit status is non-zero. A failed run never leaves a
# final-named file or a temp file behind.
#
# NOTE: this is a Jinja template, so do not use the bash length operator
# (dollar, brace, hash) in here; the brace-hash sequence starts a Jinja comment.

set -Eeuo pipefail
umask 077
export LC_ALL=C
export PATH="$PATH:/usr/local/bin:/usr/sbin:/usr/bin:/bin:/sbin"

readonly BACKUP_DIR="{{ mysql_backup_directory }}"
# Keep this many daily dumps. Never delete anything while fewer than this many
# valid dumps exist.
readonly KEEP={{ mysql_backup_keep | int }}
# Refuse to start when the filesystem has less free space than this.
readonly MIN_FREE_MB={{ mysql_backup_min_free_mb | int }}
# A finished dump smaller than this is considered broken.
readonly MIN_BYTES={{ mysql_backup_min_bytes | int }}

# The extension is deliberately NOT ".zst": the old (removed) logrotate rule
# globbed "*.zst" and, together with the misnamed uncompressed dumps, it is why
# the directory is full of empty files. Nothing that matches *.zst can ever
# match a file created by this script.
HOST_NAME="$(uname -n)"
readonly PREFIX="mysql-$HOST_NAME-"
readonly SUFFIX=".sql.zstd"
# The exact shape of a timestamp in a dump name. Retention only ever touches
# files matching PREFIX + this + SUFFIX.
readonly TS_GLOB='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9]'

# This runs on a 1 CPU box that also serves the website: run the dump and
# compression at the lowest CPU priority, and best-effort-lowest IO priority.
if command -v ionice >/dev/null 2>&1; then
    LOWPRIO=(nice -n 19 ionice -c2 -n7)
else
    LOWPRIO=(nice -n 19)
fi

tmp_file=""

log() {
    printf '%s mysql-backup: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*" >&2
}

die() {
    log "ERROR: $*"
    logger -t mysql-backup -p user.err -- "ERROR: $*" || true
    exit 1
}

cleanup() {
    if [[ -n "$tmp_file" ]]; then
        rm -f -- "$tmp_file"
    fi
}
trap cleanup EXIT
trap 'die "interrupted"' INT TERM
# Anything unexpected that set -e catches still produces a message.
trap 'log "ERROR: command failed (line $LINENO): $BASH_COMMAND"' ERR

# offsite_hook is called with the path of the new, validated dump after
# retention has run. It is intentionally empty: no offsite destination has been
# chosen yet. A failure here fails the run (and alerts), but the local dump is
# already in place.
offsite_hook() {
    : "$1"
}

# valid_dump PATH: a regular, non-empty file that zstd can decompress. This
# is the cheap check used on existing dumps; the new dump gets more checks.
valid_dump() {
    [[ -f "$1" && ! -L "$1" && -s "$1" ]] && zstd --test --quiet -- "$1" 2>/dev/null
}

# prune: delete the oldest dumps beyond KEEP. Only files named exactly like our
# dumps are considered, and only valid ones are counted or deleted, so nothing
# is removed unless at least KEEP newer valid dumps exist.
prune() {
    local f valid=0 deleted=0
    local -a all=()
    shopt -s nullglob
    # TS_GLOB is deliberately unquoted: it is a glob. The directory, prefix and
    # suffix are quoted so they are matched literally.
    # shellcheck disable=SC2206,SC2027
    all=("$BACKUP_DIR/$PREFIX"$TS_GLOB"$SUFFIX")
    shopt -u nullglob
    while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        if ! valid_dump "$f"; then
            log "WARNING: not counting invalid dump, leaving it alone: $f"
            continue
        fi
        valid=$((valid + 1))
        if ((valid > KEEP)); then
            rm -f -- "$f"
            deleted=$((deleted + 1))
        fi
    done < <(printf '%s\n' "${all[@]}" | sort -r)
    log "retention: $valid valid dumps found, kept $((valid - deleted)), deleted $deleted (keep=$KEEP)"
}

main() {
    if ! [[ "$KEEP" =~ ^[0-9]+$ ]] || ((KEEP < 1)); then
        die "KEEP must be an integer >= 1, got '$KEEP'"
    fi
    [[ -d "$BACKUP_DIR" ]] || die "backup directory $BACKUP_DIR does not exist"

    # Disk guard. The disk on this host is nearly full; do not make it worse.
    local free_kb
    free_kb="$(df -Pk "$BACKUP_DIR" | awk 'NR==2 {print $4}')"
    [[ "$free_kb" =~ ^[0-9]+$ ]] || die "could not determine free space for $BACKUP_DIR"
    if ((free_kb < MIN_FREE_MB * 1024)); then
        die "only $((free_kb / 1024)) MB free on the filesystem holding $BACKUP_DIR, need at least $MIN_FREE_MB MB; not starting"
    fi

    # One run at a time.
    exec 9>"$BACKUP_DIR/.mysql-backup.lock"
    flock --nonblock 9 || die "another mysql-backup is already running"

    # We hold the lock, so any leftover temp file is from a run that was killed
    # before it could clean up.
    find "$BACKUP_DIR" -maxdepth 1 -type f -name '.mysql-backup.tmp.*' -delete

    local stamp final
    stamp="$(date -u +%Y-%m-%d_%H-%M-%S)"
    final="$BACKUP_DIR/$PREFIX$stamp$SUFFIX"
    [[ ! -e "$final" ]] || die "$final already exists"

    # Dump to a temp file in the same directory (so the final rename is
    # atomic). The temp name does not match the dump pattern or *.zst.
    #
    # mysqldump is piped through zstd so the file really is compressed. The
    # previous version passed --compress --compression-algorithms=zstd to
    # mysqldump, which only compresses the client/server protocol (pointless
    # over a local socket) and wrote plain SQL to a file named *.zst.
    tmp_file="$(mktemp "$BACKUP_DIR/.mysql-backup.tmp.XXXXXX")"
    chmod 0600 "$tmp_file"
    log "starting dump to $final"
    if ! "${LOWPRIO[@]}" mysqldump --all-databases \
            --single-transaction --tz-utc \
            --user=root \
        | "${LOWPRIO[@]}" zstd --quiet --threads=1 > "$tmp_file"; then
        die "mysqldump or zstd failed; no backup was written"
    fi

    # Validate before the file gets a final name.
    local size
    size="$(wc -c < "$tmp_file" | tr -d '[:space:]')"
    ((size >= MIN_BYTES)) || die "dump is only $size bytes (minimum $MIN_BYTES); discarding"
    zstd --test --quiet -- "$tmp_file" || die "zstd integrity test failed; discarding"
    # mysqldump writes this footer last. If it is missing the dump was cut off.
    # (tail reads the whole stream, so zstd never gets SIGPIPE.)
    if ! zstd --decompress --stdout --quiet -- "$tmp_file" | tail -n 5 | grep -q '^-- Dump completed'; then
        die "dump has no '-- Dump completed' footer, it is truncated; discarding"
    fi

    mv -- "$tmp_file" "$final"
    tmp_file=""
    log "wrote $final ($size bytes)"

    # Retention only runs once a new valid dump is in place.
    prune

    offsite_hook "$final"
}

main "$@"
