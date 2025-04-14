# Analyse des Emplois LinkedIn

Application Streamlit pour visualiser les tendances des offres d'emploi LinkedIn par industrie, taille d'entreprise, type de présence et type d'emploi. Cette application s'exécute localement et se connecte à une base Snowflake.

## Prérequis

- Python 3.8+
- Compte Snowflake avec accès à la base `LINKEDIN` (schéma `PUBLIC`)
- Les tables Snowflake suivantes doivent être remplies : `top_jobs_by_industry`, `jobs_by_company_size`, `jobs_by_presence`, `jobs_by_employment_type`

## Installation

1. **Cloner le dépôt** :
   ```bash
   git clone https://github.com/ManoKalos/linkedin-jobs-analysis.git
   cd linkedin-jobs-analysis
   ```

2. **Créer un environnement virtuel** :
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows : venv\Scripts\activate
   ```

3. **Installer les dépendances** :
   ```bash
   pip install -r requirements.txt
   ```

4. **Configurer les identifiants Snowflake** :
   - Copiez le modèle de configuration :
     ```bash
     cp .streamlit/secrets.toml.example .streamlit/secrets.toml
     ```
   - Éditez `.streamlit/secrets.toml` avec vos identifiants Snowflake :
     ```toml
     [snowflake]
     user = "votre_utilisateur_snowflake"
     password = "votre_mot_de_passe_snowflake"
     account = "votre_identifiant_de_compte_snowflake"
     warehouse = "votre_nom_d_entrepot"
     ```

## Exécution Locale

Lancez l'application :
```bash
streamlit run visualizer.py
```

Ouvrez votre navigateur à l'adresse `http://localhost:8501`.

## Structure du Projet

- `app.py` : Application Streamlit principale affichant quatre graphiques.
- `requirements.txt` : Dépendances Python (Streamlit, Snowflake, Pandas, Plotly).
- `.gitignore` : Exclut les fichiers sensibles comme `.streamlit/secrets.toml`.
- `.streamlit/secrets.toml.example` : Modèle pour configurer les identifiants Snowflake.
- `README.md` : Ce fichier, expliquant comment installer et exécuter l'application.

## Dépannage

- **Graphiques vides** : Vérifiez les tables Snowflake (`top_jobs_by_industry`, etc.) avec :
  ```sql
  SELECT * FROM LINKEDIN.PUBLIC.top_jobs_by_industry;
  ```
- **Erreur de connexion** : Assurez-vous que `.streamlit/secrets.toml` est correctement configuré.
- **Contact** : Ouvrez une issue sur GitHub pour obtenir de l'aide.
