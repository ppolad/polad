#!/usr/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
 
usage() {
  cat << USAGE
Usage: $(basename "$0") --dir DIR [--pattern PAT] [--older-than DAYS] [--archive] [--delete] [--dry-run] [--retention N]
USAGE
}
 
DIR=""; PATTERN="*"; OLDER_DAYS=0; DO_ARCHIVE=false; DO_DELETE=false; DRY=false; RETENTION=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir) DIR=${2:-}; shift 2;;
    --pattern) PATTERN=${2:-"*"}; shift 2;;
    --older-than) OLDER_DAYS=${2:-0}; shift 2;;
    --archive) DO_ARCHIVE=true; shift;;
    --delete) DO_DELETE=true; shift;;
    --dry-run) DRY=true; shift;;
    --retention) RETENTION=${2:-0}; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done
 
[[ -z "$DIR" ]] && { usage; die "--dir is required"; }
[[ -d "$DIR" ]] || die "Directory not found: $DIR"
require find; require tar; require date
 
mapfile -t FILES < <(find "$DIR" -type f -name "$PATTERN" -mtime +"$OLDER_DAYS" -print | sort || true)
log "Matched files: ${#FILES[@]} (dir=$DIR pattern=$PATTERN older_than=$OLDER_DAYS)"
 
STAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE="$LOG_DIR/archive-$STAMP.tgz"
 
if $DO_ARCHIVE && ((${#FILES[@]} > 0)); then
  if $DRY; then
    log "[dry-run] Would archive ${#FILES[@]} files into $ARCHIVE"
  else
    tar -czf "$ARCHIVE" -C / $(printf -- "%s\n" "${FILES[@]}" | sed 's#^/##') 2>/dev/null || tar -czf "$ARCHIVE" -C "$DIR" .
    log "Created archive: $ARCHIVE"
  fi
fi
 
if $DO_DELETE && ((${#FILES[@]} > 0)); then
  if $DRY; then
    log "[dry-run] Would delete ${#FILES[@]} files"
  else
    while IFS= read -r f; do
      rm -f -- "$f"
    done < <(printf "%s\n" "${FILES[@]}")
    log "Deleted ${#FILES[@]} files"
  fi
fi
 
if (( RETENTION > 0 )); then
  mapfile -t ARCS < <(ls -1t "$LOG_DIR"/archive-*.tgz 2>/dev/null || true)
  if ((${#ARCS[@]} > RETENTION)); then
    TO_DELETE=("${ARCS[@]:$RETENTION}")
    if $DRY; then
      log "[dry-run] Would remove ${#TO_DELETE[@]} old archives"
    else
      printf "%s\n" "${TO_DELETE[@]}" | xargs -r rm -f --
      log "Retention applied, kept $RETENTION latest"
    fi
  fi
fi
mkdir -p "$LOG_DIR"

