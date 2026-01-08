"""
Connexion SSH Netmiko — variante commentée et verbosée

But:
- Reprendre la démonstration de connexion Netmiko avec davantage de commentaires et de sorties.

Points clés expliqués:
- Rôle du dictionnaire d'équipement.
- Ouverture et fermeture automatique de session avec `with`.
- Envoi d'une commande de show et affichage de la sortie.
"""
from netmiko import ConnectHandler

VERBOSE = True

def log(msg: str) -> None:
    if VERBOSE:
        print(f"[VERBOSE] {msg}")

# Définition de l'équipement
# NOTE: Modifiez l'IP pour correspondre à votre lab
router_core = {
    "device_type": "cisco_ios",
    "host": "172.16.86.160",
    "username": "admin",
    "password": "admin",
}

print(f"Connexion en cours à {router_core['host']}...")
log("Tentative d'ouverture de session SSH...")





# Utilisation du gestionnaire de contexte (with) pour gérer la fermeture automatique
try:
    with ConnectHandler(**router_core) as net_connect:
        print(f"Connecté à {router_core['host']}")
        log("Envoi de la commande de consultation...")
        output = net_connect.send_command("show ip interface brief")
        print(output)
        log("Commande terminée. La fermeture aura lieu automatiquement.")
except Exception as e:
    print(f"ERREUR: Échec de connexion à {router_core['host']}: {e}")
    log("Conseils: tester ping/SSH, vérifier 'device_type', credentials, ACL.")

