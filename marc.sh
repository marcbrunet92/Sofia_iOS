#!/bin/bash

# === PARAMÈTRES ===
# /Users/marc/StudioProjects/Sofia_Android/app/src/main/java/com/lemarc/sofia
# /Users/marc/Desktop/Sofia/SofiaCore/Sources/SofiaCore
racine="/home/marcb/Sofia_iOS/Sofia"
dossierSortie="/home/marcb/Sofia_iOS/dev"
profondeur=-1   # -1 = pas de limite, 1 = un seul niveau

dossiersIgnores=(
    "Assets.xcassets"
    "node_modules"
    ".git"
    "__pycache__"
    ".venv"
    "dev_utils"
    ".idea"
    ".ruff_cache"
)

extensionsAutorisees=(
    ".swift"
)

# =========================================================

is_ignored() {
    local nom="$1"

    for dossier in "${dossiersIgnores[@]}"; do
        [[ "$nom" == "$dossier" ]] && return 0
    done

    return 1
}

generate_tree() {
    local path="$1"
    local prefix="$2"
    local current_depth="$3"

    if [[ $profondeur -ne -1 && $current_depth -ge $profondeur ]]; then
        return
    fi

    local entries=()

    local entries=()

    mapfile -t entries < <(
        find "$path" -mindepth 1 -maxdepth 1 | sort
    )

    local count=${#entries[@]}

    for ((i=0; i<count; i++)); do

        local entry="${entries[$i]}"
        local name
        name=$(basename "$entry")

        local connector
        local new_prefix

        if [[ $i -eq $((count - 1)) ]]; then
            connector="└── "
            new_prefix="${prefix}    "
        else
            connector="├── "
            new_prefix="${prefix}│   "
        fi

        echo "${prefix}${connector}${name}"

        if [[ -d "$entry" ]]; then
            generate_tree "$entry" "$new_prefix" $((current_depth + 1))
        fi
    done
}

generate_concatenation() {

    local output_file="$1"

    > "$output_file"

    local compteur=0

    while IFS= read -r fichier; do

        skip=false

        for dossier in "${dossiersIgnores[@]}"; do
            if [[ "$fichier" == *"/$dossier/"* ]]; then
                skip=true
                break
            fi
        done

        $skip && continue

        extension=".${fichier##*.}"

        autorise=false
        for ext in "${extensionsAutorisees[@]}"; do
            if [[ "$extension" == "$ext" ]]; then
                autorise=true
                break
            fi
        done

        $autorise || continue

        cheminRelatif="${fichier#$racine/}"

        {
            echo
            echo "===== Fichier: $cheminRelatif ====="
            echo
            cat "$fichier"
        } >> "$output_file"

        ((compteur++))

    done < <(
        if [[ $profondeur -eq -1 ]]; then
            find "$racine" -type f
        else
            find "$racine" -type f -maxdepth $((profondeur + 1))
        fi
    )

    if [[ $compteur -eq 0 ]]; then
        echo "Aucun fichier trouvé à concaténer."
    else
        echo "Nombre de fichiers concaténés : $compteur"
        echo "Concaténation enregistrée : $output_file"
    fi
}

main() {

    if [[ ! -d "$racine" ]]; then
        echo "Le répertoire spécifié n'existe pas : $racine"
        exit 1
    fi

    mkdir -p "$dossierSortie"

    local cheminArborescence="$dossierSortie/arborescence.txt"
    local cheminConcatenation="$dossierSortie/concatenation-data.txt"

#    {
#        echo "$racine"
#        generate_tree "$racine" "" 0
#    } > "$cheminArborescence"

    echo "Arborescence enregistrée avec succès dans : $cheminArborescence"

    generate_concatenation "$cheminConcatenation"
}

main
