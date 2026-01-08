"""
Connexion SSH Netmiko — variante commentée et verbosée

But:
- Reprendre la démonstration de connexion Netmiko avec davantage de commentaires et de sorties.

Nouveautés pédagogiques (configurable):
- Paramètres pris depuis le fichier .env (situé dans le même répertoire) si présent
- Variables d'environnement: NETMIKO_HOST, NETMIKO_USER, NETMIKO_PASS, NETMIKO_SECRET, NETMIKO_PORT
- Sinon, demande interactive (prompts) pour l'hôte et les identifiants.
- Journal de session Netmiko activé: "netmiko_session.log" pour le débogage.

Points clés expliqués:
- Rôle du dictionnaire d'équipement.
- Ouverture et fermeture automatique de session avec `with`.
- Envoi d'une commande de show et affichage de la sortie.
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
host = os.getenv("NETMIKO_HOST") or input("Adresse IP/DNS du routeur: ").strip()
username = os.getenv("NETMIKO_USER") or input("Nom d'utilisateur: ").strip()
password = os.getenv("NETMIKO_PASS") or getpass.getpass("Mot de passe: ")
secret = os.getenv("NETMIKO_SECRET") or ""
port_env = os.getenv("NETMIKO_PORT")
try:
    port = int(port_env) if port_env else 22
except ValueError:
    port = 22

# Définition de l'équipement
router_core = { # type: ignore
    "device_type": "cisco_ios",
    "host": host,
    "username": username,
    "password": password,
    "secret": secret,
    "port": port,
    "timeout": 10,
}

print(f"Connexion en cours à {router_core['host']}...")
log(f"Tentative d'ouverture de session SSH vers {router_core['host']}:{router_core['port']} avec l'utilisateur {router_core['username']}...")





# Utilisation du gestionnaire de contexte (with) pour gérer la fermeture automatique
try:
    # Journal de session détaillé pour le débogage Netmiko
    with ConnectHandler(**router_core, session_log="netmiko_session.log") as net_connect:
        print(f"Connecté à {router_core['host']}")
        log("Envoi de la commande de consultation...")
        output = net_connect.send_command("show ip interface brief")
        print(output)
        log("Commande terminée. La fermeture aura lieu automatiquement.")
except Exception as e:
    print(f"ERREUR: Échec de connexion à {router_core['host']}: {e}")
    log("Conseils: tester ping/SSH, vérifier 'device_type', credentials, ACL.")

