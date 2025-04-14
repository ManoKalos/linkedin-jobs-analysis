-- Création de la base
CREATE OR REPLACE DATABASE linkedin;
USE DATABASE linkedin;

-- Création du stage
CREATE OR REPLACE STAGE linkedin_stage
  URL = 's3://snowflake-lab-bucket/';

-- Création des formats de fichiers
CREATE OR REPLACE FILE FORMAT csv_comma_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  NULL_IF = ('NULL', '')
  FIELD_OPTIONALLY_ENCLOSED_BY = '"';

-- Délimiteur différent pour les job posting
CREATE OR REPLACE FILE FORMAT csv_semicolon_format
  TYPE = 'CSV'
  FIELD_DELIMITER = ';'
  SKIP_HEADER = 1
  NULL_IF = ('NULL', '')
  FIELD_OPTIONALLY_ENCLOSED_BY = '"';

CREATE OR REPLACE FILE FORMAT json_format
  TYPE = 'JSON'
  STRIP_OUTER_ARRAY = TRUE;

-- Création des tables 
CREATE OR REPLACE TABLE job_postings (
  job_id STRING,
  job STRING,
  location STRING,
  company_id STRING,
  company_name STRING,
  work_type STRING,
  full_time_remote STRING,
  no_of_employ STRING,
  no_of_application INTEGER,
  posted_day_ago STRING,
  alumni STRING,
  hiring_person STRING,
  linkedin_followers STRING,
  hiring_person_link STRING,
  job_details STRING
);

CREATE OR REPLACE TABLE salaries (
  salary_id STRING,
  job_id STRING,
  max_salary FLOAT,
  med_salary FLOAT,
  min_salary FLOAT,
  pay_period STRING,
  currency STRING,
  compensation_type STRING
);

CREATE OR REPLACE TABLE benefits (
  job_id STRING,
  type STRING,
  inferred INTEGER
);

CREATE OR REPLACE TABLE companies (
  company_id STRING,
  name STRING,
  description STRING,
  company_size INTEGER,
  state STRING,
  country STRING,
  city STRING,
  zip_code STRING,
  address STRING,
  url STRING
);

CREATE OR REPLACE TABLE skills (
  skill_abr STRING,
  skill_name STRING
);

CREATE OR REPLACE TABLE employee_counts (
  company_id STRING,
  employee_count INTEGER,
  follower_count INTEGER,
  time_recorded FLOAT
);

CREATE OR REPLACE TABLE job_skills (
  job_id STRING,
  skill_abr STRING
);

CREATE OR REPLACE TABLE industries (
  industry_id STRING,
  industry_name STRING
);

CREATE OR REPLACE TABLE job_industries (
  job_id STRING,
  industry_id STRING
);

CREATE OR REPLACE TABLE company_specialities (
  company_id STRING,
  speciality STRING
);

CREATE OR REPLACE TABLE company_industries (
  company_id STRING,
  industry STRING
);

-- Charger les données
-- Fichiers CSV
COPY INTO job_postings
  FROM @linkedin_stage/job_postings.csv
  FILE_FORMAT = (FORMAT_NAME = 'csv_semicolon_format')
  ON_ERROR = 'CONTINUE';

COPY INTO salaries
  FROM @linkedin_stage/salaries.csv
  FILE_FORMAT = (FORMAT_NAME = 'csv_comma_format')
  ON_ERROR = 'CONTINUE';

COPY INTO benefits (job_id, inferred, type)
  FROM (SELECT $1, $2, $3 FROM @linkedin_stage/benefits.csv)
  FILE_FORMAT = (FORMAT_NAME = 'csv_comma_format')
  ON_ERROR = 'CONTINUE';

COPY INTO employee_counts
  FROM @linkedin_stage/employee_counts.csv
  FILE_FORMAT = (FORMAT_NAME = 'csv_comma_format')
  ON_ERROR = 'CONTINUE';

COPY INTO job_skills
  FROM @linkedin_stage/job_skills.csv
  FILE_FORMAT = (FORMAT_NAME = 'csv_comma_format')
  ON_ERROR = 'CONTINUE';

COPY INTO skills
  FROM @linkedin_stage/skills.csv
  FILE_FORMAT = (FORMAT_NAME = 'csv_comma_format')
  ON_ERROR = 'CONTINUE';

-- Fichiers JSON
CREATE OR REPLACE TEMPORARY TABLE temp_json (raw_data VARIANT);

-- Companies
COPY INTO temp_json
  FROM @linkedin_stage/companies.json
  FILE_FORMAT = (FORMAT_NAME = 'json_format');
INSERT INTO companies
  SELECT
    raw_data:company_id::STRING,
    raw_data:name::STRING,
    raw_data:description::STRING,
    raw_data:company_size::INTEGER,
    raw_data:state::STRING,
    raw_data:country::STRING,
    raw_data:city::STRING,
    raw_data:zip_code::STRING,
    raw_data:address::STRING,
    raw_data:url::STRING
  FROM temp_json;

-- Company_industries
TRUNCATE TABLE temp_json;
COPY INTO temp_json
  FROM @linkedin_stage/company_industries.json
  FILE_FORMAT = (FORMAT_NAME = 'json_format');
INSERT INTO company_industries
  SELECT
    raw_data:company_id::STRING,
    raw_data:industry::STRING
  FROM temp_json;

