"""
Démonstration guidée — os.system pour piloter des commandes (ls et ping)

Objectifs pédagogiques:
- Illustrer l'appel de commandes système depuis Python via `os.system`.
- Comprendre les avantages (simplicité) et limites (sécurité, parsing) de cette approche.

Étapes:
1) Demander à l'utilisateur un chemin de répertoire et exécuter `ls -l <chemin>`.
2) Demander une adresse IP/nom d'hôte et exécuter `ping -c 1 <cible>`.

Mises en garde importantes:
- `os.system` concatène des chaînes et invoque un shell: attention aux entrées non fiables.
- Pour du code production, préférez `subprocess.run()` avec liste d'arguments.

Sorties:
- Liste détaillée du répertoire fourni, puis résultat d'un ping (1 paquet) sur la cible.
"""
import os

VERBOSE = True

def log(msg: str) -> None:
	if VERBOSE:
		print(f"[VERBOSE] {msg}")

# Python demande à Debian d'afficher le nom du dossier
rep = input('Merci de saisir le chemin de votre repertoire \n')
log(f"Répertoire fourni: {rep}")
log(f"Exécution: ls -l {rep}")
os.system(f"ls -l {rep}")

# Python demande à Debian de tester la connexion
ip = input('Merci de saisir l\'adresse IP \n')
log(f"Cible fournie: {ip}")
print("Résultat du ping \n")
# -c 1 = count 1 packet
log(f"Exécution: ping -c 1 {ip}")
rc = os.system(f"ping -c 1 {ip}")
log(f"Code retour ping: {rc}")
