"""
Exercice guidé — Connexion SSH interactive et recherche d'uptime

Objectifs:
- Recueillir les paramètres de connexion auprès de l'utilisateur (ou .env).
- Établir une session SSH avec Netmiko.
- Extraire l'information d'uptime dans la sortie de `show version`.

Conseils pédagogiques:
- Ne jamais afficher le mot de passe en clair.
- Indiquer les étapes à l'utilisateur (verbosité) pour qu'il suive le déroulé.
- Utiliser .env pour éviter de saisir les credentials à chaque fois.
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

# 1. Demande les infos à l'utilisateur (ou .env)
host = os.getenv("NETMIKO_HOST") or input("Adresse IP: ").strip()
username = os.getenv("NETMIKO_USER") or input("Login: ").strip()
password = os.getenv("NETMIKO_PASS") or getpass.getpass("Mot de passe: ")
log(f"Cible: {host}, Utilisateur: {username}")

device = {
    'device_type': 'cisco_ios',
    'host': host,
    'username': username,
    'password': password,
}

try:
    print(f"Connexion à {host}...")
    log("Ouverture de session SSH...")
    with ConnectHandler(**device) as net_connect:
        # 2. Récupère la version (qui contient souvent l'uptime)
        log("Envoi de 'show version' et analyse de la sortie...")
        output = net_connect.send_command("show version")
        
        # 3. Cherche et affiche l'uptime
        found = False
        for line in output.splitlines():
            if "uptime" in line.lower():
                print(f"Succès ! {line}")
                found = True
                break
        if not found:
            print("Uptime introuvable dans la sortie.")

except Exception as e:
    print(f"Erreur lors de la connexion : {e}")
