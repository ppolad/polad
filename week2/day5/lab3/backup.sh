#!/usr/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
 
usage(){ echo "Usage: $(basename "$0") --source DIR --dest DIR [--name NAME] [--exclude PATTERN] [--retention N]"; }
SRC=""; DEST=""; NAME="backup"; EXCLUDE=""; RET=7
 
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) SRC=${2:-}; shift 2;;
    --dest) DEST=${2:-}; shift 2;;
    --name) NAME=${2:-backup}; shift 2;;
    --exclude) EXCLUDE=${2:-}; shift 2;;
    --retention) RET=${2:-7}; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done
 
[[ -d "$SRC" ]] || die "Source not found: $SRC"
mkdir -p "$DEST"
require tar
 
STAMP=$(date +%Y%m%d-%H%M%S)
ARCHIVE="$DEST/${NAME}-${STAMP}.tgz"
 
if [[ -n "$EXCLUDE" ]]; then
  tar -czf "$ARCHIVE" --exclude="$EXCLUDE" -C "$SRC" .
else
  tar -czf "$ARCHIVE" -C "$SRC" .
fi
 
tar -tzf "$ARCHIVE" >/dev/null
log "Backup created and verified: $ARCHIVE"
 
if (( RET > 0 )); then
  mapfile -t ARCS < <(ls -1t "$DEST"/${NAME}-*.tgz 2>/dev/null || true)
  if ((${#ARCS[@]} > RET)); then
    TO_DELETE=("${ARCS[@]:$RET}")
    printf "%s\n" "${TO_DELETE[@]}" | xargs -r rm -f --
    log "Retention applied for $NAME, kept $RET"
  fi
fi
