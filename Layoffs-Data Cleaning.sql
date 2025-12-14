select * from layoffs;

-- creating duplicate table from raw data

create table layoffs_staging
like layoffs;

insert layoffs_staging 
select *from layoffs;

select*from layoffs_staging;

-- removing duplicates

with dup_cte as
(
select * ,
row_number() over(partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging
)
select * from dup_cte
where row_num>1;


CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;


insert into layoffs_staging2 
select * ,
row_number() over(partition by company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions) as row_num
from layoffs_staging;

select*from layoffs_staging2 where row_num>1;

DELETE FROM layoffs_staging2
WHERE row_num > 1;

-- standardizing data

select company,trim(company) from layoffs_staging2;

update layoffs_staging2 
set company=trim(company);

select * from layoffs_staging2 where industry like 'Crypto%';

update layoffs_staging2
set industry='Crypto Currency' where industry like 'Crypto%';

select distinct country from layoffs_staging2 
where country like 'United States%';

update layoffs_staging2 
set country='United States' where country like 'United States%';

update layoffs_staging2 
set `date`=str_to_date(`date`,'%m/%d/%Y');

select `date` from layoffs_staging2;

alter table layoffs_staging2
modify column `date` DATE;

update layoffs_staging2
set industry =null
where industry='';

select t1.industry,t2.industry 
from layoffs_staging2 t1
join layoffs_staging2 t2 
on t1.company=t2.company;

update  layoffs_staging2 t1
join layoffs_staging2 t2
on t1.company=t2.company
set t1.industry=t2.industry
where t1.industry is null 
and t2.industry is not null;

update layoffs_staging2
set industry='Travel' 
where company ='Airbnb';

update layoffs_staging2
set industry='Transportation' 
where company ='Carvana';

update layoffs_staging2
set industry='Consumer' 
where company ='Juul';

select * from layoffs_staging2
where total_laid_off is null and percentage_laid_off is null;

delete from layoffs_staging2
where total_laid_off is null and percentage_laid_off is null;

alter table layoffs_staging2 drop column row_num;