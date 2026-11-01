#!/bin/bash
# Vidéo de démonstration pour l'App Review : sur un simulateur iPhone, on filme l'écran
# d'accueil, le lancement de l'app, puis le parcours automatique joué par l'app elle-même
# (-SofiaDemoTour YES, voir playDemoTour dans Sofia/SofiaApp.swift) : fenêtres de temps,
# jeux de données, feuille « À propos », onglet Alertes et détail d'une alerte.
#
# Apple demande une vidéo filmée sur un appareil physique : celle-ci sert d'aperçu et de
# script à reproduire sur l'iPhone.
#
# Usage : .github/scripts/demo-video.sh <chemin de Sofia.app (build simulateur)> <dossier de sortie>
set -euo pipefail

APP="$1"
OUT="$2"
BUNDLE_ID="com.lemarc.Sofia"
# Durée du parcours (environ 50 s) plus une marge pour le chargement des données
DURATION="${DURATION:-75}"

log() {
    echo "[$(date -u +%H:%M:%S)] $*"
}

# Commande simctl avec un délai maximal (macOS n'a pas `timeout` : alarm de perl)
sim() {
    local seconds="$1"
    shift
    perl -e 'alarm shift; exec @ARGV' "$seconds" xcrun simctl "$@"
}

RUNTIME=$(xcrun simctl list runtimes available -j \
    | jq -r '[.runtimes[] | select(.platform == "iOS")] | sort_by(.version | split(".") | map(tonumber)) | last | .identifier')
echo "Runtime : $RUNTIME"

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

type=$(device_type "iPhone 17 Pro" "iPhone 16 Pro" "iPhone 15 Pro")
udid=$(xcrun simctl create "Sofia demo" "$type" "$RUNTIME")
log "Démarrage du simulateur ($udid)"
sim 600 bootstatus "$udid" -b >/dev/null
sim 300 status_bar "$udid" override --time "9:41" --dataNetwork wifi --wifiMode active --wifiBars 3 \
    --cellularMode active --cellularBars 4 --batteryState charged --batteryLevel 100 || true
sim 120 ui "$udid" appearance light
sim 600 install "$udid" "$APP"
log "App installée"

# Premier lancement hors vidéo : remplit le cache local, la vidéo n'attend pas le réseau
sim 600 launch "$udid" "$BUNDLE_ID"
sleep 60
sim 120 terminate "$udid" "$BUNDLE_ID" || true
log "Cache rempli"

mkdir -p "$OUT"
file="$OUT/sofia-demo-iphone.mp4"
xcrun simctl io "$udid" recordVideo --codec=h264 --force "$file" &
recorder=$!
sleep 4
log "Lancement filmé"
sim 300 launch "$udid" "$BUNDLE_ID" -SofiaDemoTour YES
sleep "$DURATION"
kill -INT "$recorder"
wait "$recorder" || true
log "Vidéo : $file ($(du -h "$file" | cut -f1))"

sim 120 shutdown "$udid" || true
sim 120 delete "$udid" || true
