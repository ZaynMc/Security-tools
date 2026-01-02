progress_bar() {
    local progress=$1
    local total=$2
    if [ "$total" -eq 0 ]; then total=1; fi
    local percent=$((progress * 100 / total))
    printf "\rProgression : %3d%%" "$percent"
}


secure_delete_file() {
    local file="$1"
    if [ -f "$file" ]; then
        if command -v srm &> /dev/null; then
            srm -z "$file" 
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            rm -P "$file"
        else
            shred -u -z "$file"
        fi
    fi
}

secure_delete_dir() {
    local dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -type f -exec bash -c '
            if [[ "$OSTYPE" == "darwin"* ]]; then rm -P "$1"; else shred -u -z "$1"; fi
        ' _ {} \;
        rm -rf "$dir"
    fi
}

get_file_size() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        stat -f%z "$1"
    else
        stat -c%s "$1"
    fi
}

if [ $# -ne 2 ]; then
    echo "Usage : $0 <fichier_ou_dossier> <0=crypter | 1=décrypter>"
    exit 1
fi

CIBLE="$1"
MODE="$2"

read -r -s -p "Entrez le mot de passe : " PASS
echo
export PASS 

CRYPTO_ARGS="-aes-256-cbc -pbkdf2 -iter 1000000 -md sha512 -salt -pass env:PASS"

if [ "$MODE" -eq 0 ]; then
    if [ -d "$CIBLE" ]; then
        ARCHIVE="${CIBLE%/}.tar.gz"
        echo "Archivage du dossier..."
        tar -czf "$ARCHIVE" "$CIBLE"
        
        SIZE=$(get_file_size "$ARCHIVE")
        OUTFILE="$ARCHIVE.enc"
        SOURCE_FILE="$ARCHIVE"
        IS_DIR=1
    elif [ -f "$CIBLE" ]; then
        SIZE=$(get_file_size "$CIBLE")
        OUTFILE="$CIBLE.enc"
        SOURCE_FILE="$CIBLE"
        IS_DIR=0
    else
        echo "Erreur : '$CIBLE' n'est pas valide."
        exit 3
    fi

    echo "Chiffrement AES-256 (SHA-512/1M itérations)..."

    dd if="$SOURCE_FILE" bs=4096 2>/dev/null | \
    openssl enc $CRYPTO_ARGS -out "$OUTFILE" &
    
    PID=$!
    while kill -0 $PID 2>/dev/null; do
        DONE=$(get_file_size "$OUTFILE" 2>/dev/null || echo 0)
        [ "$DONE" -gt "$SIZE" ] && DONE=$SIZE
        progress_bar "$DONE" "$SIZE"
        sleep 0.5
    done
    progress_bar "$SIZE" "$SIZE"
    echo
    wait $PID
    
    if [ $? -eq 0 ]; then
        if [ "$IS_DIR" -eq 1 ]; then
            secure_delete_dir "$CIBLE"
            secure_delete_file "$ARCHIVE"
        else
            secure_delete_file "$CIBLE"
        fi
        echo "✅ Succès : $OUTFILE créé (Original supprimé sécurisé)."
    else
        echo "❌ Erreur lors du cryptage."
        rm -f "$OUTFILE"
    fi

elif [ "$MODE" -eq 1 ]; then
    if [[ ! -f "$CIBLE" ]]; then
        echo "Erreur : le fichier '$CIBLE' n'existe pas."
        exit 3
    fi

    SIZE=$(get_file_size "$CIBLE")

    if [[ "$CIBLE" == *.tar.gz.enc ]]; then
        OUTFILE="${CIBLE%.enc}"
        IS_ARCHIVE=1
    else
        OUTFILE="${CIBLE%.enc}"
        IS_ARCHIVE=0
    fi

    echo "Déchiffrement..."
    
    openssl enc -d $CRYPTO_ARGS -in "$CIBLE" -out "$OUTFILE" &
    
    PID=$!
    while kill -0 $PID 2>/dev/null; do
       printf "\rTraitement en cours..."
       sleep 0.5
    done
    echo
    wait $PID
    
    if [ $? -eq 0 ]; then
        if [ "$IS_ARCHIVE" -eq 1 ]; then
            echo "Extraction de l'archive..."
            tar -xzf "$OUTFILE"
            secure_delete_file "$OUTFILE"
        fi
        secure_delete_file "$CIBLE" 
        echo "✅ Succès : Élément décrypté."
    else
        echo "❌ Erreur : Mot de passe incorrect ou fichier corrompu."
        rm -f "$OUTFILE"
    fi

else
    echo "Le second argument doit être 0 (crypter) ou 1 (décrypter)."
    exit 2
fi

unset PASS
