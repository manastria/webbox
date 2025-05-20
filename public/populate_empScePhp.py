import random
import mysql.connector
from faker import Faker

# Configuration de la connexion MySQL
config = {
    'host': '127.0.0.1',     # ou l'IP du conteneur Docker
    'port': 3306,            # port mappé depuis le conteneur
    'user': 'etudiant',
    'password': 'etudiant',  # à adapter
    'database': 'empScePhp'
}

fake = Faker('fr_FR')  # Génération réaliste de données en français

# Services fictifs
services = [
    ('DEV', 'Développement'),
    ('HRH', 'Ressources humaines'),
    ('COM', 'Communication'),
    ('FIN', 'Finance'),
    ('DSI', 'Informatique'),
    ('MKT', 'Marketing')
]

def insert_services(cursor):
    for code, name in services:
        cursor.execute(
            "INSERT INTO service (code, designation) VALUES (%s, %s)",
            (code, name)
        )

def generate_employe_data(code_services, nb=20):
    employes = []
    for _ in range(nb):
        matricule = ''.join(random.choices('0123456789', k=4))
        nom = fake.last_name().upper()
        prenom = fake.first_name()
        cadre = random.choice(['O', 'N'])  # O = oui, N = non
        service = random.choice(code_services)
        employes.append((matricule, nom, prenom, cadre, service))
    return employes

def insert_employes(cursor, employes):
    for e in employes:
        cursor.execute(
            "INSERT INTO employe (matricule, nom, prenom, cadre, service) VALUES (%s, %s, %s, %s, %s)",
            e
        )

def main():
    try:
        connection = mysql.connector.connect(**config)
        cursor = connection.cursor()

        print("[+] Insertion des services...")
        insert_services(cursor)

        print("[+] Génération des employés...")
        employes = generate_employe_data([s[0] for s in services], nb=30)

        print("[+] Insertion des employés...")
        insert_employes(cursor, employes)

        connection.commit()
        print("[✓] Données insérées avec succès.")
    except mysql.connector.Error as err:
        print(f"[!] Erreur : {err}")
    finally:
        if cursor:
            cursor.close()
        if connection:
            connection.close()

if __name__ == "__main__":
    main()
