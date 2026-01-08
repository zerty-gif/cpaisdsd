"""
Slide 20 - Exercice 2
Boucle sur une liste d'IPs avec gestion d'erreurs.
"""
from netmiko import ConnectHandler
from netmiko.exceptions import NetmikoTimeoutException

parc_reseau = ["192.168.10.11", "192.168.10.172", "192.168.10.133"]

username = "admin"
password = "admin"

for ip in parc_reseau:
    print(f"\n--- Tentative sur {ip} ---")
    
    device = {
        'device_type': 'cisco_ios',
        'host': ip,
        'username': username,
        'password': password,
    }

    try:
        with ConnectHandler(**device) as net_connect:
            print(f"Connexion réussie à {ip}")
            # On pourrait ajouter des commandes ici
            
    except NetmikoTimeoutException:
        print("Échec de connexion (Timeout)")
    except Exception as e:
        print(f"Autre erreur: {e}")
