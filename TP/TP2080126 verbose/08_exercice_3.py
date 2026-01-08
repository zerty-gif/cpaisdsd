"""
Slide 21 - Exercice 3
Input utilisateur et affichage de la version.
"""
from netmiko import ConnectHandler
import getpass

ip_addr = input("Entrez l'adresse IP du routeur : ")
user = input("Nom d'utilisateur: ")
pwd = getpass.getpass("Mot de passe SSH : ")

device = {
    'device_type': 'cisco_ios',
    'host': ip_addr,
    'username': user,
    'password': pwd,
}

print(f"Connexion à {ip_addr} en cours...")

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

except Exception as e:
    print(f"Erreur: {e}")
