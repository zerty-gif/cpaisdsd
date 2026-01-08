import os


def verif():
    if os.getuid() == 0:
        print("Privilège OK")
    else:
        print("Ce script nécessite les droits root")


def main():
    verif()
    os.system("ls -la")
    ip = input("ping ip : ").strip()
    if ip:
        rc = os.system("ping -c 4 " + ip + " > /dev/null 2>&1")
        if rc != 0:
            print(f"Échec du ping sur {ip}, code {rc}")
        else:
            print(f"Ping réussi sur {ip}")



if __name__ == "__main__":
    main()
