#!/bin/bash
# setup.sh - Installation complète toolchain STM32 + utilitaires
# Usage: bash setup.sh

set -e

# -------- VARIABLES --------
GCC_URL="https://launchpad.net/gcc-arm-embedded/5.0/5-2016-q3-update/+download/gcc-arm-none-eabi-5_4-2016q3-20160926-linux.tar.bz2"
GCC_INSTALL_DIR="/opt/arm-gcc-5.4"
SW4STM32_URL="https://www.ac6-tools.com/downloads/SW4STM32/install_sw4stm32_linux_64bits-v2.3.run"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_GCC_ARCHIVE="gcc-arm-none-eabi-5_4-2016q3-linux.tar.bz2"
LOCAL_SW4_RUN="install_sw4stm32.run"

# -------- 1️⃣ Vérification privilèges --------
if [[ $EUID -ne 0 ]]; then
    echo "⚠️  Ce script doit être lancé avec sudo."
    exit 1
fi

# -------- 2️⃣ Installer paquets nécessaires --------
echo "📦 Installation des paquets système..."
apt update
apt install -y openocd tmux git hexcurse telnet wget bzip2 picocom minicom make

# -------- 3️⃣ Support 32-bit pour gcc 5.4 --------
dpkg --add-architecture i386 || true
apt update
apt install -y libc6:i386 libstdc++6:i386 libncurses6:i386 zlib1g:i386 libbz2-1.0:i386 libgcc1:i386

# -------- Install paquets graphiques pour Systemworkbench --------
apt update
apt install -y libgtk2.0-0t64 libxtst6 libxrender1 libxrandr2 libxi6

# -------- Install paquets pour esp idf --------
apt update
apt install -y wget flex bison gperf python3 python3-pip python3-venv cmake ninja-build ccache libffi-dev libssl-dev dfu-util libusb-1.0-0

# Créer des liens symboliques si nécessaires
for lib in ncurses tinfo; do
    lib6_path="/usr/lib/i386-linux-gnu/lib${lib}.so.6"
    lib5_path="/usr/lib/i386-linux-gnu/lib${lib}.so.5"
    if [[ -f "$lib6_path" && ! -f "$lib5_path" ]]; then
        echo "🔗 Création du lien symbolique $lib5_path → $lib6_path"
        ln -s "$lib6_path" "$lib5_path"
    fi
done

# -------- 4️⃣ Installer GCC ARM 5.4 --------
echo "📥 Installation de GCC 5.4..."
mkdir -p /tmp/gcc-arm
cd /tmp/gcc-arm

if [[ -f "$SCRIPT_DIR/$LOCAL_GCC_ARCHIVE" ]]; then
    echo "📦 Utilisation de l'archive GCC locale"
    cp "$SCRIPT_DIR/$LOCAL_GCC_ARCHIVE" .
else
    echo "🌐 Téléchargement de GCC depuis internet"
    wget -O "$LOCAL_GCC_ARCHIVE" "$GCC_URL"
fi

rm -rf "$GCC_INSTALL_DIR"
tar xjf "$LOCAL_GCC_ARCHIVE"
mv gcc-arm-none-eabi-5_4-2016q3 "$GCC_INSTALL_DIR"

# -------- Ajouter au PATH --------
# Ligne à ajouter dans bashrc
BASHRC_LINE="export PATH=\"$GCC_INSTALL_DIR/bin:\$PATH\""
if ! grep -Fxq "$BASHRC_LINE" /home/$SUDO_USER/.bashrc; then
    echo "📌 Ajout de GCC au PATH dans .bashrc"
    echo "$BASHRC_LINE" >> /home/$SUDO_USER/.bashrc
fi

# -------- 5️⃣ Installer System Workbench v2.3 --------
echo "📥 Préparation de System Workbench v2.3..."
USER_HOME=$(eval echo "~$SUDO_USER")
mkdir -p "$USER_HOME/Ac6"
cd "$USER_HOME/Ac6"

if [[ -f "$SCRIPT_DIR/$LOCAL_SW4_RUN" ]]; then
    echo "📦 Utilisation de l'installateur local SW4STM32"
    cp "$SCRIPT_DIR/$LOCAL_SW4_RUN" install_sw4stm32.run
else
    echo "🌐 Téléchargement de SW4STM32 depuis internet"
    wget -O install_sw4stm32.run "$SW4STM32_URL"
fi

chmod +x install_sw4stm32.run
chown -R $SUDO_USER:$SUDO_USER "$USER_HOME/Ac6"

# Chercher auto-install.xml à côté du setup.sh
AUTO_INSTALL_FILE="$SCRIPT_DIR/auto-install.xml"

if [ -f "$AUTO_INSTALL_FILE" ]; then
    echo "✅ auto-install.xml trouvé : $AUTO_INSTALL_FILE"
    chown $SUDO_USER:$SUDO_USER "$AUTO_INSTALL_FILE"
    chmod 644 "$AUTO_INSTALL_FILE"
    echo "⚙️ Installation automatique de SW4STM32..."
    su - $SUDO_USER -c "cd $USER_HOME/Ac6 && ./install_sw4stm32.run \"$AUTO_INSTALL_FILE\""
