WITH ages AS (
	SELECT adm.hadm_id, date_part('year', age(adm.admittime, pat.dob)) AS age
	FROM mimiciii.admissions adm
	LEFT JOIN mimiciii.patients pat
	ON adm.subject_id = pat.subject_id
),
diastolics AS (
	WITH diastolic_items AS (
		SELECT di.itemid 
		FROM mimiciii.d_items di 
		WHERE di."label" ILIKE '%diastolic%'
	)
	SELECT c.hadm_id,
	MIN(c.value::INT) AS diastolic_min,
	AVG(c.value::INT) AS diastolic_mean,
	MAX(c.value::INT) AS diastolic_max
	FROM mimiciii.chartevents c 
	INNER JOIN diastolic_items 
	ON c.itemid = diastolic_items.itemid
	WHERE c.valueuom = 'mmHg'
    AND c.value::INT > 0
	GROUP BY c.hadm_id
),
systolics AS (
	WITH systolic_items AS (
		SELECT di.itemid 
		FROM mimiciii.d_items di 
		WHERE di."label" ILIKE '%systolic%'
	)
	SELECT c.hadm_id,
	MIN(c.value::INT) AS systolic_min,
	AVG(c.value::INT) AS systolic_mean,
	MAX(c.value::INT) AS systolic_max
	FROM mimiciii.chartevents c 
	INNER JOIN systolic_items 
	ON c.itemid = systolic_items.itemid
	WHERE c.valueuom = 'mmHg'
    AND c.value::INT > 0
	GROUP BY c.hadm_id
),
bacteria_ratios AS (
	WITH staph_ratios AS (
		WITH staph_counts AS (
			SELECT
				m.org_itemid,
				m.hadm_id,
				SUM(CASE WHEN m.interpretation = 'S' THEN 1 ELSE 0 END)::FLOAT AS sensitive_count,
				SUM(CASE WHEN m.interpretation = 'I' THEN 1 ELSE 0 END)::FLOAT AS intermediate_count,
				SUM(CASE WHEN m.interpretation = 'R' THEN 1 ELSE 0 END)::FLOAT AS resistant_count,
				SUM(1)::FLOAT AS total_count
			FROM
				mimiciii.microbiologyevents m
			WHERE
				NOT m.interpretation = '[NULL]'
			GROUP BY
				m.hadm_id,
				m.org_itemid,
				m.org_name
			HAVING
				m.org_name ILIKE '%staph%'
		)
		SELECT
			staph_counts.hadm_id,
			SUM(staph_counts.sensitive_count) / SUM(staph_counts.total_count) AS staph_sensitive_ratio,
			SUM(staph_counts.intermediate_count) / SUM(staph_counts.total_count) AS staph_intermediate_ratio,
			SUM(staph_counts.resistant_count) / SUM(staph_counts.total_count) AS staph_resistant_ratio
		FROM
			staph_counts
		GROUP BY staph_counts.hadm_id
	),
	e_coli_ratios AS (
		WITH e_coli_counts AS (
			SELECT
				m.org_itemid,
				m.hadm_id,
				SUM(CASE WHEN m.interpretation = 'S' THEN 1 ELSE 0 END)::FLOAT AS sensitive_count,
				SUM(CASE WHEN m.interpretation = 'I' THEN 1 ELSE 0 END)::FLOAT AS intermediate_count,
				SUM(CASE WHEN m.interpretation = 'R' THEN 1 ELSE 0 END)::FLOAT AS resistant_count,
				SUM(1)::FLOAT AS total_count
			FROM
				mimiciii.microbiologyevents m
			WHERE
				NOT m.interpretation = '[NULL]'
			GROUP BY
				m.hadm_id,
				m.org_itemid,
				m.org_name
			HAVING
				m.org_itemid = 80002 -- E. Coli
		)
		SELECT
			e_coli_counts.hadm_id,
			SUM(e_coli_counts.sensitive_count) / SUM(e_coli_counts.total_count) AS e_coli_sensitive_ratio,
			SUM(e_coli_counts.intermediate_count) / SUM(e_coli_counts.total_count) AS e_coli_intermediate_ratio,
			SUM(e_coli_counts.resistant_count) / SUM(e_coli_counts.total_count) AS e_coli_resistant_ratio
		FROM
			e_coli_counts
		GROUP BY e_coli_counts.hadm_id
	),
	strep_ratios AS (
		WITH strep_counts AS (
			SELECT
				m.org_itemid,
				m.hadm_id,
				SUM(CASE WHEN m.interpretation = 'S' THEN 1 ELSE 0 END)::FLOAT AS sensitive_count,
				SUM(CASE WHEN m.interpretation = 'I' THEN 1 ELSE 0 END)::FLOAT AS intermediate_count,
				SUM(CASE WHEN m.interpretation = 'R' THEN 1 ELSE 0 END)::FLOAT AS resistant_count,
				SUM(1)::FLOAT AS total_count
			FROM
				mimiciii.microbiologyevents m
			WHERE
				NOT m.interpretation = '[NULL]'
			GROUP BY
				m.hadm_id,
				m.org_itemid,
				m.org_name
			HAVING
				m.org_name ILIKE '%strep%'
		)
		SELECT
			strep_counts.hadm_id,
			SUM(strep_counts.sensitive_count) / SUM(strep_counts.total_count) AS strep_sensitive_ratio,
			SUM(strep_counts.intermediate_count) / SUM(strep_counts.total_count) AS strep_intermediate_ratio,
			SUM(strep_counts.resistant_count) / SUM(strep_counts.total_count) AS strep_resistant_ratio
		FROM
			strep_counts
		GROUP BY strep_counts.hadm_id
	)
	SELECT
		staph_ratios.hadm_id,
		staph_ratios.staph_sensitive_ratio,
		staph_ratios.staph_intermediate_ratio,
		staph_ratios.staph_resistant_ratio,
		e_coli_ratios.e_coli_sensitive_ratio,
		e_coli_ratios.e_coli_intermediate_ratio,
		e_coli_ratios.e_coli_resistant_ratio,
		strep_ratios.strep_sensitive_ratio,
		strep_ratios.strep_intermediate_ratio,
		strep_ratios.strep_resistant_ratio
	FROM staph_ratios
	FULL JOIN e_coli_ratios
	ON staph_ratios.hadm_id = e_coli_ratios.hadm_id
	FULL JOIN strep_ratios
	ON staph_ratios.hadm_id = strep_ratios.hadm_id
),
temperature_stats AS (
	WITH temperatures AS (
			WITH temperature_items AS (
				SELECT * 
				FROM mimiciii.d_items di 
				WHERE di.itemid IN (223761, 678) --Carevue and Metavision Temperature Fahrenheit
			)
			SELECT * 
			FROM mimiciii.chartevents c 
			INNER JOIN temperature_items 
			ON c.itemid = temperature_items.itemid
		)
		SELECT temperatures.hadm_id,
		MIN(temperatures.value::FLOAT) AS min_temp,
		AVG(temperatures.value::FLOAT) AS mean_temp,
		MAX(temperatures.value::FLOAT) AS max_temp
		FROM temperatures
		GROUP BY temperatures.hadm_id
),
heart_rate_stats AS (
	WITH heart_rates AS (
		WITH heart_rate_items AS (
			SELECT * 
			FROM mimiciii.d_items di 
			WHERE di.itemid IN (220045, 211)
		)
		SELECT * 
		FROM mimiciii.chartevents c 
		INNER JOIN heart_rate_items
		ON c.itemid = heart_rate_items.itemid
	)
	SELECT heart_rates.hadm_id,
	MIN(heart_rates.value::FLOAT) AS min_heart_rate,
	AVG(heart_rates.value::FLOAT) AS mean_heart_rate,
	MAX(heart_rates.value::FLOAT) AS max_heart_rate
	FROM heart_rates
    WHERE heart_rates.value::FLOAT > 0
	GROUP BY heart_rates.hadm_id
),
respiratory_rate_stats AS (
	WITH respiratory_rates AS (
		WITH respiratory_rate_items AS (
			SELECT * 
			FROM mimiciii.d_items di 
			WHERE di.itemid IN (615, 220210)
		)
		SELECT * 
		FROM mimiciii.chartevents c 
		INNER JOIN respiratory_rate_items
		ON c.itemid = respiratory_rate_items.itemid
	)
	SELECT respiratory_rates.hadm_id,
	MIN(respiratory_rates.value::FLOAT) AS min_respiratory_rate,
	AVG(respiratory_rates.value::FLOAT) AS mean_respiratory_rate,
	MAX(respiratory_rates.value::FLOAT) AS max_respiratory_rate
	FROM respiratory_rates
    WHERE respiratory_rates.value::FLOAT > 0
	GROUP BY respiratory_rates.hadm_id
),
pneumonia_stats AS (
	WITH pneumonia_diagnoses AS (
		WITH pneumonia_items AS (
			SELECT did.icd9_code
			FROM mimiciii.d_icd_diagnoses did 
			WHERE did.long_title ILIKE '%pneumonia%'
		)
		SELECT di.hadm_id
		FROM mimiciii.diagnoses_icd di
		INNER JOIN pneumonia_items
		ON di.icd9_code = pneumonia_items.icd9_code
	)
	SELECT a.hadm_id, 1 AS pneumonia_diagnosis
	FROM mimiciii.admissions a 
	INNER JOIN pneumonia_diagnoses
	ON a.hadm_id = pneumonia_diagnoses.hadm_id
),
uti_stats AS (
	WITH uti_diagnoses AS (
		WITH uti_items AS (
			SELECT did.icd9_code
			FROM mimiciii.d_icd_diagnoses did 
			WHERE did.icd9_code IN ('5901', '5902', '5908', '5990')
		)
		SELECT di.hadm_id
		FROM mimiciii.diagnoses_icd di
		INNER JOIN uti_items
		ON di.icd9_code = uti_items.icd9_code
	)
	SELECT a.hadm_id, 1 AS uti_diagnosis
	FROM mimiciii.admissions a 
	INNER JOIN uti_diagnoses
	ON a.hadm_id = uti_diagnoses.hadm_id
),
skin_infection_stats AS (
	WITH skin_infections_diagnoses AS (
		WITH skin_infections_items AS (
			SELECT did.icd9_code
			FROM mimiciii.d_icd_diagnoses did 
			WHERE did.icd9_code ILIKE '680%'
			OR did.icd9_code ILIKE '681%'
			OR did.icd9_code ILIKE '682%'
			OR did.icd9_code ILIKE '683%'
			OR did.icd9_code ILIKE '684%'
			OR did.icd9_code ILIKE '685%'
			OR did.icd9_code ILIKE '686%'
		)
		SELECT di.hadm_id
		FROM mimiciii.diagnoses_icd di
		INNER JOIN skin_infections_items
		ON di.icd9_code = skin_infections_items.icd9_code
	)
	SELECT a.hadm_id, 1 AS skin_infection_diagnosis
	FROM mimiciii.admissions a 
	INNER JOIN skin_infections_diagnoses
	ON a.hadm_id = skin_infections_diagnoses.hadm_id
),
gi_infection_stats AS (
	WITH gi_infections_diagnoses AS (
		WITH gi_infections_items AS (
			SELECT did.icd9_code
			FROM mimiciii.d_icd_diagnoses did 
			WHERE did.icd9_code ILIKE '00%'
		)
		SELECT di.hadm_id
		FROM mimiciii.diagnoses_icd di
		INNER JOIN gi_infections_items
		ON di.icd9_code = gi_infections_items.icd9_code
	)
	SELECT a.hadm_id, 1 AS gi_infection_diagnosis
	FROM mimiciii.admissions a 
	INNER JOIN gi_infections_diagnoses
	ON a.hadm_id = gi_infections_diagnoses.hadm_id
),
diabetes_stats AS (
	WITH diabetes_diagnoses AS (
		WITH diabetes_items AS (
			SELECT did.icd9_code
			FROM mimiciii.d_icd_diagnoses did
			WHERE did.icd9_code ILIKE '249%'
			OR did.icd9_code ILIKE '250%'
			OR did.icd9_code = 'V1221'
		)
		SELECT di.hadm_id
		FROM mimiciii.diagnoses_icd di
		INNER JOIN diabetes_items
		ON di.icd9_code = diabetes_items.icd9_code
	)
	SELECT a.hadm_id, 1 AS diabetes_diagnosis
	FROM mimiciii.admissions a 
	INNER JOIN diabetes_diagnoses
	ON a.hadm_id = diabetes_diagnoses.hadm_id
),
cancer_stats AS (
	WITH cancer_diagnoses AS (
		WITH cancer_items AS (
			SELECT did.icd9_code, did.short_title, did.long_title 
			FROM mimiciii.d_icd_diagnoses did
			WHERE did.icd9_code ILIKE '14%'
			OR did.icd9_code ILIKE '15%'
			OR did.icd9_code ILIKE '16%'
			OR did.icd9_code ILIKE '17%'
			OR did.icd9_code ILIKE '18%'
			OR did.icd9_code ILIKE '19%'
			OR did.icd9_code ILIKE '20%'
			OR did.icd9_code ILIKE '23%'
			OR did.icd9_code ILIKE '24%'
		)
		SELECT di.hadm_id
		FROM mimiciii.diagnoses_icd di
		INNER JOIN cancer_items
		ON di.icd9_code = cancer_items.icd9_code
	)
	SELECT a.hadm_id, 1 AS cancer_diagnosis
	FROM mimiciii.admissions a 
	INNER JOIN cancer_diagnoses
	ON a.hadm_id = cancer_diagnoses.hadm_id
),
lung_disease_stats AS (
	WITH lung_disease_diagnoses AS (
		WITH lung_disease_items AS (
			SELECT did.icd9_code
			FROM mimiciii.d_icd_diagnoses did
			WHERE did.icd9_code ILIKE '49%'
			OR did.icd9_code ILIKE '50%'
			OR did.icd9_code ILIKE '515%'
			OR did.icd9_code ILIKE '516%'
			OR did.icd9_code ILIKE '517%'
			OR did.icd9_code ILIKE '518%'
			OR did.icd9_code ILIKE '519%'
		)
		SELECT di.hadm_id
		FROM mimiciii.diagnoses_icd di
		INNER JOIN lung_disease_items
		ON di.icd9_code = lung_disease_items.icd9_code
	)
	SELECT a.hadm_id, 1 AS lung_disease_diagnosis
	FROM mimiciii.admissions a 
	INNER JOIN lung_disease_diagnoses
	ON a.hadm_id = lung_disease_diagnoses.hadm_id
),
immunodeficiency_stats AS (
	WITH immunodeficiency_diagnoses AS (
		WITH immunodeficiency_items AS (
			SELECT did.icd9_code
			FROM mimiciii.d_icd_diagnoses did
			WHERE did.icd9_code ILIKE '279%'
			OR did.icd9_code ILIKE '042%'
		)
		SELECT di.hadm_id
		FROM mimiciii.diagnoses_icd di
		INNER JOIN immunodeficiency_items
		ON di.icd9_code = immunodeficiency_items.icd9_code
	)
	SELECT a.hadm_id, 1 AS immunodeficiency_diagnosis
	FROM mimiciii.admissions a 
	INNER JOIN immunodeficiency_diagnoses
	ON a.hadm_id = immunodeficiency_diagnoses.hadm_id
),
kidney_disease_stats AS (
	WITH kidney_disease_diagnoses AS (
		WITH kidney_disease_items AS (
			SELECT did.icd9_code
			FROM mimiciii.d_icd_diagnoses did
			WHERE did.icd9_code ILIKE '58%'
		)
		SELECT di.hadm_id
		FROM mimiciii.diagnoses_icd di
		INNER JOIN kidney_disease_items
		ON di.icd9_code = kidney_disease_items.icd9_code
	)
	SELECT a.hadm_id, 1 AS kidney_disease_diagnosis
	FROM mimiciii.admissions a 
	INNER JOIN kidney_disease_diagnoses
	ON a.hadm_id = kidney_disease_diagnoses.hadm_id
),
presepsis_admissions AS (
	WITH sepsis_admissions AS (
		WITH sepsis_diagnoses AS (
			SELECT DISTINCT ON (di.hadm_id) di.hadm_id 
			FROM mimiciii.diagnoses_icd di 
			WHERE di.icd9_code = '99591' --Sepsis
			OR di.icd9_code = '99592' --Severe Sepsis
		)
		SELECT *
		FROM mimiciii.admissions adm
		INNER JOIN sepsis_diagnoses 
		ON adm.hadm_id = sepsis_diagnoses.hadm_id
	)
	SELECT a.hadm_id, 1 AS will_readmit_for_sepsis
	FROM mimiciii.admissions a
	INNER JOIN sepsis_admissions sa
	ON a.subject_id = sa.subject_id
	WHERE a.admittime > (sa.admittime - INTERVAL '30 days')
	AND a.admittime < sa.admittime
	AND a.hospital_expire_flag = 0
)
SELECT
    DISTINCT ON (adm.hadm_id)
	adm.hadm_id,
	diastolics.diastolic_min,
	diastolics.diastolic_mean,
	diastolics.diastolic_max,
	systolics.systolic_min,
	systolics.systolic_mean,
	systolics.systolic_max,
	bacteria_ratios.staph_sensitive_ratio,
	bacteria_ratios.staph_intermediate_ratio,
	bacteria_ratios.staph_resistant_ratio,
	bacteria_ratios.e_coli_sensitive_ratio,
	bacteria_ratios.e_coli_intermediate_ratio,
	bacteria_ratios.e_coli_resistant_ratio,
	bacteria_ratios.strep_sensitive_ratio,
	bacteria_ratios.strep_intermediate_ratio,
	bacteria_ratios.strep_resistant_ratio,
	temperature_stats.min_temp,
	temperature_stats.mean_temp,
	temperature_stats.max_temp,
	heart_rate_stats.min_heart_rate,
	heart_rate_stats.mean_heart_rate,
	heart_rate_stats.max_heart_rate,
	respiratory_rate_stats.min_respiratory_rate,
	respiratory_rate_stats.mean_respiratory_rate,
	respiratory_rate_stats.max_respiratory_rate,
	pneumonia_stats.pneumonia_diagnosis,
	uti_stats.uti_diagnosis,
	skin_infection_stats.skin_infection_diagnosis,
	gi_infection_stats.gi_infection_diagnosis,
	diabetes_stats.diabetes_diagnosis,
	cancer_stats.cancer_diagnosis,
	lung_disease_stats.lung_disease_diagnosis,
	immunodeficiency_stats.immunodeficiency_diagnosis,
	kidney_disease_stats.kidney_disease_diagnosis,
	presepsis_admissions.will_readmit_for_sepsis
