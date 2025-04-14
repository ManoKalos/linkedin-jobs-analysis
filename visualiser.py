import streamlit as st
import snowflake.connector
import plotly.express as px
import pandas as pd
import os

# Configuration de la page
st.set_page_config(page_title="Analyse des Emplois LinkedIn", layout="wide")
st.title("Analyse du Marché de l'Emploi LinkedIn")
st.markdown("Découvrez les tendances des offres d'emploi par industrie, taille d'entreprise, type de présence et type d'emploi.")

# Vérification du fichier secrets.toml
secrets_path = os.path.join(".streamlit", "secrets.toml")
if not os.path.exists(secrets_path):
    st.error("Erreur : Le fichier .streamlit/secrets.toml est manquant. Copiez .streamlit/secrets.toml.example et remplissez vos identifiants Snowflake.")
    st.stop()

# Vérification des clés Snowflake dans secrets
try:
    snowflake_config = st.secrets["snowflake"]
    required_keys = ["user", "password", "account", "warehouse"]
    for key in required_keys:
        if key not in snowflake_config:
            st.error(f"Erreur : La clé '{key}' est manquante dans .streamlit/secrets.toml.")
            st.stop()
except KeyError:
    st.error("Erreur : La section [snowflake] est manquante dans .streamlit/secrets.toml. Vérifiez le fichier.")
    st.stop()

# Connexion à Snowflake
@st.cache_resource
def connexion_snowflake():
    """Établit une connexion sécurisée à Snowflake."""
    try:
        conn = snowflake.connector.connect(
            user=snowflake_config["user"],
            password=snowflake_config["password"],
            account=snowflake_config["account"],
            warehouse=snowflake_config["warehouse"],
            database="LINKEDIN",
            schema="PUBLIC"
        )
        return conn
    except Exception as e:
        st.error(f"Erreur de connexion à Snowflake : {str(e)}")
        st.stop()

# Récupération des données
@st.cache_data
def recuperer_donnees(query):
    """Exécute une requête SQL et retourne un DataFrame."""
    conn = connexion_snowflake()
    df = pd.read_sql(query, conn)
    conn.close()
    return df

# Q1 : Top 10 des industries
st.header("Top 10 des Industries par Offres d'Emploi")
requete_industries = "SELECT industry_name, job_count FROM top_jobs_by_industry ORDER BY job_count DESC LIMIT 10"
try:
    df_industries = recuperer_donnees(requete_industries)
    if df_industries.empty:
        st.warning("Aucune donnée pour les industries. Vérifiez la table top_jobs_by_industry.")
    else:
        fig_industries = px.bar(
            df_industries,
            x="industry_name",
            y="job_count",
            title="Top 10 des Industries",
            labels={"industry_name": "Industrie", "job_count": "Nombre d'Offres"},
            color="job_count",
            color_continuous_scale="Blues"
        )
        fig_industries.update_layout(xaxis_tickangle=45, showlegend=False)
        st.plotly_chart(fig_industries, use_container_width=True)
        st.write(f"Industrie principale : {df_industries.iloc[0]['industry_name']} avec {df_industries.iloc[0]['job_count']} offres.")
except Exception as e:
    st.error(f"Erreur lors de la récupération des industries : {str(e)}")

# Q2 : Répartition par taille d'entreprise
st.header("Répartition des Offres par Taille d'Entreprise")
requete_taille = "SELECT company_size, job_count FROM jobs_by_company_size WHERE company_size != -1 ORDER BY company_size"
try:
    df_taille = recuperer_donnees(requete_taille)
    if df_taille.empty:
        st.warning("Aucune donnée pour les tailles d'entreprise. Vérifiez la table jobs_by_company_size.")
    else:
        fig_taille = px.pie(
            df_taille,
            names="company_size",
            values="job_count",
            title="Offres par Taille d'Entreprise",
            color_discrete_sequence=px.colors.qualitative.Pastel
        )
        fig_taille.update_traces(textinfo="percent+label")
        st.plotly_chart(fig_taille, use_container_width=True)
        st.write(f"Total des offres : {df_taille['job_count'].sum()} pour {len(df_taille)} catégories de taille.")
except Exception as e:
    st.error(f"Erreur lors de la récupération des tailles d'entreprise : {str(e)}")

# Q3 : Répartition par type de présence
st.header("Répartition des Offres par Type de Présence")
requete_presence = "SELECT work_type, job_count FROM jobs_by_presence WHERE work_type IN ('Remote', 'On-site', 'Hybrid')"
try:
    df_presence = recuperer_donnees(requete_presence)
    if df_presence.empty:
        st.warning("Aucune donnée pour les types de présence. Vérifiez la table jobs_by_presence.")
    else:
        fig_presence = px.pie(
            df_presence,
            names="work_type",
            values="job_count",
            title="Offres : Télétravail vs Sur Site vs Hybride",
            color_discrete_sequence=px.colors.qualitative.Set2
        )
        fig_presence.update_traces(textinfo="percent+label")
        st.plotly_chart(fig_presence, use_container_width=True)
        remote_count = df_presence[df_presence['work_type'] == 'Remote']['job_count'].iloc[0] if 'Remote' in df_presence['work_type'].values else 0
        st.write(f"Offres en télétravail : {remote_count} offres.")
except Exception as e:
    st.error(f"Erreur lors de la récupération des types de présence : {str(e)}")

# Q4 : Répartition par type d'emploi
st.header("Répartition des Offres par Type d'Emploi")
requete_emploi = "SELECT employment_type, job_count FROM jobs_by_employment_type WHERE employment_type IN ('Full-time', 'Part-time', 'Internship')"
try:
    df_emploi = recuperer_donnees(requete_emploi)
    if df_emploi.empty:
        st.warning("Aucune donnée pour les types d'emploi. Vérifiez la table jobs_by_employment_type.")
    else:
        fig_emploi = px.pie(
            df_emploi,
            names="employment_type",
            values="job_count",
            title="Offres : Temps Plein vs Temps Partiel vs Stage",
            color_discrete_sequence=px.colors.qualitative.Bold
        )
        fig_emploi.update_traces(textinfo="percent+label")
        st.plotly_chart(fig_emploi, use_container_width=True)
        full_time_count = df_emploi[df_emploi['employment_type'] == 'Full-time']['job_count'].iloc[0] if 'Full-time' in df_emploi['employment_type'].values else 0
        st.write(f"Offres à temps plein : {full_time_count} offres.")
except Exception as e:
    st.error(f"Erreur lors de la récupération des types d'emploi : {str(e)}")
