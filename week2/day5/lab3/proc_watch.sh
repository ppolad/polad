#!/usr/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"
 
usage(){ echo "Usage: $(basename "$0") --name PATTERN [--interval SEC] [--cpu-limit PCT] [--mem-limit MB] [--action {log,kill}] [--samples N]"; }
PATTERN=""; INTERVAL=5; CPU_LIMIT=90; MEM_LIMIT=1024; ACTION=log; SAMPLES=12
 
while [[ $# -gt 0 ]]; do
  case "$1" in
    --name) PATTERN=${2:-}; shift 2;;
    --interval) INTERVAL=${2:-5}; shift 2;;
    --cpu-limit) CPU_LIMIT=${2:-90}; shift 2;;
    --mem-limit) MEM_LIMIT=${2:-1024}; shift 2;;
    --action) ACTION=${2:-log}; shift 2;;
    --samples) SAMPLES=${2:-12}; shift 2;;
    -h|--help) usage; exit 0;;
    *) die "Unknown arg: $1";;
  esac
done
 
[[ -z "$PATTERN" ]] && { usage; die "--name is required"; }
require ps; require awk
 
for ((i=1;i<=SAMPLES;i++)); do
  while read -r PID CPU RSS_KB CMD; do
    [[ -z "$PID" ]] && continue
    RSS_MB=$(( (RSS_KB + 1023) / 1024 ))
    log "proc pid=$PID cpu=${CPU}% rss=${RSS_MB}MB cmd=$CMD"
    if (( ${CPU%.*} > CPU_LIMIT || RSS_MB > MEM_LIMIT )); then
      if [[ "$ACTION" == "kill" ]]; then
        kill -9 "$PID" || true
        log "Killed pid=$PID (cpu>${CPU_LIMIT} or mem>${MEM_LIMIT})"
      fi
    fi
  done < <(
    ps aux | awk -v pat="$PATTERN" '
      NR>1 {
        cmd=""; for(i=11;i<=NF;i++) cmd=cmd" "$i;
        if(cmd ~ pat && cmd !~ /proc_watch\.sh/)
          printf "%s %s %s %s\n",$2,$3,$6,cmd
      }'
  )
  sleep "$INTERVAL"
done
