"""
Exercice — Parcours d'un parc d'IPs avec gestion d'erreurs

Objectifs:
- Itérer sur une liste d'équipements et tenter une connexion SSH.
- Illustrer la gestion des erreurs (timeout, autres exceptions).
- Fournir une verbosité utile et un bref récapitulatif final.
- Utiliser .env pour les credentials communs.
"""
import os
import getpass
from pathlib import Path
from netmiko import ConnectHandler
from netmiko.exceptions import NetmikoTimeoutException
from dotenv import load_dotenv

# Charge le fichier .env s'il existe dans le même répertoire que ce script
script_dir = Path(__file__).parent
dotenv_path = script_dir / ".env"
if dotenv_path.exists():
    load_dotenv(dotenv_path)
    print(f"[INFO] Fichier .env chargé depuis {dotenv_path}")

parc_reseau = ["172.16.86.160", "172.16.86.161", "172.16.86.162"]

# Credentials depuis .env ou prompts
username = os.getenv("NETMIKO_USER") or input("Nom d'utilisateur: ").strip() or "admin"
password = os.getenv("NETMIKO_PASS") or getpass.getpass("Mot de passe: ") or "admin"

VERBOSE = True

def log(msg: str) -> None:
    if VERBOSE:
        print(f"[VERBOSE] {msg}")

succès = []
échecs = []

for ip in parc_reseau:
    print(f"\n--- Tentative sur {ip} ---")
    
    device = {
        'device_type': 'cisco_ios',
        'host': ip,
        'username': username,
        'password': password,
    }

    try:
        log("Tentative d'ouverture de session SSH...")
        with ConnectHandler(**device) as net_connect:
            print(f"Connexion réussie à {ip}")
            succès.append(ip)
            # On pourrait ajouter des commandes ici
            
    except NetmikoTimeoutException:
        print("Échec de connexion (Timeout)")
        échecs.append((ip, "timeout"))
    except Exception as e:
        print(f"Autre erreur: {e}")
        échecs.append((ip, str(e)))

print("\n=== Récapitulatif ===")
print(f"Succès: {len(succès)} -> {', '.join(succès) if succès else 'aucun'}")
print(f"Échecs: {len(échecs)}")
for ip, err in échecs:
    print(f" - {ip}: {err}")
