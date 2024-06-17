Select *
From CovidDeaths
WHERE continent != ''
order by 3,4

-- Select Data that we are going to start with

Select location, `date`, total_cases, new_cases, total_deaths, population
From CovidDeaths
WHERE continent != ''
order by location , `date` 

-- total cases vs total deaths in Egypt : 
-- shows the probability of an individual dying if they has Covid in Egypt 

CREATE view if not exists egypt_death_percent as
Select location, `date`, total_cases,  total_deaths, (total_deaths/total_cases)*100 as death_percetage
From CovidDeaths
WHERE location = 'Egypt' 
and  continent != '' 
order by location , `date` 

SELECT * FROM egypt_death_percent edp 

-- total cases vs population in Egypt
-- shows the probability of an individual catching Covid in Egypt

Select location, `date`, total_cases,  population, (total_cases/population)*100 as cases_percentage
From CovidDeaths
WHERE location = 'Egypt'
AND continent != ''
order by location , `date` 

Select Location, Population,date, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by Location, Population, date
order by PercentPopulationInfected desc


-- Contries with highest infection rate compared to population
CREATE view if not exists infection_percentage as
Select location, population ,date, MAX(total_cases),  Max((total_cases/population))*100 as PercentPopulationInfected
From CovidDeaths
Group by location, population ,`date` 
order by PercentPopulationInfected DESC 

SELECT * FROM infection_percentage
-- Contries with highest death count compared to population

Select location, MAX(total_deaths) as total_deaths_count 
From CovidDeaths
WHERE continent != ''
GROUP BY location
order by total_deaths_count DESC 

-- continents with highest deaths count

SELECT continent, max(total_deaths) as total_deaths_count
FROM CovidDeaths 
where continent != ''
GROUP BY continent 
ORDER BY total_deaths_count DESC 


-- global stats per day

SELECT 
	location,
    `date`, 
     SUM(new_cases) AS total_cases_per_day, 
     SUM(new_deaths) AS total_deaths_per_day , 
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS death_rate_percentage
FROM CovidDeaths
WHERE continent != '' 
GROUP BY location, `date` 
HAVING total_deaths_per_day != 0
ORDER BY location, `date`, total_cases_per_day DESC;


-- overall global stats

SELECT 
     SUM(new_cases) AS total_cases_per_day, 
     SUM(new_deaths) AS total_deaths_per_day , 
    (SUM(new_deaths) / SUM(new_cases)) * 100 AS death_rate_percentage
FROM CovidDeaths
WHERE continent != '' 
HAVING total_deaths_per_day != 0
ORDER BY 1,2;

-- CTE for people vaccinated
-- looking at total population compared to total people vaccinated
with population_vaccinated (continent,location, date, population, new_vaccinations, comulative_people_vaccinated)
as
(
SELECT 
    de.continent, 
    de.location, 
    de.`date`, 
    de.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY de.location ORDER BY de.`date`) AS comulative_people_vaccinated
FROM CovidDeaths AS de
JOIN CovidVaccinations AS vac
    ON de.location = vac.location
    AND de.`date` = vac.`date`
WHERE de.continent != '' 
)

SELECT * , (comulative_people_vaccinated/population)*100 as comulative_people_vaccinated_percentage
FROM population_vaccinated

-- temp table for vaccinated people penrcetage 

CREATE TABLE if not exists percent_population_vaccinated (
    continent NVARCHAR(255),
    location NVARCHAR(255),
    date DATE,
    population NUMERIC,
    new_vaccination NUMERIC,
    cumulative_people_vaccinated NUMERIC
);

INSERT INTO percent_population_vaccinated (continent, location, date, population, new_vaccination, cumulative_people_vaccinated)
SELECT 
    de.continent, 
    de.location, 
    de.`date`, 
    de.population, 
    NULLIF(vac.new_vaccinations, '') AS new_vaccinations,
    SUM(NULLIF(vac.new_vaccinations, '')) OVER (PARTITION BY de.location ORDER BY de.`date`) AS cumulative_people_vaccinated
FROM CovidDeaths AS de
JOIN CovidVaccinations AS vac
    ON de.location = vac.location
    AND de.`date` = vac.`date`
WHERE de.continent != '';


SELECT * , (cumulative_people_vaccinated/population)*100 as comulative_people_vaccinated_percentage
FROM percent_population_vaccinated

-- creating a view to store data for later visualizations

CREATE VIEW if not exists Vaccinated_people_percent as 
SELECT 
    de.continent, 
    de.location, 
    de.`date`, 
    de.population, 
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (PARTITION BY de.location ORDER BY de.`date`) AS comulative_people_vaccinated
FROM CovidDeaths AS de
JOIN CovidVaccinations AS vac
    ON de.location = vac.location
    AND de.`date` = vac.`date`
WHERE de.continent != '' 

SELECT * FROM vaccinated_people_percent vpp 
