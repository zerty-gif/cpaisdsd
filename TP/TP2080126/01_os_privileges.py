"""
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
