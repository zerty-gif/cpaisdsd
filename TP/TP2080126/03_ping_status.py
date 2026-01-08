"""
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
