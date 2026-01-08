"""
Gestion des erreurs Netmiko — Timeout, Authentification et cas inattendus

Objectifs pédagogiques:
- Illustrer l'usage de `try/except` avec des exceptions spécifiques Netmiko.
- Apprendre à fournir des messages d'erreur utiles et actionnables.

Scénario:
- Test de connexion avec gestion des erreurs de timeout et d'authentification.
- Affichage clair du type d'erreur rencontré.
- Credentials depuis .env ou prompts interactifs.
"""
import os
import getpass
from pathlib import Path
from netmiko import ConnectHandler
from netmiko.exceptions import NetmikoTimeoutException, NetmikoAuthenticationException
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

cisco_router = {
    'device_type': 'cisco_ios',
    'host': host,
    'username': username,
    'password': password,
}

try:
    print(f"Connexion à {cisco_router['host']}...")
    log("Ouverture de session SSH via Netmiko...")
    connection = ConnectHandler(**cisco_router)
    log("Session établie, envoi de 'show ip interface brief'")
    output = connection.send_command("show ip interface brief")
    print("Résultat : \n", output)
    log("Fermeture explicite de la session")
    connection.disconnect()

# GESTION DES ERREURS SPÉCIFIQUES
except NetmikoTimeoutException:
    print(f" ERREUR: L'équipement {cisco_router['host']} est injoignable (Timeout).")
    log("Causes possibles: IP incorrecte, route manquante, filtre, port SSH fermé.")
except NetmikoAuthenticationException:
    print(f" ERREUR: Échec d'authentification sur {cisco_router['host']} (User/Pass incorrect).")
    log("Vérifiez le couple login/mot de passe et les privilèges.")
except Exception as e:
    print(f" ERREUR INATTENDUE: {e}")
    log("Collectez la trace complète si nécessaire et isolez la cause.")
