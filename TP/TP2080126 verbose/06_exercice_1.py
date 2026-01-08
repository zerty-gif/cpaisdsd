"""
Slide 18 - Exercice 1
Script interactif : demande infos, connecte SSH, affiche uptime.
"""
from netmiko import ConnectHandler
import getpass

# 1. Demande les infos à l'utilisateur
host = input("Adresse IP: ")
username = input("Login: ")
password = getpass.getpass("Mot de passe: ")

device = {
    'device_type': 'cisco_ios',
    'host': host,
    'username': username,
    'password': password,
}

try:
    print(f"Connexion à {host}...")
    with ConnectHandler(**device) as net_connect:
        # 2. Récupère la version (qui contient souvent l'uptime)
        output = net_connect.send_command("show version")
        
        # 3. Cherche et affiche l'uptime
        for line in output.splitlines():
            if "uptime" in line.lower():
                print(f"Succès ! {line}")

except Exception as e:
    print(f"Erreur lors de la connexion : {e}")
