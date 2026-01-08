import os
import subprocess
import ipaddress


def verif():
    if os.getuid() == 0:
        print("Privilège OK")
    else:
        print("Ce script nécessite les droits root")


def list_dir():
    try:
        subprocess.run(["ls", "-la"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"ls a échoué: {e}")


def ping_ip(ip_str: str) -> int:
    try:
        # Valide IPv4 ou IPv6
        ipaddress.ip_address(ip_str)
    except ValueError:
        print("Adresse IP invalide")
        return 1

    try:
        result = subprocess.run(["ping", "-c", "4", ip_str], check=False)
        return result.returncode
    except FileNotFoundError:
        print("Commande 'ping' introuvable")
        return 127


if __name__ == "__main__":
    verif()
    list_dir()
    ip = input("ping ip : ").strip()
    rc = ping_ip(ip)
    if rc != 0:
        print(f"Échec du ping, code {rc}")
    else:
        print("Ping réussi")

# Fin du script

