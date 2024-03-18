#!/bin/bash

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <username>"
    exit 1
fi

USERNAME=$1
FTP_DIR="/home/$USERNAME/ftp"

# Vérifier si l'utilisateur existe déjà
if id "$USERNAME" &>/dev/null; then
    echo "L'utilisateur $USERNAME existe déjà."

else
    # Créer l'utilisateur avec le mot de passe
    useradd -g sftpusers "$USERNAME"
fi

# Vérifier si le répertoire existe déjà
if [ ! -d "$FTP_DIR" ]; then
    # Créer le répertoire avec les bonnes permissions
    mkdir -p "$FTP_DIR"
    chown root:root "$FTP_DIR"
    chmod 755 "$FTP_DIR"
    chown root:root /home/$USERNAME/ftp
    chmod 755 /home/$USERNAME
    echo "Répertoire $FTP_DIR créé."
else
    echo "Le répertoire $FTP_DIR existe déjà."
fi

if [ ! -d "/home/$USERNAME/.ssh" ]; then
    # Créer le répertoire avec les bonnes permissions
    mkdir -p "/home/$USERNAME/.ssh"
    chown root:root "/home/$USERNAME/.ssh"
    # TODO : ajouter clés publiqye id_ed25519 au authorization_keys de l'utilisateur nouvellement créé
    # chmod 700 /home/$USERNAME/.ssh
    # chmod 600 /home/$USERNAME/.ssh/authorized_keys
    # chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh
    echo "La clé SSH a été créé : copier le contenu de la clé publique dans le fichier /home/$USERNAME/.ssh/authorized_keys du client."
    cat /home/$USERNAME/.ssh/ # TODO: nom de la clé
else
    echo "Le dossier /home/$USERNAME/.ssh existe déjà."
fi

