select * 
from Portfolioproject..CovidDeath$
order by location,date

---select data for analysis
select continent, Location, Date, population, total_cases, total_deaths
from Portfolioproject..CovidDeath$ 
where continent is not NULL
order by location,date


-----------------------total deaths vs total cases percentage
select continent, Location, Date, population, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_percentage
from Portfolioproject..CovidDeath$ 
where continent is not NULL
order by location,date

-----------------------% of the population infected
select continent, Location, Date, population, total_cases, total_deaths, new_cases,
(total_cases/population)*100 as Infected_percentage
from Portfolioproject..CovidDeath$ 
where continent is not NULL
order by location,date
----------------------Countries with maximum infection rate
select continent, Location, Date, population,
MAX(total_cases/population)*100 as highestinfectionrate
from Portfolioproject..CovidDeath$ 
group by location, Date, population,continent
order by highestinfectionrate DESC
----------------------highest deaths count in the countries
select location, MAX(cast(total_deaths as int)) as Totaldeathcount
from Portfolioproject..CovidDeath$
where continent is not NULL
group by location
order by Totaldeathcount DESC
----------------------looking/Breaking the numbers continent wise
select location, MAX(cast(total_deaths as int)) as Totaldeathcount
from Portfolioproject..CovidDeath$
where continent is  NULL
group by location
order by Totaldeathcount DESC

---------------------- overall Death percentage
select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as Deathpercentage
from Portfolioproject..CovidDeath$
where continent is not null
order by 1,2

----------------Joining the vaccination table data
select * from Portfolioproject..Covidvaccinations$
where continent is not null
order by location
----------------total new cases and new_vaccinations location wise
select D.location,D.date,D.continent, SUM(D.new_cases) as total_new_cases, SUM(cast(V.new_vaccinations as int)) as total_vaccinations from Portfolioproject..CovidDeath$ D
join Portfolioproject..Covidvaccinations$ V
	on D.location = V.location
	and D.date = V.date
group by D.location,D.continent,D.date
having D.continent is not NULL 
order by total_vaccinations,total_new_cases,date DESC

----------------Rolling vaccination figures
select D.location, D.date, D.population, D.continent,V.new_vaccinations,
SUM(cast(V.new_vaccinations as int)) OVER (partition by D.location Order by D.location,D.date) as Rolling_vaccination_figures
from Portfolioproject..CovidDeath$ D
	join Portfolioproject..Covidvaccinations$ V
	on D.location = V.location
	and D.date = V.date
where D.continent is not null
order by 1,2

---------------To perform the caluclations on the partition column 
---------------we use two methods	
				-----1. CTE
				-----2. creating a temporary table
-------------using CTE
with ROLL_VAC_PRCNT (location,date,population,continent,new_vaccinations,Rolling_vaccines)
as(
select D.location, D.date, D.population, D.continent,V.new_vaccinations,
SUM(cast(V.new_vaccinations as int)) OVER (partition by D.location Order by D.location,D.date) as Rolling_vaccination_figures
from Portfolioproject..CovidDeath$ D
	join Portfolioproject..Covidvaccinations$ V
	on D.location = V.location
	and D.date = V.date
where D.continent is not null
)
select *,(Rolling_vaccines/population)*100 as ROLL_VACC_PERCENT from ROLL_VAC_PRCNT
order by location,date

-------------Creating a temporary table
DROP TABLE IF exists ROLL_VACCINES_PERCENT
create Table ROLL_VACCINES_PERCENT(
location nvarchar(255),
Date datetime,
population numeric,
continent nvarchar(255),
new_vaccinations nvarchar(255),
Roll_vaccines_percent numeric
)
------inserting the records into the temporary table created earlier
insert into ROLL_VACCINES_PERCENT
select D.location, D.date, D.population, D.continent,V.new_vaccinations,
SUM(cast(V.new_vaccinations as bigint)) OVER (partition by D.location Order by D.location,D.date) as Rolling_vaccination_figures
from Portfolioproject..CovidDeath$ D
	join Portfolioproject..Covidvaccinations$ V
	on D.location = V.location
	and D.date = V.date

select *, (Roll_vaccines_percent/population)*100 as VACC_PRCNT
from ROLL_VACCINES_PERCENT
order by location,date

------Creating views to fetch the data stored in the final target tables

Create View Vaccinationpercentages as 
select D.location, D.date, D.population, D.continent,V.new_vaccinations,
SUM(cast(V.new_vaccinations as int)) OVER (partition by D.location Order by D.location,D.date) as Rolling_vaccination_figures
from Portfolioproject..CovidDeath$ D
	join Portfolioproject..Covidvaccinations$ V
	on D.location = V.location
	and D.date = V.date
where D.continent is not null

-------New Cases vs vaccinations 
select D.location, D.date, D.continent, D.new_cases,V.new_vaccinations from Portfolioproject..CovidDeath$ D
join Portfolioproject..Covidvaccinations$ V
	on D.location = V.location
	and D.date = V.date
where D.continent is not NULL and new_vaccinations is not NULL
order by location, date
----------------------------------