-- Company_specialities
TRUNCATE TABLE temp_json;
COPY INTO temp_json
  FROM @linkedin_stage/company_specialities.json
  FILE_FORMAT = (FORMAT_NAME = 'json_format');
INSERT INTO company_specialities
  SELECT
    raw_data:company_id::STRING,
    raw_data:speciality::STRING
  FROM temp_json;

-- Industries
TRUNCATE TABLE temp_json;
COPY INTO temp_json
  FROM @linkedin_stage/industries.json
  FILE_FORMAT = (FORMAT_NAME = 'json_format');
INSERT INTO industries
  SELECT
    raw_data:industry_id::STRING,
    raw_data:industry_name::STRING
  FROM temp_json;

-- Job_industries
TRUNCATE TABLE temp_json;
COPY INTO temp_json
  FROM @linkedin_stage/job_industries.json
  FILE_FORMAT = (FORMAT_NAME = 'json_format');
INSERT INTO job_industries
  SELECT
    raw_data:job_id::STRING,
    raw_data:industry_id::STRING
  FROM temp_json;

-- Transformation de la donnée
UPDATE job_postings
SET work_type = COALESCE(work_type, 'Unknown'),
    no_of_application = COALESCE(no_of_application, 0),
    company_name = COALESCE(company_name, 'Unknown');

CREATE OR REPLACE TABLE salaries_normalized AS
SELECT
  salary_id,
  job_id,
  CASE
    WHEN pay_period = 'HOURLY' THEN max_salary * 2080
    ELSE max_salary
  END AS max_salary_yearly,
  CASE
    WHEN pay_period = 'HOURLY' THEN min_salary * 2080
    ELSE min_salary
  END AS min_salary_yearly,
  currency,
  compensation_type
FROM salaries;

CREATE OR REPLACE TABLE job_skills_dedup AS
SELECT DISTINCT job_id, skill_abr
FROM job_skills;

-- Queries d'analyse
CREATE OR REPLACE TABLE top_jobs_by_industry AS
SELECT
  COALESCE(ci.industry, 'Unknown') AS industry_name,
  COUNT(jp.job_id) AS job_count
FROM job_postings jp
LEFT JOIN companies c ON jp.company_id = c.company_id
LEFT JOIN company_industries ci ON c.company_id = ci.company_id
GROUP BY ci.industry
ORDER BY job_count DESC
LIMIT 10;

CREATE OR REPLACE TABLE jobs_by_company_size AS
SELECT
  COALESCE(c.company_size, -1) AS company_size,
  COUNT(jp.job_id) AS job_count
FROM job_postings jp
LEFT JOIN companies c ON jp.company_id = c.company_id
GROUP BY c.company_size
ORDER BY c.company_size;

CREATE OR REPLACE TABLE jobs_by_presence AS
SELECT
  COALESCE(work_type, 'Unknown') AS work_type,
  COUNT(job_id) AS job_count
FROM job_postings
GROUP BY work_type;

CREATE OR REPLACE TABLE jobs_by_employment_type AS
SELECT
  COALESCE(REGEXP_SUBSTR(full_time_remote, 'Full-time|Part-time|Internship', 1, 1), 'Unknown') AS employment_type,
  COUNT(job_id) AS job_count
FROM job_postings
GROUP BY employment_type;

-- Analyse
SELECT TABLE_NAME, ROW_COUNT
FROM INFORMATION_SCHEMA.TABLES
WHERE TABLE_CATALOG = 'LINKEDIN' AND TABLE_SCHEMA = 'PUBLIC'
ORDER BY TABLE_NAME;

SELECT 'benefits' AS table_name, job_id, type, inferred FROM benefits LIMIT 10;
SELECT 'job_postings' AS table_name, job_id, job, company_id FROM job_postings LIMIT 10;
SELECT 'salaries' AS table_name, salary_id, job_id, med_salary FROM salaries LIMIT 10;
SELECT 'companies' AS table_name, company_id, name, company_size FROM companies LIMIT 10;
SELECT 'skills' AS table_name, skill_abr, skill_name FROM skills LIMIT 10;
SELECT 'employee_counts' AS table_name, company_id, employee_count FROM employee_counts LIMIT 10;
SELECT 'job_skills' AS table_name, job_id, skill_abr FROM job_skills LIMIT 10;
SELECT 'industries' AS table_name, industry_id, industry_name FROM industries LIMIT 10;
SELECT 'job_industries' AS table_name, job_id, industry_id FROM job_industries LIMIT 10;
SELECT 'company_specialities' AS table_name, company_id, speciality FROM company_specialities LIMIT 10;
SELECT 'company_industries' AS table_name, company_id, industry FROM company_industries LIMIT 10;
SELECT 'top_jobs_by_industry' AS table_name, industry_name, job_count FROM top_jobs_by_industry LIMIT 10;
SELECT 'jobs_by_company_size' AS table_name, company_size, job_count FROM jobs_by_company_size LIMIT 10;
SELECT 'jobs_by_presence' AS table_name, work_type, job_count FROM jobs_by_presence LIMIT 10;
SELECT 'jobs_by_employment_type' AS table_name, employment_type, job_count FROM jobs_by_employment_type LIMIT 10;
SELECT 'salaries_normalized' AS table_name, salary_id, job_id, max_salary_yearly FROM salaries_normalized LIMIT 10;
SELECT 'job_skills_dedup' AS table_name, job_id, skill_abr FROM job_skills_dedup LIMIT 10;

