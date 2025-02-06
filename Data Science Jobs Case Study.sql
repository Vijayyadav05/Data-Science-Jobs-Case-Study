Create Database Case_Study;
use Case_Study;
Select * from salaries;
/*1.You're a Compensation analyst employed by a multinational corporation. Your Assignment is to Pinpoint Countries 
who give work fully remotely, for the title 'managers’ Paying salaries Exceeding $90,000 USD*/

Select distinct (company_location) as Countries from salaries
where Salary >90000 and remote_ratio=100 and job_title like '%manager%';

/*2.AS a remote work advocate Working for a progressive HR tech startup who place their freshers’ clients IN 
large tech firms. you're tasked WITH Identifying top 5 Country Having  greatest count of large(company size) 
number of companies.*/

Select company_location as Countries,count(*) as cnt from (
Select * from salaries where experience_level = "EN" and company_size="L")
as t
group by company_location
order by cnt desc
limit 5;
    ----------------------------------------
with cte as (
Select * from salaries where experience_level ='EN' and company_size='L')
Select company_location as Countries, count(*) as Cnt
from Cte
group by company_location
order by cnt desc
limit 5;

/*3. Picture yourself AS a data scientist Working for a workforce management platform. Your objective is to 
calculate the percentage of employees. Who enjoy fully remote roles WITH salaries Exceeding $100,000 USD, 
Shedding light ON the attractiveness of high-paying remote positions IN today's job market.*/

Select  round((count(case when remote_ratio=100 then 1 end)/count(*))*100,2)
as '% of remote work employees'
from salaries
where salary>100000;
---------------------------------------------------------------

set @total = (select count(*) from salaries where salary>100000);
set @Count = (select count(*) from salaries where remote_ratio=100 and salary>100000);
set @percent = round(((Select @Count)/(Select @total))*100,2);
Select @percent as '% of remote work employees';

/*4.Imagine you're a data analyst Working for a global recruitment agency. Your Task is to identify the Locations 
where entry-level average salaries exceed the average salary for that job title in market for entry level,
helping your agency guide candidates towards lucrative countries.*/

Select company_location,t.job_title,t.average_per_country,p.average from (
Select company_location, job_title, Avg(salary) as average_per_country from Salaries
where Experience_level = 'EN' group by company_location,job_title) as t
 inner join
(Select job_title, Avg(salary) as Average from salaries where Experience_level='EN'
group by job_title) as p 
on t.job_title=p.job_title where average_per_country > average;
--------------------------------------------------------------------

With filtercountry as (
Select company_location, job_title, Avg(salary) as average_per_country from Salaries
where Experience_level = 'EN' group by company_location,job_title),
filterjob as (
Select job_title, Avg(salary) as Average from salaries where Experience_level='EN'
group by job_title)
Select company_location,fc.job_title,average_per_country,average
from filtercountry as fc
join filterjob as fj on fc.job_title = fj.job_title
where average_per_country > average;

/*5. You've been hired by a big HR Consultancy to look at how much people get paid IN different Countries. 
Your job is to Find out for each job title which Country pays the maximum average salary. This helps you to place 
your candidates IN those countries.*/

Select * from Salaries;
Select company_location,job_title,Average from (
Select *, rank() over (partition by job_title order by Average desc) as r from (
Select company_location,job_title,avg(salary) as Average from Salaries
group by company_location,job_title) as a) as b
where r=1;
  -------------------------------------------------------------------

With  filteravg as (
Select company_location,job_title,avg(salary) as Average from Salaries
group by company_location,job_title),
filterrank as (
Select *, rank() over (partition by job_title order by Average desc) as r
from filteravg)
Select fr.company_location,fr.job_title,fr.Average from filterrank as fr
where r = 1;

/*6.  AS a data-driven Business consultant, you've been hired by a multinational corporation to analyze salary 
trends across different company Locations. Your goal is to Pinpoint Locations WHERE the average salary Has 
consistently Increased over the Past few years (Countries WHERE data is available for 3 years
 Only this and pst two years) providing Insights into Locations experiencing Sustained salary growth.*/
 
 With filterlocation as (					-- Filter locations that have salary data for exactly the last 3 years
 Select company_location,count(distinct work_year) as num_years 
 from salaries where work_year between 2022 and 2024
 group by company_location
 having num_years=3),
 yearlyavgs as (							-- Find the average salary per location per year
 Select company_location, work_year, Avg(salary) as avg_salary
 from salaries 
 where company_location in(select company_location from filterlocation)
 group by company_location,work_year),
 pivotedavgs as (							-- Pivot data to get salary averages for 2022, 2023, and 2024
 Select company_location,
 max(case when work_year =2022 then avg_salary end) as avg_salary_2022,
 max(case when work_year =2023 then avg_salary end) as avg_salary_2023,
 max(case when work_year =2024 then avg_salary end) as avg_salary_2024
 from yearlyavgs
 group by company_location)
 Select company_location,avg_salary_2022,avg_salary_2023,avg_salary_2024  -- Filter locations where salary increased consistently over the 3 years
 from pivotedavgs
 where avg_salary_2024>avg_salary_2023 and avg_salary_2023>avg_salary_2022;
 
 /* 7.	Picture yourself AS a workforce strategist employed by a global HR tech startup. Your missiON is to 
 determINe the percentage of  fully remote work for each experience level IN 2021 and compare it WITH the 
 correspONdINg figures for 2024, highlightINg any significant INcreASes or decreASes IN remote work adoptiON
 over the years.*/
 
 With remotecount2021 as (
 Select experience_level,count(*) as remote_count from 
 salaries where remote_ratio=100 and work_year=2021
 group by experience_level),
 totalcount2021 as (
 select experience_level,count(*) as total_count from
 salaries where work_year=2021
 group by experience_level),
 percent2021 as (
 Select r.experience_level,r.remote_count,t.total_count,
 round((r.remote_count/t.total_count)*100,2) as remote_percent_2021
 from remotecount2021 as r
 inner join totalcount2021 as t on r.experience_level = t.experience_level),
 remotecount2024 as (
 Select experience_level,count(*) as remote_count from 
 salaries where remote_ratio=100 and work_year=2024
 group by experience_level),
 totalcount2024 as (
 select experience_level,count(*) as total_count from
 salaries where work_year=2024
 group by experience_level),
 percent2024 as (
 Select r.experience_level,remote_count,total_count,
 round((remote_count/total_count)*100,2) as remote_percent_2024
 from remotecount2024 as r
 inner join totalcount2024 as t on r.experience_level = t.experience_level)
 Select p1.experience_level,p1.remote_percent_2021,p2.remote_percent_2024
 from percent2021 as p1
 join percent2024 as p2 on p1.experience_level = p2.experience_level;
 
 
 




 