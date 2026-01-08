"""
Exercice guidé — Connexion SSH interactive et recherche d'uptime

Objectifs:
- Recueillir les paramètres de connexion auprès de l'utilisateur.
- Établir une session SSH avec Netmiko.
- Extraire l'information d'uptime dans la sortie de `show version`.

Conseils pédagogiques:
- Ne jamais afficher le mot de passe en clair.
- Indiquer les étapes à l'utilisateur (verbosité) pour qu'il suive le déroulé.
"""
from netmiko import ConnectHandler
import getpass

VERBOSE = True

def log(msg: str) -> None:
    if VERBOSE:
        print(f"[VERBOSE] {msg}")

# 1. Demande les infos à l'utilisateur
host = input("Adresse IP: ")
username = input("Login: ")
password = getpass.getpass("Mot de passe: ")
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
