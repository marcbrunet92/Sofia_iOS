#!/bin/bash
# Captures d'écran pour l'App Store : 10 sur iPhone 6,3" (1206 × 2622) et 10 sur iPad 13"
# (2064 × 2752), en clair et en sombre, avec les vraies données du serveur.
#
# Usage : .github/scripts/screenshots.sh <chemin de Sofia.app (build simulateur)> <dossier de sortie>
#
# Chaque vue est choisie par des arguments de lancement lus par Sofia/Util/ScreenshotOptions.swift.
set -euo pipefail

APP="$1"
OUT="$2"
BUNDLE_ID="com.lemarc.Sofia"
# Temps laissé à l'app avant chaque capture (cache déjà rempli, puis rafraîchissement réseau)
SETTLE="${SETTLE:-15}"

# Libellé | apparence | arguments de lancement
SHOTS=(
    "graph-1m|light|"
    "graph-24h-wind|light|-SofiaScreenshotWindow HOURS_24 -SofiaScreenshotDatasets pn,weather"
    "graph-6m|light|-SofiaScreenshotWindow MONTH_6 -SofiaScreenshotDatasets pn,b1610"
    "alerts|light|-SofiaScreenshotTab remit"
    "alert-detail|light|-SofiaScreenshotTab remit -SofiaScreenshotDetail YES"
    "graph-1m|dark|"
    "graph-1w-wind|dark|-SofiaScreenshotWindow DAYS_7 -SofiaScreenshotDatasets pn,weather"
    "graph-all|dark|-SofiaScreenshotWindow ALL -SofiaScreenshotDatasets b1610"
    "alerts|dark|-SofiaScreenshotTab remit"
    "alert-detail|dark|-SofiaScreenshotTab remit -SofiaScreenshotDetail YES"
)

# Horodatage, pour voir quelle étape prend du temps
log() {
    echo "[$(date -u +%H:%M:%S)] $*"
}

# Commande simctl avec un délai maximal : un simulateur bloqué fait échouer le job au lieu de
# l'occuper jusqu'à son délai d'une heure. macOS n'a pas `timeout` : alarm de perl.
sim() {
    local seconds="$1"
    shift
    perl -e 'alarm shift; exec @ARGV' "$seconds" xcrun simctl "$@"
}

RUNTIME=$(xcrun simctl list runtimes available -j \
    | jq -r '[.runtimes[] | select(.platform == "iOS")] | sort_by(.version | split(".") | map(tonumber)) | last | .identifier')
echo "Runtime : $RUNTIME"

# Premier type de simulateur disponible parmi ceux donnés
device_type() {
    local name id
    for name in "$@"; do
        id=$(xcrun simctl list devicetypes -j | jq -r --arg n "$name" '.devicetypes[] | select(.name == $n) | .identifier')
        if [ -n "$id" ]; then
            echo "Simulateur : $name" >&2
            echo "$id"
            return 0
        fi
    done
    echo "Aucun simulateur disponible parmi : $*" >&2
    return 1
}

# Une capture sans canal alpha (refusé par App Store Connect)
capture() {
    local udid="$1" file="$2"
    sim 60 io "$udid" screenshot --type=png "$file"
    if sips -g hasAlpha "$file" | grep -q 'yes'; then
        sips -s format jpeg -s formatOptions best "$file" --out "$file.jpg" >/dev/null
        sips -s format png "$file.jpg" --out "$file" >/dev/null
        rm "$file.jpg"
    fi
}

shoot() {
    local family="$1"
    shift
    local type udid index=0 shot label appearance args file
    type=$(device_type "$@")
    udid=$(xcrun simctl create "Sofia $family" "$type" "$RUNTIME")
    log "Démarrage du simulateur $family ($udid)"
    sim 600 bootstatus "$udid" -b >/dev/null
    log "Simulateur démarré"
    sim 60 status_bar "$udid" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true
    sim 300 install "$udid" "$APP"
    log "App installée"

    # Premier lancement : remplit le cache local (tout l'historique)
    sim 120 launch "$udid" "$BUNDLE_ID"
    sleep 60
    sim 60 terminate "$udid" "$BUNDLE_ID" || true
    log "Cache rempli"

    mkdir -p "$OUT/$family"
    for shot in "${SHOTS[@]}"; do
        index=$((index + 1))
        IFS='|' read -r label appearance args <<<"$shot"
        log "$family $index : $label ($appearance)"
        sim 60 ui "$udid" appearance "$appearance"
        # shellcheck disable=SC2086 # arguments séparés volontairement
        sim 120 launch --terminate-running-process "$udid" "$BUNDLE_ID" $args
        sleep "$SETTLE"
        file="$OUT/$family/$(printf '%02d' "$index")-$label-$appearance.png"
        capture "$udid" "$file"
        sim 60 terminate "$udid" "$BUNDLE_ID" || true
    done

    sim 120 shutdown "$udid" || true
    sim 120 delete "$udid" || true
}

# Tailles acceptées par App Store Connect pour iPhone 6,1"/6,3" et iPad 12,9"/13"
check_sizes() {
    local file width height status=0
    for file in "$OUT"/*/*.png; do
        width=$(sips -g pixelWidth "$file" | awk '/pixelWidth/ { print $2 }')
        height=$(sips -g pixelHeight "$file" | awk '/pixelHeight/ { print $2 }')
        case "${width}x${height}" in
            1179x2556 | 2556x1179 | 1206x2622 | 2622x1206 | 2048x2732 | 2732x2048 | 2064x2752 | 2752x2064)
                echo "OK   ${width}x${height}  $file" ;;
            *)
                echo "TAILLE REFUSÉE PAR L'APP STORE ${width}x${height}  $file"
                status=1 ;;
        esac
    done
    return $status
}

shoot iphone "iPhone 17 Pro" "iPhone 16 Pro" "iPhone 15 Pro"
shoot ipad "iPad Pro 13-inch (M5)" "iPad Pro 13-inch (M4)" "iPad Pro (12.9-inch) (6th generation)"
check_sizes
