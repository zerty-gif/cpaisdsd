"""
Analyse des codes de retour — ping et interprétation (0 = succès)

Objectifs pédagogiques:
- Rappeler que sous Unix, un code de retour 0 signifie succès, != 0 signifie échec.
- Montrer comment capturer et afficher ce code avec `os.system`.

Démonstration:
1) Lance `ping -c 1 8.8.8.8` en redirigeant sortie et erreurs vers /dev/null.
2) Récupère le code de retour puis affiche un diagnostic explicite.
"""
import os

VERBOSE = True

def log(msg: str) -> None:
    if VERBOSE:
        print(f"[VERBOSE] {msg}")

print("Test de connectivité vers 8.8.8.8...")
log("Exécution: ping -c 1 8.8.8.8 > /dev/null 2>&1")
# > /dev/null cache la sortie, 2>&1 cache les erreurs (adapté pour Linux)
r = os.system("ping -c 1 8.8.8.8 > /dev/null 2>&1")
log(f"Code retour obtenu: {r}")

if r == 0:
    print("Joignable (Succès)")
    log("Interprétation: 0 => la commande a réussi")
else:
    print("Injoignable (Échec)")
    log("Interprétation: != 0 => la commande a échoué")