else
    echo "⚠️ auto-install.xml non trouvé à côté de setup.sh"
    echo "➡️  Lancement de l'installation manuelle de SW4STM32, veuillez répondre aux instructions dans le terminal..."
    su - $SUDO_USER -c "cd $USER_HOME/Ac6 && ./install_sw4stm32.run -c"
fi

# -------- 6️⃣ Finalisation --------
echo "♻️ Recharge du bashrc pour le PATH"
su - $SUDO_USER -c "source ~/.bashrc"

# -------- 7️⃣ Restauration backup SW4STM32 --------
echo "📦 Restauration du backup SW4STM32..."

USER_HOME=$(eval echo "~$SUDO_USER")
BACKUP_FILE="$SCRIPT_DIR/sw4stm32_full_backup.tar.gz"

if [ -f "$BACKUP_FILE" ]; then
    echo "✅ Backup trouvé : $BACKUP_FILE"
    echo "📂 Extraction dans $USER_HOME"
    tar xzf "$BACKUP_FILE" -C "$USER_HOME"
    chown -R $SUDO_USER:$SUDO_USER "$USER_HOME"
    echo "🎉 Backup restauré avec succès"
else
    echo "⚠️ Aucun backup SW4STM32 trouvé à côté de setup.sh"
    echo "➡️ Étape ignorée"
fi


echo "✅ Installation terminée !"
echo "🔍 Vérification GCC :"

# Version attendue
EXPECTED_GCC_VERSION="5.4.1"

# Exécute la commande dans le shell interactif, capture la sortie stdout
GCC_OUT=$(su - $SUDO_USER -l -c "bash -ic 'arm-none-eabi-gcc --version'" 2>/dev/null)

# Vérifie si la sortie contient "arm-none-eabi-gcc"
if echo "$GCC_OUT" | grep -q "arm-none-eabi-gcc"; then
    # Affiche la première ligne (la version)
    GCC_LINE=$(echo "$GCC_OUT" | head -n 1)
    echo "$GCC_LINE"

    # Vérifie si la version correspond à celle attendue
    if echo "$GCC_LINE" | grep -q "$EXPECTED_GCC_VERSION"; then
        echo "✅ GCC fonctionne correctement !"
        echo "🎯 Version correcte détectée : $EXPECTED_GCC_VERSION"
    else
        echo "⚠️  GCC non trouvé ou Version différente de GCC détectée, version attendue : $EXPECTED_GCC_VERSION !"
    fi
else
    echo "❌ GCC n'a pas été trouvé ou ne fonctionne pas."
fi

# -------- 8️⃣ Installation ESP-IDF v5.2.3 --------
echo "📥 Installation de l'ESP-IDF v5.2.3..."

USER_HOME=$(eval echo "~$SUDO_USER")
ESP_DIR="$USER_HOME/esp"
ESP_IDF_DIR="$ESP_DIR/esp-idf"

# Créer dossier esp
mkdir -p "$ESP_DIR"
chown -R $SUDO_USER:$SUDO_USER "$ESP_DIR"

if [[ ! -d "$ESP_IDF_DIR" ]]; then
    echo "🌐 Clonage du dépôt ESP-IDF v5.2.3..."
    su - $SUDO_USER -c "git clone -b v5.2.3 --recursive https://github.com/espressif/esp-idf.git '$ESP_IDF_DIR'"
else
    echo "ℹ️ Le dépôt esp-idf existe déjà, mise à jour..."
    su - $SUDO_USER -c "cd '$ESP_IDF_DIR' && git fetch --all && git checkout v5.2.3 && git submodule update --init --recursive"
fi

# Installer les dépendances ESP32
echo "⚙️ Exécution du script d'installation pour ESP32..."
su - $SUDO_USER -c "cd '$ESP_IDF_DIR' && ./install.sh all"

# Ajouter alias dans bashrc
BASHRC_ALIAS="alias get_idf='. \$HOME/esp/esp-idf/export.sh'"
if ! grep -Fxq "$BASHRC_ALIAS" /home/$SUDO_USER/.bashrc; then
    echo "📌 Ajout de l'alias get_idf dans .bashrc"
    echo "$BASHRC_ALIAS" >> /home/$SUDO_USER/.bashrc
fi

su - $SUDO_USER -c "source ~/.bashrc"

echo "✅ ESP-IDF installé et alias ajouté. Vous pouvez maintenant utilisez 'get_idf' pour activer l'environnement ESP-IDF."
echo "✅ Installation complète terminée !"
echo "➡️ Ouvrez un nouveau terminal ou 'source ~/.bashrc' pour commencer à utiliser GCC, SW4STM32 et ESP-IDF (En utilisant 'get_idf' dans un terminal pour charger l'environnement)."
