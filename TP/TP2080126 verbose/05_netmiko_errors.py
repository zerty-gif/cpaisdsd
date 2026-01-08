"""
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
    print("Résultat : \n", output)
    connection.disconnect()

# GESTION DES ERREURS SPÉCIFIQUES
except NetmikoTimeoutException:
    print(f" ERREUR: L'équipement {cisco_router['host']} est injoignable (Timeout).")
except NetmikoAuthenticationException:
    print(f" ERREUR: Échec d'authentification sur {cisco_router['host']} (User/Pass incorrect).")
except Exception as e:
    print(f" ERREUR INATTENDUE: {e}")
