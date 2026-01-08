import os

# This dictionary contains the filename as the key and the script content as the value
files_to_create = {
    # ---------------------------------------------------------
    # PART 1: MODULE OS
    # ---------------------------------------------------------
    "01_os_privileges.py": '''"""
Slide 4: Vérification des privilèges
Ce script vérifie si l'utilisateur est root (UID 0).
"""
import os

def verifier_privileges():
    # On vérifie si l'utilisateur est Root (UID 0)
    if os.getuid() != 0:
        print("ERREUR: Ce script doit être lancé avec 'sudo'.")
    else:
        print("Privilèges confirmés. Lancement du diagnostic...")

if __name__ == "__main__":
    verifier_privileges()
''',
    "02_os_system_demo.py": '''"""
Slide 5: Utilisation de os.system
Interaction directe avec le terminal (ls et ping).
"""
import os

# Python demande à Debian d'afficher le nom du dossier
rep = input('Merci de saisir le chemin de votre repertoire \\n')
os.system(f"ls -l {rep}")

# Python demande à Debian de tester la connexion
ip = input('Merci de saisir l\\'adresse IP \\n')
print("Résultat du ping \\n")
# -c 1 = count 1 packet
os.system(f"ping -c 1 {ip}")
''',
    "03_ping_status.py": '''"""
Slide 7: Code de retour
Analyse si la commande a réussi (0) ou échoué (!= 0).
"""
import os

print("Test de connectivité vers 8.8.8.8...")
# > /dev/null cache la sortie, 2>&1 cache les erreurs (adapté pour Linux)
r = os.system("ping -c 1 8.8.8.8 > /dev/null 2>&1")

if r == 0:
    print("Joignable (Succès)")
else:
    print("Injoignable (Échec)")
''',
    # ---------------------------------------------------------
    # PART 2: NETMIKO BASIC
    # ---------------------------------------------------------
    "04_netmiko_connect.py": '''"""
Slide 10 & 11: Connexion Netmiko Basique
Démonstration de la connexion SSH et envoi de commande.
"""
from netmiko import ConnectHandler

# Définition de l'équipement
# NOTE: Modifiez l'IP pour correspondre à votre lab
router_core = {
    "device_type": "cisco_ios",
    "host": "192.168.10.12",
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
''',
    # ---------------------------------------------------------
    # PART 3: GESTION DES ERREURS
    # ---------------------------------------------------------
    "05_netmiko_errors.py": '''"""
Slide 15: Gestion avancée des erreurs
Try/Except pour Timeout et Authentification.
"""
from netmiko import ConnectHandler
from netmiko.exceptions import NetmikoTimeoutException, NetmikoAuthenticationException

cisco_router = {
    'device_type': 'cisco_ios',
    'host': '192.168.10.122', # IP erronée pour tester le timeout
    'username': 'admin',
    'password': 'admin',
}

try:
    print(f"Connexion à {cisco_router['host']}...")
    connection = ConnectHandler(**cisco_router)
    output = connection.send_command("show ip interface brief")
    print("Résultat : \\n", output)
    connection.disconnect()

# GESTION DES ERREURS SPÉCIFIQUES
except NetmikoTimeoutException:
    print(f" ERREUR: L'équipement {cisco_router['host']} est injoignable (Timeout).")
except NetmikoAuthenticationException:
    print(f" ERREUR: Échec d'authentification sur {cisco_router['host']} (User/Pass incorrect).")
except Exception as e:
    print(f" ERREUR INATTENDUE: {e}")
''',
    # ---------------------------------------------------------
    # PART 4: EXERCICES
    # ---------------------------------------------------------
    "06_exercice_1.py": '''"""
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
''',
    "07_exercice_2.py": '''"""
Slide 20 - Exercice 2
Boucle sur une liste d'IPs avec gestion d'erreurs.
"""
from netmiko import ConnectHandler
from netmiko.exceptions import NetmikoTimeoutException

parc_reseau = ["192.168.10.11", "192.168.10.172", "192.168.10.133"]

username = "admin"
password = "admin"

for ip in parc_reseau:
    print(f"\\n--- Tentative sur {ip} ---")
    
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
''',
    "08_exercice_3.py": '''"""
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
            print("\\n".join(output.splitlines()[:5]))

except Exception as e:
    print(f"Erreur: {e}")
''',
}

# Loop through the dictionary and create the files
for filename, content in files_to_create.items():
    try:
        with open(filename, "w", encoding="utf-8") as f:
            f.write(content)
        print(f"[OK] Fichier créé : {filename}")
    except Exception as e:
        print(f"[ERREUR] Impossible de créer {filename} : {e}")

print("\n--- Terminée ! Vous avez maintenant 8 scripts Python prêts à l'emploi. ---")
