"""
Connexion SSH avec Netmiko — démonstration pas à pas

Objectifs pédagogiques:
- Décrire la structure d'un dictionnaire d'équipement pour Netmiko.
- Expliquer l'intérêt du gestionnaire de contexte `with` pour fermer proprement la session.
- Montrer l'envoi d'une commande de consultation et l'affichage du résultat.

Pré-requis:
- Bibliothèque `netmiko` installée (cf. requirements.txt).
- Accès réseau vers l'équipement, identifiants corrects.
- Fichier .env optionnel avec NETMIKO_HOST, NETMIKO_USER, NETMIKO_PASS, etc.

Étapes de l'exécution:
1) Chargement des paramètres depuis .env (si présent) ou prompts interactifs.
2) Préparation du dictionnaire `router_core` (type, hôte, identifiants).
3) Tentative de connexion SSH via `ConnectHandler` (verbose: messages d'étape).
4) Envoi de `show ip interface brief` et affichage de la sortie.
5) Fermeture automatique de la session en sortie de bloc `with`.
"""
import os
import getpass
from pathlib import Path
from netmiko import ConnectHandler
from dotenv import load_dotenv

# Charge le fichier .env s'il existe dans le même répertoire que ce script
script_dir = Path(__file__).parent
dotenv_path = script_dir / ".env"
if dotenv_path.exists():
    load_dotenv(dotenv_path)
    print(f"[INFO] Fichier .env chargé depuis {dotenv_path}")

VERBOSE = True

def log(msg: str) -> None:
    if VERBOSE:
        print(f"[VERBOSE] {msg}")

# Récupération des paramètres via ENV ou prompts
host = os.getenv("NETMIKO_HOST") or input("Adresse IP/DNS du routeur: ").strip() or "172.16.86.161"
username = os.getenv("NETMIKO_USER") or input("Nom d'utilisateur: ").strip() or "admin"
password = os.getenv("NETMIKO_PASS") or getpass.getpass("Mot de passe: ") or "admin"
secret = os.getenv("NETMIKO_SECRET") or ""
port_env = os.getenv("NETMIKO_PORT")
try:
    port = int(port_env) if port_env else 22
except ValueError:
    port = 22

# Définition de l'équipement
router_core = {
    "device_type": "cisco_ios",
    "host": host,
    "username": username,
    "password": password,
    "port": port,
    "secret": secret,
    "timeout": 10,
}

print(f"Connexion en cours à {router_core['host']}...")
log(f"Détails (sans mot de passe): device_type={router_core['device_type']}, host={router_core['host']}, port={router_core['port']}")

# Utilisation du gestionnaire de contexte (with) pour gérer la fermeture automatique
try:
    with ConnectHandler(**router_core, session_log="netmiko_session.log") as net_connect:
        print(f"Connecté à {router_core['host']}")
        log("Connexion établie, envoi de la commande 'show ip interface brief'")
        output = net_connect.send_command("show ip interface brief")
        print(output)
        log("Commande exécutée, fermeture de session en fin de bloc 'with'")
except Exception as e:
    print(f"ERREUR: Impossible d'établir la connexion à {router_core['host']}: {e}")
    log("Vérifiez la reachabilité, le device_type et les identifiants.")

