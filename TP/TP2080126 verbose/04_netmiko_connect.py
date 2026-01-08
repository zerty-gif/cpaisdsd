"""
Slide 10 & 11: Connexion Netmiko Basique
Démonstration de la connexion SSH et envoi de commande.
"""
from netmiko import ConnectHandler

# Définition de l'équipement
# NOTE: Modifiez l'IP pour correspondre à votre lab
router_core = {
    "device_type": "cisco_ios",
    "host": "172.16.86.160",
    "username": "admin",
    "password": "admin",
}

print(f"Connexion en cours à {router_core['host']}...")

# Utilisation du gestionnaire de contexte (with) pour gérer la fermeture automatique
with ConnectHandler(**router_core) as net_connect:
    print(f"Connecté à {router_core['host']}")
    
    # Envoi d'une commande de consultation
    output = net_connect.send_command("show ip interface brief")
    print(output)

