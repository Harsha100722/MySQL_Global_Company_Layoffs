select * from layoffs_staging2;

select max(total_laid_off), max(percentage_laid_off)
from layoffs_staging2;

select * from layoffs_staging2 where percentage_laid_off=1
order by funds_raised_millions desc;

select company,sum(total_laid_off) from 
layoffs_staging2 group by company order by 2 desc;

select location , sum(total_laid_off) from
layoffs_staging2 group by location order by 2 desc;

select country , sum(total_laid_off)
from layoffs_staging2 group by country order by 2 desc;

select Year(`date`) ,sum(total_laid_off)
from layoffs_staging2 group by 1 order by 1 desc;

with laid_off as 
(
select company , Year(`date`) as years,sum(total_laid_off) as total_laid
from layoffs_staging2 group by company,years
),
industry_rank as
(
select company,years, total_laid,
dense_rank() over(partition by years order by total_laid desc) as ranking
from laid_off
)
select company,years, total_laid,ranking
from industry_rank 
WHERE ranking <= 3
AND years IS NOT NULL
ORDER BY years ASC, total_laid DESC;


select substring(date,1,7) as dates,sum(total_laid_off) as total_laid
from layoffs_staging2
group by  dates order by dates desc;

with date_laid_off as
(
select substring(date,1,7) as dates,sum(total_laid_off) as total_laid
from layoffs_staging2
group by  dates order by dates desc
),
sum_date_laid as
(
select dates ,total_laid, sum(total_laid) over(partition by dates) as roll_dates
from date_laid_off 
order by dates asc
)
select dates,total_laid,roll_dates from sum_date_laid 
where dates is not null;