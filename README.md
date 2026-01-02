🛡️ CryptShell : Chiffrement & Suppression Sécurisée

Présentation du projet

SafeCrypt-Shell est un script Bash automatisé permettant de sécuriser vos données sensibles via un chiffrement de niveau industriel. Contrairement à une simple protection par mot de passe, cet outil combine le chiffrement AES-256, l'archivage intelligent et la suppression définitive (shredding) pour garantir qu'aucune trace des fichiers originaux ne subsiste sur le disque après traitement.

🚀 Fonctionnalités Clés

Chiffrement de Haute Sécurité : Utilise OpenSSL avec l'algorithme AES-256-CBC.

Protection contre la force brute : Implémente PBKDF2 avec 1 000 000 d'itérations et un hachage SHA-512 pour dériver la clé à partir du mot de passe.

Gestion des dossiers : Compresse automatiquement les répertoires en archives .tar.gz avant le chiffrement.

Suppression Irréversible : Une fois le fichier chiffré, l'original est supprimé via srm, shred ou rm -P (selon l'OS), empêchant toute récupération par des logiciels de forensic.

Indicateur de Progression : Une barre de progression dynamique en temps réel suit l'état du traitement des données.

Cross-Platform : Détection automatique du système d'exploitation pour une compatibilité Linux et macOS.

🛠️ Détails Techniques

Architecture du Chiffrement

Le script utilise une configuration robuste pour la commande openssl enc :

PBKDF2 : Pour transformer votre mot de passe en une clé cryptographique complexe.

Salt : Ajout d'un sel aléatoire pour prévenir les attaques par table arc-en-ciel (rainbow tables).

Pass via Env : Le mot de passe est passé par une variable d'environnement (env:PASS) pour éviter qu'il n'apparaisse dans la liste des processus (ps).

Logique de Nettoyage

Le script choisit le meilleur outil disponible pour la suppression :

srm (Secure Remove) si installé.

shred -u -z (Linux) : Écrase le fichier avec des zéros et des données aléatoires avant suppression.

rm -P (macOS) : Écrase le fichier trois fois selon les standards de sécurité.

📖 Utilisation

Le script accepte deux arguments : le chemin du fichier/dossier et le mode (0 pour chiffrer, 1 pour déchiffrer).

Bash
./safecrypt.sh <fichier_ou_dossier> <0|1>
Exemple : Chiffrer un dossier confidentiel

Bash
./safecrypt.sh ./MesDocuments 0
Résultat : Un fichier MesDocuments.tar.gz.enc est créé et le dossier original est détruit.

⚠️ Avertissements de Sécurité

Perte de mot de passe : Aucune méthode de récupération n'existe. Si vous perdez le mot de passe, les données sont définitivement inaccessibles.

Stockage : Bien que le chiffrement soit robuste, assurez-vous de stocker vos fichiers .enc sur des supports fiables.
