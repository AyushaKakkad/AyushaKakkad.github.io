---Display of table covid deaths
UPDATE SQLProject..CovidDeaths
SET continent = NULL
WHERE continent = '';

SELECT *
from SQLProject..CovidDeaths
where continent is not null
order by 3,4

---display of columns to be used
SELECT Location, date, total_cases,new_cases,total_deaths,population
from SQLProject..CovidDeaths
order by 1,2

---Death percentage calculation
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    CASE 
        WHEN TRY_CAST(total_cases AS DECIMAL(10, 2)) = 0 THEN NULL
        ELSE (TRY_CAST(total_deaths AS DECIMAL(10, 2)) / TRY_CAST(total_cases AS DECIMAL(10, 2))) * 100
    END AS Death_Percent
FROM 
    SQLProject..CovidDeaths

ORDER BY 1,2

--- Liklihood of death if you catch covid in your country
SELECT 
    location,
    date,
    total_cases,
    total_deaths,
    CASE 
        WHEN TRY_CAST(total_cases AS DECIMAL(10, 2)) = 0 THEN NULL
        ELSE (TRY_CAST(total_deaths AS DECIMAL(10, 2)) / TRY_CAST(total_cases AS DECIMAL(10, 2))) * 100
    END AS Death_Percent
FROM 
    SQLProject..CovidDeaths
WHERE location like '%states'
ORDER BY 1,2

-- Total Cases vs Total Population
--Percentage of population that got covid
SELECT 
    location,
    date,
	population,
    total_cases,
    (TRY_CAST(total_cases AS DECIMAL(10, 2)) / TRY_CAST(population AS DECIMAL(10, 2))) * 100 AS population_percent_infect
FROM 
    SQLProject..CovidDeaths
ORDER BY 1,2

-- Countries with highest infection rate
SELECT 
    location,
	population,
    Max(total_cases) as HighestInfectionCount,
    Max((TRY_CAST(total_cases AS DECIMAL(10, 2)) / TRY_CAST(population AS DECIMAL(10, 2)))) * 100 AS Max_population_infect
FROM 
    SQLProject..CovidDeaths
Group by Location,Population
ORDER BY Max_population_infect desc

-- Countries with lowest infection rate
SELECT 
    location,
	population,
    Min(total_cases) as HighestInfectionCount,
    Min((TRY_CAST(total_cases AS DECIMAL(10, 2)) / TRY_CAST(population AS DECIMAL(10, 2)))) * 100 AS Min_population_infect
FROM 
    SQLProject..CovidDeaths
Group by Location,Population
ORDER BY Min_population_infect 

-- Countries with Highest Death Count based on location
SELECT 
    location,
    MAX(Cast(total_deaths as int)) as HighestDeathCount
FROM 
    SQLProject..CovidDeaths
WHERE continent is null
Group by location
ORDER BY HighestDeathCount desc

-- Countries with Lowest Death Count based on location
SELECT 
    location,
    MIN(Cast(total_deaths as int)) as LowestDeathCount
FROM 
    SQLProject..CovidDeaths
WHERE continent is null
Group by location
ORDER BY LowestDeathCount 

-- Countries with Highest Death Count based on continent
SELECT 
    continent,
    MAX(Cast(total_deaths as int)) as HighestDeathCountConti
FROM 
    SQLProject..CovidDeaths
WHERE continent is not null
Group by continent
ORDER BY HighestDeathCountConti

-- Countries with Lowest Death Count based on continent
SELECT 
    continent,
    MIN(Cast(total_deaths as int)) as LowestDeathCountConti
FROM 
    SQLProject..CovidDeaths
WHERE continent is not null
Group by continent
ORDER BY LowestDeathCountConti

-- Global Numbers wrt date
SELECT 
    date,
    Sum(Try_cast(new_cases as Decimal(10,2))) as total_newcases,
    Sum(try_cast(new_deaths as Decimal(10,2)))as total_newdeaths,
	CASE 
        WHEN Sum(try_CAST(new_cases AS Decimal(10,2))) = 0 THEN NULL
	    ELSE Sum(try_cast(new_deaths as Decimal(10,2)))/Sum(try_cast(new_cases as Decimal(10,2))) *100 
	End as DeathPercent
  
FROM SQLProject..CovidDeaths
Where continent is not null
Group by date
ORDER BY 1,2

---Global numbers 
SELECT 
    Sum(Try_cast(new_cases as Decimal(10,2))) as total_newcases,
    Sum(try_cast(new_deaths as Decimal(10,2)))as total_newdeaths,
	CASE 
        WHEN Sum(try_CAST(new_cases AS Decimal(10,2))) = 0 THEN NULL
	    ELSE Sum(try_cast(new_deaths as Decimal(10,2)))/Sum(try_cast(new_cases as Decimal(10,2))) *100 
	End as DeathPercent
  
FROM SQLProject..CovidDeaths
Where continent is not null
ORDER BY 1,2

-- Join Tables
Select *
From SQLProject..CovidDeaths death
Join SQLProject..CovidVaccinations vac
On death.location = vac.location and death.date = vac.date

--Total Population vs Total Vaccinations available
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations
From SQLProject..CovidDeaths death
Join SQLProject..CovidVaccinations vac
On death.location = vac.location and death.date = vac.date
WHERE death.continent is not null
Order by 2,3

--People Vaccinated based on location 
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER(Partition by death.location ORDER BY death.location,death.date) as PeopleVaccinated
From SQLProject..CovidDeaths death
Join SQLProject..CovidVaccinations vac
On death.location = vac.location and death.date = vac.date
WHERE death.continent is not null
Order by 2,3

--Using Common Table Expression(CTE)
--% of People Vaccinated
With PopuVac (Continent,Location,Date,Population,New_Vaccinations,PeopleVaccinated)
as
(
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations))OVER(Partition by death.location ORDER BY death.location,death.date) as PeopleVaccinated
From SQLProject..CovidDeaths death
Join SQLProject..CovidVaccinations vac
On death.location = vac.location and death.date = vac.date
WHERE death.continent is not null
--Order by 2,3
) 

SELECT 
    *,
    CASE 
        WHEN TRY_CAST(Population AS DECIMAL(10, 2)) = 0 THEN NULL
        ELSE (TRY_CAST(PeopleVaccinated AS DECIMAL(10, 2)) / TRY_CAST(Population AS DECIMAL(10, 2))) * 100 
    END AS PeopleVaccinatedPercent
FROM 
    PopuVac
ORDER BY 
    location, 
    date;


--Create View to store data 
Create View PercentPopulationVaccinated as
Select death.continent, death.location, death.date, death.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER(Partition by death.location ORDER BY death.location,death.date) as PeopleVaccinated
From SQLProject..CovidDeaths death
Join SQLProject..CovidVaccinations vac
On death.location = vac.location and death.date = vac.date
WHERE death.continent is not null
--Order by 2,3

Select *
From PercentPopulationVaccinated