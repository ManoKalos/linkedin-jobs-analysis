Analyse des Emplois LinkedIn
Application Streamlit pour visualiser les tendances des offres d'emploi LinkedIn par industrie, taille d'entreprise, type de présence et type d'emploi. Cette application s'exécute localement et se connecte à une base Snowflake.
Prérequis

Python 3.8+
Compte Snowflake avec accès à la base LINKEDIN (schéma PUBLIC)
Les tables Snowflake suivantes doivent être remplies : top_jobs_by_industry, jobs_by_company_size, jobs_by_presence, jobs_by_employment_type

Installation

Cloner le dépôt :
git clone https://github.com/ManoKalos/linkedin-jobs-analysis.git
cd linkedin-jobs-analysis


Créer un environnement virtuel :
python -m venv venv
source venv/bin/activate  # Windows : venv\Scripts\activate


Installer les dépendances :
pip install -r requirements.txt



Exécution Locale

Lancez l'application :
streamlit run visualiser.py


Ouvrez votre navigateur à l'adresse http://localhost:8501.

Saisissez vos identifiants Snowflake dans la barre latérale de l'application :

Utilisateur
Mot de passe
Compte
Entrepôt



Structure du Projet

visualiser.py : Application Streamlit principale affichant quatre graphiques.
requirements.txt : Dépendances Python (Streamlit, Snowflake, Pandas, Plotly).
.gitignore : Exclut les fichiers sensibles comme les environnements virtuels.
README.md : Ce fichier, expliquant comment installer et exécuter l'application.

Dépannage

Graphiques vides :

Connectez-vous à Snowflake et vérifiez les tables :SELECT * FROM LINKEDIN.PUBLIC.top_jobs_by_industry LIMIT 10;
SELECT * FROM LINKEDIN.PUBLIC.jobs_by_company_size LIMIT 10;
SELECT * FROM LINKEDIN.PUBLIC.jobs_by_presence LIMIT 10;
SELECT * FROM LINKEDIN.PUBLIC.jobs_by_employment_type LIMIT 10;


Si les tables sont vides, assurez-vous que le script Snowflake a été exécuté correctement.


Erreur de connexion Snowflake :

Vérifiez que les identifiants saisis dans l'interface sont corrects.
Testez la connexion manuellement :import snowflake.connector
conn = snowflake.connector.connect(
    user="votre_utilisateur",
    password="votre_mot_de_passe",
    account="votre_compte",
    warehouse="votre_entrepot",
    database="LINKEDIN",
    schema="PUBLIC"
)
print(conn.cursor().execute("SELECT CURRENT_VERSION()").fetchone())




Autres problèmes :

Contactez le propriétaire du dépôt via une issue GitHub ou vérifiez les logs dans la console.



Sécurité

Les identifiants Snowflake sont saisis directement dans l'interface Streamlit et ne sont pas stockés sur le disque.
Assurez-vous de ne pas partager vos identifiants dans des environnements non sécurisés.

