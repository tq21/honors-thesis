-- type 2 diabetes patients SUBJECT_ID, HADM_ID (54521)
WITH
dm_patients AS (
  SELECT SUBJECT_ID,
         HADM_ID,
  FROM `physionet-data.mimic_hosp.diagnoses_icd` AS A
  WHERE icd_code LIKE 'E11%'                    
),

-- first admission time, SUBJECT_ID, ADMIT_TIME (17606)
first_admit AS (
  SELECT
    A.SUBJECT_ID,
    min(B.ADMITTIME) as ADMIT_TIME
  FROM 
    dm_patients AS A,
    `physionet-data.mimic_core.admissions` AS B
  WHERE
    A.SUBJECT_ID = B.SUBJECT_ID AND
    A.HADM_ID = B.HADM_ID
  GROUP BY
    A.SUBJECT_ID
),

-- first discharge time, SUBJECT_ID, HADM_ID_1 (17606)
main AS (
  SELECT
    A.SUBJECT_ID,
    B.HADM_ID AS HADM_ID_1,
    A.ADMIT_TIME,
    B.DISCHTIME AS DISCH_TIME
  FROM
    first_admit AS A,
    `physionet-data.mimic_core.admissions` AS B
  where
    A.SUBJECT_ID = B.SUBJECT_ID AND
    A.ADMIT_TIME = B.ADMITTIME
),

-- compute length-of-stay: SUBJECT_ID, LOS
time_diff_var AS (
  SELECT
    SUBJECT_ID,
    DATETIME_DIFF(DISCH_TIME, ADMIT_TIME, DAY) AS LENGTH_OF_STAY
  FROM
    main
),

-- get patients info: SUBJECT_ID, GENDER, AGE
patients_info_var AS (
  SELECT
    A.SUBJECT_ID,
    B.GENDER,
    EXTRACT(YEAR FROM A.ADMIT_TIME) - B.ANCHOR_YEAR + B.ANCHOR_AGE AS AGE
  FROM
    main AS A,
    `physionet-data.mimic_core.patients` AS B
  WHERE
    A.SUBJECT_ID = B.SUBJECT_ID
),

-- get admission info: SUBJECT_ID, ADMISSION_TYPE, INSURANCE, MARITAL_STATUS, ETHNICITY
admin_info AS (
  SELECT
    A.SUBJECT_ID,
    B.ADMISSION_TYPE,
    B.DISCHARGE_LOCATION,
    B.INSURANCE,
    B.MARITAL_STATUS,
    B.ETHNICITY
  FROM
    main AS A,
    `physionet-data.mimic_core.admissions` AS B
  WHERE
    A.SUBJECT_ID = B.SUBJECT_ID AND
    A.HADM_ID_1 = B.HADM_ID
),

# -- glucose 1 time: HADM_ID_1, CHARTTIME_1 (8144)
# glucose_time_1 AS (
#   SELECT
#     A.HADM_ID_1,
#     min(B.CHARTTIME) AS CHARTTIME_1
#   FROM
#     main AS A
#   LEFT JOIN
#     `physionet-data.mimic_derived.chemistry` AS B
#   ON
#     A.HADM_ID_1 = B.HADM_ID
#   GROUP BY
#     A.HADM_ID_1
# ),

# -- glucose 1 value: HADM_ID_1, GLUCOSE_1
# glucose_val_1 AS (
#   SELECT
#     A.HADM_ID_1,
#     B.GLUCOSE AS GLUCOSE_1,
#     row_number() OVER (PARTITION BY HADM_ID_1) AS RN
#   FROM
#     glucose_time_1 AS A
#   LEFT JOIN
#     `physionet-data.mimic_derived.chemistry` AS B
#   ON
#     A.HADM_ID_1 = B.HADM_ID AND
#     A.CHARTTIME_1 = B.CHARTTIME
# ),

# -- glucose 1 final (8144)
# glucose_val_1_final AS (
#   SELECT
#     HADM_ID_1,
#     GLUCOSE_1
#   FROM
#     glucose_val_1
#   WHERE
#     RN < 2
# ),
glucose_time_1 AS (
  SELECT
    A.HADM_ID_1,
    min(B.CHARTTIME) AS CHARTTIME_1
  FROM
    main AS A
  LEFT JOIN
    `physionet-data.mimic_hosp.labevents` AS B
  ON
    A.HADM_ID_1 = B.HADM_ID AND
    A.SUBJECT_ID = B.SUBJECT_ID AND 
    B.ITEMID = 50931
  GROUP BY
    A.HADM_ID_1
),

glucose_val_1 AS (
  SELECT
    A.HADM_ID_1,
    VALUENUM AS GLUCOSE_1,
    row_number() OVER (PARTITION BY HADM_ID_1) AS RN
  FROM
    glucose_time_1 AS A
  LEFT JOIN
    `physionet-data.mimic_hosp.labevents` AS B
  ON
    A.HADM_ID_1 = B.HADM_ID AND
    A.CHARTTIME_1 = B.CHARTTIME AND
    B.ITEMID = 50931
),

glucose_val_1_final AS (
  SELECT
    HADM_ID_1,
    GLUCOSE_1
  FROM
    glucose_val_1
  WHERE
    RN < 2
),

-- hemoglobin 1 time: HADM_ID_1, CHARTTIME_1 (8144)
# hemoglobin_time_1 AS (
#   SELECT
#     A.HADM_ID_1,
#     min(B.CHARTTIME) AS CHARTTIME_1
#   FROM
#     main AS A
#   LEFT JOIN
#     `physionet-data.mimic_derived.complete_blood_count` AS B
#   ON
#     A.HADM_ID_1 = B.HADM_ID
#   GROUP BY
#     A.HADM_ID_1
# ),

