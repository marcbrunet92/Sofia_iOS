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
    xcrun simctl io "$udid" screenshot --type=png "$file"
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
    xcrun simctl boot "$udid"
    xcrun simctl bootstatus "$udid" -b
    xcrun simctl status_bar "$udid" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
        --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true
    xcrun simctl install "$udid" "$APP"

    # Premier lancement : remplit le cache local (tout l'historique)
    xcrun simctl launch "$udid" "$BUNDLE_ID"
    sleep 60
    xcrun simctl terminate "$udid" "$BUNDLE_ID" || true

    mkdir -p "$OUT/$family"
    for shot in "${SHOTS[@]}"; do
        index=$((index + 1))
        IFS='|' read -r label appearance args <<<"$shot"
        xcrun simctl ui "$udid" appearance "$appearance"
        # shellcheck disable=SC2086 # arguments séparés volontairement
        xcrun simctl launch --terminate-running-process "$udid" "$BUNDLE_ID" $args
        sleep "$SETTLE"
        file="$OUT/$family/$(printf '%02d' "$index")-$label-$appearance.png"
        capture "$udid" "$file"
        echo "$file"
    done

    xcrun simctl shutdown "$udid"
    xcrun simctl delete "$udid"
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
