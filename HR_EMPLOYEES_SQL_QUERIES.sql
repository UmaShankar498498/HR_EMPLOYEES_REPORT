SHOW DATABASES;
CREATE DATABASE hr_project;
USE hr_project;		
SHOW TABLES;
# RENAMING COLUMN NAME
ALTER TABLE hr
RENAME COLUMN ï»¿id TO id;

# CHANGING COLUMN NAME AND DATATYPE ALSO
ALTER TABLE hr
CHANGE COLUMN id emp_id VARCHAR(20) NULL;

SELECT * FROM hr;

DESCRIBE hr;

# UPDATING DATE FORMAT
UPDATE hr
SET birthdate = CASE
	WHEN birthdate LIKE '%/%/%' THEN date_format(str_to_date(birthdate, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN birthdate LIKE '%-%-%' THEN date_format(str_to_date(birthdate, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL
    END;
    
SELECT * FROM hr;

# CHANGING DATATYPE OF BIRTHDATE COLUMN
ALTER TABLE hr
CHANGE COLUMN birthdate birthdate DATE;

UPDATE hr
SET hire_date = CASE
	WHEN hire_date LIKE '%/%/%' THEN date_format(str_to_date(hire_date, '%m/%d/%Y'), '%Y-%m-%d')
    WHEN hire_date LIKE '%-%-%' THEN date_format(str_to_date(hire_date, '%m-%d-%Y'), '%Y-%m-%d')
    ELSE NULL END;

SELECT hire_date FROM hr;

ALTER TABLE hr
MODIFY COLUMN hire_date DATE;

DESCRIBE hr;

SELECT * FROM hr;

UPDATE hr
SET termdate = CASE
WHEN termdate LIKE '%-%' THEN DATE(str_to_date(termdate, '%Y-%m-%d %H:%i:%s UTC'))
ELSE '0000-00-00' END;

SELECT * FROM hr;

# TO MODIFY INVALID DATE FORMATS
SET sql_mode = 'ALLOW_INVALID_DATES';

ALTER TABLE hr
MODIFY COLUMN termdate DATE;

DESCRIBE hr;

SELECT * FROM hr;

ALTER TABLE hr
MODIFY COLUMN age INT;

UPDATE hr
SET age = timestampdiff(YEAR, birthdate, CURDATE());

SELECT MAX(age), MIN(age) FROM hr;

SELECT COUNT(*) FROM hr WHERE age<18;

DELETE FROM hr WHERE age<18;
-- 1. GENDER BREAKDOWN OF THE EMPLOYEES.
SELECT gender, count(*) FROM hr 
WHERE termdate = '0000-00-00' 
GROUP BY gender;

-- 2. RACE/ETHNICITY BREAKDOWN OF THE EMPLOYEES.
SELECT race, count(*) FROM hr
WHERE termdate = '0000-00-00'
GROUP BY race
ORDER BY count(*) DESC;

-- 3. AGE DISTRIBUTION OF THE EMPLOYEES.
SELECT MIN(age) AS minimum_age, MAX(age) AS maximum_age
FROM hr WHERE termdate = '0000-00-00';

SELECT CASE 
			WHEN age>=18 AND age<=24 THEN '18-24'
            WHEN age>=25 AND age<=34 THEN '25-34'
            WHEN age>=35 AND age<=44 THEN '35-44'
            WHEN age>=45 AND age<=54 THEN '45-54'
            WHEN age>=55 AND age<=64 THEN '55-64'
		ELSE '65+' END AS age_group, gender,
        COUNT(*) AS count
        FROM hr WHERE termdate = '0000-00-00'
        GROUP BY age_group, gender
        ORDER BY age_group, gender;

-- 4. HOW MANY EMPLOYEES WORK AT HEAD QUARTERS VS REMOTE LOCATIONS?
SELECT DISTINCT(location) FROM hr;
SELECT location, COUNT(*) count FROM hr 
WHERE termdate = '0000-00-00'
GROUP BY location;

-- 5. AVERAGE LENGTH OF EMPLOYMENT FOR EMPLOYEES WHO HAVE BEEN TERMINATED?
SELECT * FROM hr;
SELECT ROUND(AVG(timestampdiff(year, hire_date, termdate)),0) avg_length_employment FROM hr
WHERE termdate<>'0000-00-00' AND termdate <= curdate();
--                                                  OR
SELECT ROUND(AVG(datediff(termdate, hire_date))/365, 0) avg_length_employment FROM hr
WHERE termdate <> '0000-00-00' AND termdate <= curdate();

-- 6. HOW DOES THE GENDER DISTRIBUTION VARY ACROSS DEPARTMENTS AND JOB TITLES?
SELECT * FROM hr;
-- ACROSS DEPARTMENTS
SELECT department, gender, count(*) count FROM hr WHERE termdate = '0000-00-00'
GROUP BY department, gender
ORDER BY department;
-- ACROSS JOBTITLES
SELECT jobtitle, gender, count(*) count FROM hr WHERE termdate = '0000-00-00'
GROUP BY jobtitle, gender
ORDER BY jobtitle;

-- 7. DISTRIBUTION OF JOB TITLES ACROSS THE COMPANY?
SELECT * FROM hr;
SELECT jobtitle, count(*) count FROM hr WHERE termdate = '0000-00-00'
GROUP BY jobtitle
ORDER BY jobtitle DESC;

-- 8. DEPARTMENT WITH HIGHEST TERMINATION RATE?
SELECT * FROM hr;
SET sql_mode = 'ALLOW_INVALID_DATES';

WITH e_d AS (SELECT department, COUNT(*) AS total_emp_bydept FROM hr 
GROUP BY department),
e_dt AS (SELECT department, COUNT(*) AS total_emp_bydept_terminated FROM hr 
WHERE termdate <> '0000-00-00' AND termdate < curdate() GROUP BY department)
SELECT e_d.department, (total_emp_bydept_terminated/total_emp_bydept)*100 AS term_rate
FROM e_d INNER JOIN e_dt ON e_d.department=e_dt.department
ORDER BY term_rate DESC;
											-- OR --
 -- USING SUBQUERY
 SELECT * FROM hr;
 SELECT department, (terminated_count/total_count)*100 AS term_rate FROM
 (SELECT department,
 COUNT(*) total_count,
 SUM(CASE WHEN termdate <> '0000-00-00' AND termdate < curdate() THEN 1 ELSE NULL END) AS terminated_count
 FROM hr
 GROUP BY department) AS term_metrics
 ORDER BY term_rate DESC;
                                            
-- 9. DISTRIBUTION OF EMPLOYEES ACROSS LOCATIONS BY CITY AND STATE
SELECT * FROM hr;
SELECT location_state ,COUNT(*) AS location_dist FROM hr
WHERE termdate = '0000-00-00'
GROUP BY location_state
ORDER BY COUNT(*) DESC;

-- 10. HOW HAS THE COMPANY'S EMPLOYEE COUNT CHANGED OVER TIME BASED ON HIRE AND TERM DATES?
SELECT * FROM hr;
WITH hires AS (
SELECT YEAR(hire_date) AS hire_year, COUNT(*) AS no_hires FROM hr GROUP BY hire_year
), terminations AS (
SELECT YEAR(termdate) AS term_year, COUNT(*) AS no_terms FROM hr WHERE termdate<>'0000-00-00' AND termdate < curdate() GROUP BY term_year
)
SELECT h.hire_year, h.no_hires, t.no_terms, ((h.no_hires-t.no_terms)/h.no_hires)*100 
FROM hires h INNER JOIN terminations t ON h.hire_year = t.term_year
ORDER BY h.hire_year ASC;  # CHECK THE CORRECTNESS OF THIS QUERY
# WRONG BECAUSE OF HIRE_DATE HAS TOTAL EMP INFO BUT TERMDATE DONT HAVE

# USING SUBQUERY
SELECT * FROM hr;
SELECT year, hires, terminations, (hires-terminations) AS net_change, ((hires-terminations)/hires)*100 AS per_net_change
FROM (
SELECT YEAR(hire_date) year, COUNT(*) hires, SUM(CASE WHEN termdate<>'0000-00-00' AND termdate<curdate() THEN 1 ELSE NULL END) terminations
FROM hr GROUP BY year
) net_change
GROUP BY year ORDER BY year ASC;

-- 11. TENURE DISTRIBUTION FOR EACH DEPARTMENT? 
SELECT department, ROUND(AVG(DATEDIFF(termdate, hire_date)/365),0) AS tenure
FROM hr WHERE termdate <> '0000-00-00' AND termdate<curdate()
GROUP BY department;










