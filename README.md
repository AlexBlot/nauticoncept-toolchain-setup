# 🛠️ Nauticoncept Embedded Toolchain Setup

Ce dépôt contient un script d'automatisation permettant d'installer l'environnement de développement complet pour les projets embarqués de **Nauticoncept**. 

Il configure les chaînes de compilation (toolchains) nécessaires pour les cibles **STM32** (via System Workbench ou Makefile baremetal custom suivant les projets) et **ESP32** (via ESP-IDF).

---

## 📋 Prérequis

* **Système d'exploitation :** Distribution basée sur **Ubuntu** ou **Debian**.
* **Compatibilité testée :** * Ubuntu 24.04 LTS (Noble Numbat)
    * Debian 13 (Trixie)
* **État du système :** Il est fortement recommandé d'exécuter ce script sur une **fresh install** (installation propre) pour éviter les conflits de bibliothèques, notamment pour le support 32-bit nécessaire aux anciennes versions de GCC.
* **Droits :** Accès `sudo` requis pour l'installation des paquets système et de GCC dans `/opt`.

---

## 📂 Contenu du dépôt

Pour que l'installation soit réussie, assurez-vous que les fichiers suivants sont présents dans le même répertoire :

| Fichier | Description |
| :--- | :--- |
| `setup.sh` | Le script principal d'installation. |
| `sw4stm32_full_backup.tar.gz` | Archive contenant la configuration et les plugins de System Workbench. |
| `auto-install.xml` | Fichier de configuration pour l'installation automatisée de SW4STM32. |

---

## 🚀 Installation

1.  **Récupérer les fichiers** sur la machine cible.
2.  **Rendre le script exécutable** :
    ```bash
    chmod +x setup.sh
    ```
3.  **Lancer l'installation** :
    ```bash
    sudo ./setup.sh
    ```

---

## 🛠️ Outils installés

### 1. STM32 (Legacy Toolchain)
* **GCC ARM Embedded 5.4.1** : Installé dans `/opt/arm-gcc-5.4` et ajouté automatiquement à votre `PATH`.
* **System Workbench for STM32 (v2.3)** : Installé dans `~/Ac6`.
* **Support Multi-arch** : Installation des bibliothèques `i386` essentielles (libc6, libstdc++, ncurses5).
* **Restauration de configuration** : Décompression de votre sauvegarde personnalisée directement dans le dossier utilisateur.

### 2. ESP32 (Espressif)
* **ESP-IDF v5.2.3** : Cloné et configuré dans `~/esp/esp-idf`.
* **Outils de build** : Installation de `cmake`, `ninja-build`, `ccache` et des dépendances Python.

### 3. Utilitaires Système
* Installation de : `openocd`, `tmux`, `git`, `hexcurse`, `telnet`, `wget`.

---

## ⚙️ Utilisation après installation

Une fois le script terminé, vous devez **redémarrer votre terminal** ou exécuter `source ~/.bashrc`.

### Compilation STM32
L'outil `arm-none-eabi-gcc` est disponible directement dans votre terminal. Pour vérifier la version :
```bash
arm-none-eabi-gcc --version
```

### Compilation ESP32
Pour ne pas encombrer votre environnement par défaut, l'outil ESP-IDF doit être chargé manuellement via un alias :
```bash
get_idf
```
Une fois cette commande lancée, vous pouvez utiliser idf.py pour compiler vos projets.

[!IMPORTANT] Note sur la sécurité : Ce script modifie votre fichier .bashrc et installe des paquets via dpkg --add-architecture. Si vous utilisez déjà une version différente de GCC ARM ou d'ESP-IDF, vérifiez vos variables d'environnement après l'installation.