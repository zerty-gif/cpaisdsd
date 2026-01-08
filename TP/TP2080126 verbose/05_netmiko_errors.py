"""
Gestion des erreurs Netmiko — Timeout, Authentification et cas inattendus

Objectifs pédagogiques:
- Illustrer l'usage de `try/except` avec des exceptions spécifiques Netmiko.
- Apprendre à fournir des messages d'erreur utiles et actionnables.

Scénario:
- Hôte volontairement erroné pour déclencher un timeout.
- Affichage clair du type d'erreur rencontré.
"""
from netmiko import ConnectHandler
from netmiko.exceptions import NetmikoTimeoutException, NetmikoAuthenticationException

cisco_router = {
    'device_type': 'cisco_ios',
    'host': '192.168.10.122', # IP erronée pour tester le timeout
    'username': 'admin',
    'password': 'admin',
}

VERBOSE = True

def log(msg: str) -> None:
    if VERBOSE:
        print(f"[VERBOSE] {msg}")

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
