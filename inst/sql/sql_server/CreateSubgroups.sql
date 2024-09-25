INSERT INTO @cohortDatabaseSchema.@cohortTable

WITH cte_subgroup AS (
SELECT c.*, 
      p.gender_concept_id,
      CASE WHEN DATE_PART(YEAR, c.cohort_start_date) - p.year_of_birth < 18 THEN '<18' 
           WHEN DATE_PART(YEAR, c.cohort_start_date) - p.year_of_birth BETWEEN 18 AND 24 THEN '18-24'
           WHEN DATE_PART(YEAR, c.cohort_start_date) - p.year_of_birth BETWEEN 25 AND 44 THEN '25-44'
           WHEN DATE_PART(YEAR, c.cohort_start_date) - p.year_of_birth BETWEEN 45 AND 64 THEN '45-64'
           WHEN DATE_PART(YEAR, c.cohort_start_date) - p.year_of_birth >=65 THEN '>=65'
           ELSE 'Others' END AS age_group
FROM @cohortDatabaseSchema.@cohortTable c
JOIN @cdmDatabaseSchema.person p ON c.subject_id = p.person_id
WHERE c.cohort_definition_id IN (@targetCohortId, @comparatorCohortId)
)

SELECT CAST(CONCAT(cohort_definition_id, 1) AS INT) AS cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
FROM cte_subgroup
WHERE gender_concept_id = 8507
UNION ALL 
SELECT CAST(CONCAT(cohort_definition_id, 2) AS INT) AS cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
FROM cte_subgroup
WHERE gender_concept_id = 8532
UNION ALL
SELECT CAST(CONCAT(cohort_definition_id, 3) AS INT) AS cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
FROM cte_subgroup
WHERE age_group = '<18'
UNION ALL
SELECT CAST(CONCAT(cohort_definition_id, 4) AS INT) AS cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
FROM cte_subgroup
WHERE age_group = '18-24'
UNION ALL
SELECT CAST(CONCAT(cohort_definition_id, 5) AS INT) AS cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
FROM cte_subgroup
WHERE age_group = '25-44'
UNION ALL
SELECT CAST(CONCAT(cohort_definition_id, 6) AS INT) AS cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
FROM cte_subgroup
WHERE age_group = '45-64'
UNION ALL
SELECT CAST(CONCAT(cohort_definition_id, 7) AS INT) AS cohort_definition_id, subject_id, cohort_start_date, cohort_end_date
FROM cte_subgroup
WHERE age_group = '>=65'
