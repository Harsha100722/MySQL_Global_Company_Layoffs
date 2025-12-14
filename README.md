# Layoffs Data Cleaning & Preparation – SQL Project

## Project Overview

**Project Title**: Layoffs Data Cleaning and Preparation  
**Level**: Beginner to Intermediate  
**Database**: MySQL  

This project focuses on cleaning and preparing a global layoffs dataset using SQL.  
The objective is to convert raw data into a clean, analysis-ready format by removing duplicates, standardizing values, handling missing data, and correcting data types.

---

## Objectives

- Preserve raw data using staging tables  
- Identify and remove duplicate records  
- Standardize company, industry, and country names  
- Convert date columns to proper DATE format  
- Handle missing and null values  
- Prepare a clean dataset for further analysis  

---

## Dataset Description

The dataset contains information about company layoffs, including:
- Company name  
- Location  
- Industry  
- Total employees laid off  
- Percentage laid off  
- Date of layoffs  
- Company stage  
- Country  
- Funds raised (in millions)  

---

## Step 1: Explore Raw Data

```sql
SELECT * FROM layoffs;
```
## Step 2: Create a Staging Table
```sql
CREATE TABLE layoffs_staging
LIKE layoffs;
```
## Insert Data into Staging Table
```sql
INSERT INTO layoffs_staging
SELECT * FROM layoffs;
```

## Step 3: Identify Duplicate Records
```sql
WITH dup_cte AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY company, location, industry, total_laid_off,
                            percentage_laid_off, `date`, stage, country,
                            funds_raised_millions
           ) AS row_num
    FROM layoffs_staging
)
SELECT *
FROM dup_cte
WHERE row_num > 1;
```

## Step 4: Create a Clean Staging Table
```sql
CREATE TABLE layoffs_staging2 (
  company TEXT,
  location TEXT,
  industry TEXT,
  total_laid_off INT DEFAULT NULL,
  percentage_laid_off TEXT,
  `date` TEXT,
  stage TEXT,
  country TEXT,
  funds_raised_millions INT DEFAULT NULL,
  row_num INT
);
```

## Insert Data with Row Numbers
```sql
INSERT INTO layoffs_staging2
SELECT *,
       ROW_NUMBER() OVER (
           PARTITION BY company, location, industry, total_laid_off,
                        percentage_laid_off, `date`, stage, country,
                        funds_raised_millions
       ) AS row_num
FROM layoffs_staging;
```
## Remove Duplicate Records
```sql
DELETE FROM layoffs_staging2
WHERE row_num > 1;
```

## Step 5: Standardize Data
```sql
UPDATE layoffs_staging2
SET company = TRIM(company);
```
# Standardize Industry Names
```sql
UPDATE layoffs_staging2
SET industry = 'Crypto Currency'
WHERE industry LIKE 'Crypto%';
```
# Standardize Country Names
```sql
UPDATE layoffs_staging2
SET country = 'United States'
WHERE country LIKE 'United States%';
```

# Step 6: Convert Date Format
```sql
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');
```
# Change Column Data Type
```sql
ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;
```

# Step 7: Handle Missing Industry Values
## Convert Empty Strings to NULL
```sql UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';
```
# Populate Missing Industry Using Company Match
```sql
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;
```
# Manual Industry Fixes
```sql
UPDATE layoffs_staging2 SET industry = 'Travel' WHERE company = 'Airbnb';
UPDATE layoffs_staging2 SET industry = 'Transportation' WHERE company = 'Carvana';
UPDATE layoffs_staging2 SET industry = 'Consumer' WHERE company = 'Juul';
```

# Step 8: Remove Invalid Records
```sql
DELETE FROM layoffs_staging2
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;
```

# Step 9: Final Cleanup(Removes the helper column used for duplicate detection)
```sql
ALTER TABLE layoffs_staging2         
DROP COLUMN row_num;
```


### Layoffs Data Exploratory Data Analysis (EDA) – SQL
# 1.Maximum Layoffs & Layoff Percentage
```sql
SELECT 
    MAX(total_laid_off) AS max_laid_off,
    MAX(percentage_laid_off) AS max_percentage_laid_off
FROM layoffs_staging2;
```
# 2.Total Layoffs by Company
```sql
SELECT company, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY company
ORDER BY total_laid_off DESC;
```
# 3.Year-wise Layoffs Trend
```sql
SELECT YEAR(`date`) AS year, SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY year
ORDER BY year DESC;
```
# 4.Top 3 Companies with Most Layoffs per Year
```sql
WITH laid_off AS (
    SELECT 
        company,
        YEAR(`date`) AS years,
        SUM(total_laid_off) AS total_laid
    FROM layoffs_staging2
    GROUP BY company, years
),
industry_rank AS (
    SELECT 
        company,
        years,
        total_laid,
        DENSE_RANK() OVER (
            PARTITION BY years
            ORDER BY total_laid DESC
        ) AS ranking
    FROM laid_off
)
SELECT company, years, total_laid, ranking
FROM industry_rank
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid DESC;
```
# 5.Monthly Layoffs Trend
```sql
SELECT 
    SUBSTRING(`date`, 1, 7) AS month,
    SUM(total_laid_off) AS total_laid_off
FROM layoffs_staging2
GROUP BY month
ORDER BY month DESC;
```
# 6.Rolling (Cumulative) Layoffs Over Time
```sql
WITH date_laid_off AS (
    SELECT 
        SUBSTRING(`date`, 1, 7) AS month,
        SUM(total_laid_off) AS total_laid
    FROM layoffs_staging2
    GROUP BY month
),
sum_date_laid AS (
    SELECT 
        month,
        total_laid,
        SUM(total_laid) OVER (ORDER BY month) AS rolling_layoffs
    FROM date_laid_off
)
SELECT month, total_laid, rolling_layoffs
FROM sum_date_laid
WHERE month IS NOT NULL;
```

## Conclusion
This EDA demonstrates:
Strong use of aggregations
CTEs and window functions
Time-series analysis using SQL
Business-oriented analytical thinking
