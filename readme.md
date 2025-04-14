# Analyse des Emplois LinkedIn

Application Streamlit pour visualiser les tendances des offres d'emploi LinkedIn par industrie, taille d'entreprise, type de présence et type d'emploi.

## Prérequis

- Python 3.8+
- Compte Snowflake avec accès à la base `LINKEDIN`

## Installation

1. Clonez ce dépôt :
   ```bash
   git clone https://github.com/votre_utilisateur/linkedin-job-analysis.git
   cd linkedin-job-analysis
   ```

2. Créez un environnement virtuel :
   ```bash
   python -m venv venv
   source venv/bin/activate  # Windows : venv\Scripts\activate
   ```

3. Installez les dépendances :
   ```bash
   pip install -r requirements.txt
   ```

4. Configurez vos identifiants Snowflake :
   - Copiez `.streamlit/secrets.toml.example` vers `.streamlit/secrets.toml` :
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
streamlit run app.py
```

Ouvrez `http://localhost:8501` dans votre navigateur.

## Déploiement sur Streamlit Cloud

1. Poussez le dépôt sur GitHub.
2. Connectez-vous à [Streamlit Cloud](https://streamlit.io/cloud).
3. Créez une nouvelle application et liez-la à ce dépôt.
4. Ajoutez les secrets Snowflake dans les paramètres de l'application :
   - Allez dans `Settings > Secrets`.
   - Ajoutez :
     ```toml
     [snowflake]
     user = "votre_utilisateur_snowflake"
     password = "votre_mot_de_passe_snowflake"
     account = "votre_identifiant_de_compte_snowflake"
     warehouse = "votre_nom_d_entrepot"
     ```

## Structure du Projet

- `app.py` : Application Streamlit principale.
- `requirements.txt` : Dépendances Python.
- `.streamlit/secrets.toml.example` : Modèle pour les identifiants Snowflake.
- `.gitignore` : Exclut les fichiers sensibles.

## Dépannage

- **Graphiques vides** : Vérifiez les tables Snowflake (`top_jobs_by_industry`, etc.) avec :
  ```sql
  SELECT * FROM LINKEDIN.PUBLIC.top_jobs_by_industry;
  ```
- **Erreur de connexion** : Assurez-vous que `.streamlit/secrets.toml` est correctement configuré.
- **Contact** : Ouv