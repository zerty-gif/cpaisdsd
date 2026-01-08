"""
Introduction pédagogique — Vérification des privilèges (UID root)

Objectifs pédagogiques:
- Comprendre la notion d'UID (User ID) sous Linux et l'UID 0 pour root.
- Savoir détecter dans un script Python si l'on dispose des privilèges administrateur.
- Apprendre à fournir des messages clairs à l'utilisateur final.

Pré-requis:
- Environnement Linux/Unix, Python 3.
- Notions de base sur les permissions et l'exécution avec sudo.

Ce que fait ce script:
1) Récupère l'UID du processus courant via `os.getuid()`.
2) Compare l'UID à 0 (root) et affiche un message d'état détaillé.

Sortie attendue:
- Message indiquant si l'utilisateur est root ou s'il doit relancer avec sudo.

Bonnes pratiques:
- Toujours expliquer la cause et la solution proposée (ici: utiliser sudo).
"""
import os

VERBOSE = True

def log(msg: str) -> None:
    if VERBOSE:
        print(f"[VERBOSE] {msg}")

def verifier_privileges():
    """Vérifie si l'utilisateur courant est root (UID 0) et affiche un message explicite."""
    uid = os.getuid()
    log(f"UID détecté: {uid}")
    # On vérifie si l'utilisateur est Root (UID 0)
    if uid != 0:
        print("ERREUR: Ce script doit être lancé avec 'sudo'.")
        log("Conseil: relancez avec 'sudo python3 <script.py>'")
    else:
        print("Privilèges confirmés. Lancement du diagnostic...")
        log("Vous disposez des droits nécessaires pour les opérations sensibles.")

if __name__ == "__main__":
    verifier_privileges()