# -- hemoglobin 1 value: HADM_ID_1, HEMOGLOBIN_1
# hemoglobin_val_1 AS (
#   SELECT
#     A.HADM_ID_1,
#     B.HEMOGLOBIN AS HEMOGLOBIN_1,
#     row_number() OVER (PARTITION BY HADM_ID_1) AS RN
#   FROM
#     hemoglobin_time_1 AS A
#   LEFT JOIN
#     `physionet-data.mimic_derived.complete_blood_count` AS B
#   ON
#     A.HADM_ID_1 = B.HADM_ID AND
#     A.CHARTTIME_1 = B.CHARTTIME
# ),

# -- hemoglobin 1 final (8144)
# hemoglobin_val_1_final AS (
#   SELECT
#     HADM_ID_1,
#     HEMOGLOBIN_1
#   FROM
#     hemoglobin_val_1
#   WHERE
#     RN < 2
# ),

a1c_time_1 AS (
  SELECT
    A.HADM_ID_1,
    min(B.CHARTTIME) AS CHARTTIME_1
  FROM
    main AS A
  LEFT JOIN
    `physionet-data.mimic_hosp.labevents` AS B
  ON
    A.HADM_ID_1 = B.HADM_ID AND
    A.SUBJECT_ID = B.SUBJECT_ID AND 
    B.ITEMID = 51222
  GROUP BY
    A.HADM_ID_1
),

a1c_val_1 AS (
  SELECT
    A.HADM_ID_1,
    VALUENUM AS A1C_1,
    row_number() OVER (PARTITION BY HADM_ID_1) AS RN
  FROM
    a1c_time_1 AS A
  LEFT JOIN
    `physionet-data.mimic_hosp.labevents` AS B
  ON
    A.HADM_ID_1 = B.HADM_ID AND
    A.CHARTTIME_1 = B.CHARTTIME AND
    B.ITEMID = 51222
),

a1c_val_1_final AS (
  SELECT
    HADM_ID_1,
    A1C_1
  FROM
    a1c_val_1
  WHERE
    RN < 2
),

-- patients with hypertension
hypertension_patients AS (
  SELECT 
    SUBJECT_ID
  FROM
    `physionet-data.mimic_hosp.diagnoses_icd`
  WHERE
    (ICD_CODE LIKE 'I10%' OR
    ICD_CODE LIKE 'I11%' OR
    ICD_CODE LIKE 'I12%' OR
    ICD_CODE LIKE 'I13%' OR
    ICD_CODE LIKE 'I14%' OR
    ICD_CODE LIKE 'I15%' OR
    ICD_CODE LIKE 'I16%') AND
    ICD_VERSION = 10 AND
    HADM_ID IN (SELECT HADM_ID_1 FROM main)
),

-- patients with hyperlipidemia
hyperlipidemia_patients AS (
  SELECT
    SUBJECT_ID
  FROM
    `physionet-data.mimic_hosp.diagnoses_icd`
  WHERE
    ICD_CODE LIKE 'E78%' AND
    ICD_VERSION = 10 AND
    HADM_ID IN (SELECT HADM_ID_1 FROM main)
),

-- patients with chronic kidney disease
ckd_patients AS (
  SELECT
    SUBJECT_ID
  FROM
    `physionet-data.mimic_hosp.diagnoses_icd`
  WHERE
    (ICD_CODE LIKE 'N18%' OR
    ICD_CODE = 'E08.22' OR
    ICD_CODE = 'E09.22' OR
    ICD_CODE = 'E10.22' OR
    ICD_CODE = 'E11.22' OR
    ICD_CODE = 'E13.22' OR
    ICD_CODE LIKE 'I12%' OR
    ICD_CODE LIKE 'I13%') AND
    ICD_VERSION = 10 AND
    HADM_ID IN (SELECT HADM_ID_1 FROM main)
),

-- add indicator vars for comorbidities
comor AS (
  SELECT
    A.SUBJECT_ID,
    IF (A.SUBJECT_ID IN (SELECT SUBJECT_ID FROM hypertension_patients), 1, 0) AS HYPERTENSION,
    IF (A.SUBJECT_ID IN (SELECT SUBJECT_ID FROM hyperlipidemia_patients), 1, 0) AS HYPERLIPIDEMIA,
    IF (A.SUBJECT_ID IN (SELECT SUBJECT_ID FROM ckd_patients), 1, 0) AS CKD
  FROM
    main AS A  
),

-- combine all tables
combined AS (
  SELECT
    A.SUBJECT_ID,
    A.HADM_ID_1,
    A.ADMIT_TIME,
    A.DISCH_TIME,
    B.LENGTH_OF_STAY,
    C.GENDER,
    C.AGE,
    D.ADMISSION_TYPE,
    D.DISCHARGE_LOCATION,
    D.INSURANCE,
    D.MARITAL_STATUS,
    D.ETHNICITY,
    E.GLUCOSE_1,
    G.A1C_1,
    I.HYPERTENSION,
    I.HYPERLIPIDEMIA,
    I.CKD
  FROM
    main AS A,
    time_diff_var AS B,
    patients_info_var AS C,
    admin_info AS D,
    glucose_val_1_final AS E,
    a1c_val_1_final AS G,
    comor AS I
  WHERE
    A.SUBJECT_ID = B.SUBJECT_ID AND
    A.SUBJECT_ID = C.SUBJECT_ID AND
    A.SUBJECT_ID = D.SUBJECT_ID AND
    A.HADM_ID_1 = E.HADM_ID_1 AND
    A.HADM_ID_1 = G.HADM_ID_1 AND
    A.SUBJECT_ID = I.SUBJECT_ID
)

SELECT * FROM combined
