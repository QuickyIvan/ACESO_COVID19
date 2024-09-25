WITH 
target_cohort AS (
  SELECT p.person_id AS person_id_t, c.cohort_start_date AS index_date_t, 
        op.observation_period_start_date AS observation_period_start_date_t, 
        p.year_of_birth, COALESCE(p.month_of_birth, 7) AS month_of_birth, p.gender_concept_id
  FROM @cohortDatabaseSchema.@cohortTable c
  JOIN @cdmDatabaseSchema.person p ON c.subject_id = p.person_id
  JOIN @cdmDatabaseSchema.observation_period op ON c.subject_id = op.person_id
  WHERE c.cohort_definition_id = @targetCohortId
  AND c.cohort_start_date >= op.observation_period_start_date
  AND c.cohort_start_date <= op.observation_period_end_date
),
comparator_cohort AS (
  SELECT p.person_id AS person_id_c, op.observation_period_start_date AS observation_period_start_date_c, 
       op.observation_period_end_date AS observation_period_end_date_c,
       p.year_of_birth, COALESCE(p.month_of_birth, 7) AS month_of_birth, p.gender_concept_id
  FROM @cohortDatabaseSchema.@cohortTable c
  JOIN @cdmDatabaseSchema.person p ON c.subject_id = p.person_id
  JOIN @cdmDatabaseSchema.observation_period op ON c.subject_id = op.person_id
  WHERE c.cohort_definition_id = @comparatorCohortId
  AND c.cohort_start_date >= op.observation_period_start_date
  AND c.cohort_start_date <= op.observation_period_end_date
),
target_comparator_mapping AS (
  SELECT tc.*, cc.person_id_c, cc.observation_period_start_date_c, cc.observation_period_end_date_c,
       DATEDIFF(day, cc.observation_period_start_date_c, tc.index_date_t) AS prior_observation_days_c,
       ABS(DATEDIFF(day, tc.observation_period_start_date_t, cc.observation_period_start_date_c)) AS observation_period_start_date_gap
  FROM target_cohort tc
  INNER JOIN comparator_cohort cc 
  ON tc.year_of_birth = cc.year_of_birth 
  AND tc.month_of_birth = cc.month_of_birth 
  AND tc.gender_concept_id = cc.gender_concept_id 
  WHERE tc.index_date_t <= cc.observation_period_end_date_c
)
SELECT f. * 
FROM (
  SELECT *, RANK() OVER (partition by person_id_c order by observation_period_start_date_gap) AS gap_rank
  FROM target_comparator_mapping
  WHERE prior_observation_days_c >= 365
) f
WHERE gap_rank = 1
