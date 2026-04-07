#!/usr/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
 
usage(){ echo "Usage: $(basename "$0") --file PATH --type {nginx,syslog} --out DIR"; }
FILE=""; TYPE=""; OUT=""
 
while [[ $# -gt 0 ]]; do
  case "$1" in
    --file) FILE=${2:-}; shift 2;;
    --type) TYPE=${2:-}; shift 2;;
    --out) OUT=${2:-}; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done
 
[[ -f "$FILE" ]] || die "File not found: $FILE"
[[ -n "$TYPE" ]] || die "--type required"
OUT=${OUT:-"$LOG_DIR"}
mkdir -p "$OUT"
 
require awk; require sort; require uniq; require head; require grep || true
 
case "$TYPE" in
  nginx)
    awk '{print $1}' "$FILE" | sort | uniq -c | sort -nr | head -20 > "$OUT/top-ips.txt"
    grep -h " 404 " "$FILE" 2>/dev/null | awk '{print $7}' | sort | uniq -c | sort -nr | head -20 > "$OUT/top-404.txt"
    awk -F '\"' '{print $6}' "$FILE" | sort | uniq -c | sort -nr | head -20 > "$OUT/user-agents.txt"
    ;;
  syslog)
    awk '{print $5}' "$FILE" | sed 's/[:\[].*$//' | sort | uniq -c | sort -nr | head -20 > "$OUT/top-programs.txt"
    awk '{print $1,$2,$3}' "$FILE" | sort | uniq -c | sort -nr | head -20 > "$OUT/top-error-times.txt"
    ;;
  *) die "Unknown type: $TYPE";;
esac
 
log "Log parsing complete for $TYPE. Output in $OUT"