FROM mimiciii.admissions adm
LEFT JOIN ages
ON adm.hadm_id = ages.hadm_id
LEFT JOIN diastolics
ON adm.hadm_id = diastolics.hadm_id
LEFT JOIN systolics
ON adm.hadm_id = systolics.hadm_id
LEFT JOIN bacteria_ratios
ON adm.hadm_id = bacteria_ratios.hadm_id
LEFT JOIN temperature_stats
ON adm.hadm_id = temperature_stats.hadm_id
LEFT JOIN heart_rate_stats
ON adm.hadm_id = heart_rate_stats.hadm_id
LEFT JOIN respiratory_rate_stats
ON adm.hadm_id = respiratory_rate_stats.hadm_id
LEFT JOIN pneumonia_stats
ON adm.hadm_id = pneumonia_stats.hadm_id
LEFT JOIN uti_stats
ON adm.hadm_id = uti_stats.hadm_id
LEFT JOIN skin_infection_stats
ON adm.hadm_id = skin_infection_stats.hadm_id
LEFT JOIN gi_infection_stats
ON adm.hadm_id = gi_infection_stats.hadm_id
LEFT JOIN diabetes_stats
ON adm.hadm_id = diabetes_stats.hadm_id
LEFT JOIN cancer_stats
ON adm.hadm_id = cancer_stats.hadm_id
LEFT JOIN lung_disease_stats
ON adm.hadm_id = lung_disease_stats.hadm_id
LEFT JOIN immunodeficiency_stats
ON adm.hadm_id = immunodeficiency_stats.hadm_id
LEFT JOIN kidney_disease_stats
ON adm.hadm_id = kidney_disease_stats.hadm_id
LEFT JOIN presepsis_admissions
ON adm.hadm_id = presepsis_admissions.hadm_id