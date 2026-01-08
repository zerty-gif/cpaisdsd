"""
Slide 5: Utilisation de os.system
Interaction directe avec le terminal (ls et ping).
"""
import os

# Python demande à Debian d'afficher le nom du dossier
rep = input('Merci de saisir le chemin de votre repertoire \n')
os.system(f"ls -l {rep}")

# Python demande à Debian de tester la connexion
ip = input('Merci de saisir l\'adresse IP \n')
print("Résultat du ping \n")
# -c 1 = count 1 packet
os.system(f"ping -c 1 {ip}")
