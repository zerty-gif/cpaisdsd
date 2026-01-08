"""
Connexion SSH avec Netmiko — démonstration pas à pas

Objectifs pédagogiques:
- Décrire la structure d'un dictionnaire d'équipement pour Netmiko.
- Expliquer l'intérêt du gestionnaire de contexte `with` pour fermer proprement la session.
- Montrer l'envoi d'une commande de consultation et l'affichage du résultat.

Pré-requis:
- Bibliothèque `netmiko` installée (cf. requirements.txt).
- Accès réseau vers l'équipement, identifiants corrects.

Étapes de l'exécution:
1) Préparation du dictionnaire `router_core` (type, hôte, identifiants).
2) Tentative de connexion SSH via `ConnectHandler` (verbose: messages d'étape).
3) Envoi de `show ip interface brief` et affichage de la sortie.
4) Fermeture automatique de la session en sortie de bloc `with`.
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
log(f"Détails (sans mot de passe): device_type={router_core['device_type']}, host={router_core['host']}")

# Utilisation du gestionnaire de contexte (with) pour gérer la fermeture automatique
try:
    with ConnectHandler(**router_core) as net_connect:
        print(f"Connecté à {router_core['host']}")
        log("Connexion établie, envoi de la commande 'show ip interface brief'")
        output = net_connect.send_command("show ip interface brief")
        print(output)
        log("Commande exécutée, fermeture de session en fin de bloc 'with'")
except Exception as e:
    print(f"ERREUR: Impossible d'établir la connexion à {router_core['host']}: {e}")
    log("Vérifiez la reachabilité, le device_type et les identifiants.")

