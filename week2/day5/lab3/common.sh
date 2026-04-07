
#!/bin/bash
# Loq funksiyası
log() {
    local msg="$1"
    local timestamp=$(date '+%Y-%m-%d_%H:%M:%S')
    echo "[$timestamp] $msg" | tee -a "$HOME/lab7-outputs/lab7.log"
}

# Skriptlərdəki xətaların qarşısını almaq üçün 'require' funksiyası
require() {
    command -v "$1" >/dev/null 2>&1 || { log "Error: $1 tələb olunur amma tapılmadı."; exit 1; }
}
