"""
Exercice — Prompt utilisateur et extraction de la version logicielle

Objectifs:
- Demander à l'utilisateur les paramètres SSH (ou utiliser .env).
- Exécuter `show version`.
- Extraire une ligne contenant "Version" et afficher un extrait pertinent.

Approche pédagogique:
- Rendre le déroulé explicite avec des messages verboses.
- Prévenir l'utilisateur en cas d'absence de correspondance.
- Utiliser .env pour éviter de retaper les credentials.
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

ip_addr = os.getenv("NETMIKO_HOST") or input("Entrez l'adresse IP du routeur : ").strip()
user = os.getenv("NETMIKO_USER") or input("Nom d'utilisateur: ").strip()
pwd = os.getenv("NETMIKO_PASS") or getpass.getpass("Mot de passe SSH : ")
log(f"Cible: {ip_addr}, Utilisateur: {user}")

device = {
    'device_type': 'cisco_ios',
    'host': ip_addr,
    'username': user,
    'password': pwd,
}

print(f"Connexion à {ip_addr} en cours...")
log("Ouverture de session SSH et exécution de 'show version'...")

try:
    with ConnectHandler(**device) as net_connect:
        # Récupération de la version
        output = net_connect.send_command("show version")
        
        # Parsing simple pour trouver la ligne de version
        found = False
        for line in output.splitlines():
            if "Version" in line:
                print(f"La version: {line.strip()}")
                found = True
                break
        
        if not found:
            print("Version non trouvée dans la sortie, voici les 5 premières lignes:")
            print("\n".join(output.splitlines()[:5]))
            log("Ajustez le parsing selon votre OS/network OS si besoin.")

except Exception as e:
    print(f"Erreur: {e}")
