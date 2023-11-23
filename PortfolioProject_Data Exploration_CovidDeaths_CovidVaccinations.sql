/* Table: CovidDeaths */

-- REMEMBER: 
--ORDER BY expression can be expressed by the nae of the column/ By the index no. of column (for ex: 1,2,3,4,...). 

--However, the same can not be applied to the GROUP BY Expression. 
--GROUP BY Statement must contain the name of the column, and not its index no.
-- All the arguments in the SELECT Statement must be added in the GROUP BY Expression, except mathematic operations of the argument(s). 



Select *
FROM CovidDeaths
WHERE continent is not null
ORDER BY 3,4

-- Data to be used:
--location, date, total_cases, new_cases, total_deaths, population
-- Used (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT)) in the below code in the select statement 
--instead of (total_deaths/total_cases). Because the latter threw an error as "operand data type nvarchar is invalid for divide operator."
--Therefore, first converted the data-type of both into float.

-- Total cases vs. Total Deaths

-- DeathPercentage based on a single country
Select location, date, total_cases,total_deaths, (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT))*100 as DeathPercentage
FROM CovidDeaths
WHERE location like 'India'
ORDER BY 1,2

-- DeathPercentage based on multiple countries:
Select location, date, total_cases,total_deaths, (CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT))*100 as DeathPercentage
FROM CovidDeaths
WHERE location IN ('India','China','Germany')
ORDER BY 1,2

-- Total Cases vs. Population
--  Based on a single country 
Select location, date, total_cases, population, (CAST(total_cases AS FLOAT)/ CAST(population as FLOAT))*100 as PercentagePopulationInfected
FROM CovidDeaths
WHERE location like 'India'
ORDER BY 1,2

-- Countries with Highest infection rate compared to Population
Select location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentagePopulationInfected
FROM CovidDeaths
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC
-- Note: Above, all the arguments in the SELECT Statement must be added in the GROUP BY Expression, 
      -- except mathematic operations of the argument(s). 

-- Countries with Highest Death Count:
Select location, MAX(cast(total_deaths as float)) as HighestDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY HighestDeathCount DESC
-- Note: Above, all the arguments in the SELECT Statement must be added in the GROUP BY Expression, 
      -- except mathematic operations of the argument(s). 

Select location, MAX(cast(total_deaths as float)) as HighestDeathCount
FROM CovidDeaths
WHERE continent is null
GROUP BY location
ORDER BY HighestDeathCount DESC
-- Note: Above, all the arguments in the SELECT Statement must be added in the GROUP BY Expression, 
      -- except argument(s) with mathematic operations. 

-- Continents with Highest Death Count:
Select continent, MAX(cast(total_deaths as float)) as HighestDeathCount
FROM CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY HighestDeathCount DESC


-- Global Numbers
Select /*date*/ SUM(new_cases) as TotalNewCases, SUM(new_deaths) as TotalNewDeaths, 
(SUM(new_deaths)/NULLIF (SUM(new_cases), 0))*100 as NewDeathpercentage
FROM CovidDeaths
WHERE continent is not null
--GROUP BY date 
ORDER BY 1,2
--NULLIF(CAST(total_cases AS FLOAT), 0)) 
---------------------------------------------------------
--Table: CovidVaccinations
Select *
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
 ON dea.location = vac.location
 AND dea.date = vac.date
--ORDER BY 3,4

-- Total Population vs. Vaccinations
-- Here, wanted to sum the data of new_vaccinations based on each location. 
--Therefore, Partition BY was opted to partition the sum of new vaccinations by location. 
-- RollingPeoplevaccinated indicates the sum of new_vaccinations. 
--We could compare columns new_vaccinations and RollingPeoplevaccinated.
--Every time, when the number of new_vaccinations changes, it gets added up to its total previous count and shown as
--actual sum till date in the column RollingPeoplevaccinated.

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeoplevaccinated,
--(RollingPeoplevaccinated/population)*100
-- When the code is executed with (RollingPeoplevaccinated/population)*100, it throws an error.
-- Because, RollingPeoplevaccinated itself is derived by performing operations on actual column in the Table.
--Therefore, it doesn't work in the query and CTE or temp. Tables needs to be generated to consider and execute such derived objects.
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 2,3

-- USE CTE (common table expressions)
-- REMEMBER:
-- No. of columns in the CTE must be equal to the no. of columns in the following select statement.
With PopvsVac (continent, location, date, population, new_vaccinations, RollingPeoplevaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeoplevaccinated
--, RollingPeoplevaccinated/population)*100
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent is not null 
AND dea.population is not null
-- ORDER BY 2,3
)
select *, (RollingPeoplevaccinated/population)*100 as PercentagePopulationVaccinated
FROM PopvsVac
-- select * means all the arguments/column names added in the CTE in With Statement.
-- As seen above, RollingPeoplevaccinated/population)*100 is added in the SELECT Statement of CTE.


-- TEMP. TABLE
DROP TABLE if exists #Temp_PercentagePopulationVaccinated
Create Table #Temp_PercentagePopulationVaccinated
(
continent nvarchar(255), 
location nvarchar(255), 
date datetime, 
population numeric, 
new_vaccinations numeric, 
RollingPeoplevaccinated numeric
)

INSERT INTO #Temp_PercentagePopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeoplevaccinated
--, RollingPeoplevaccinated/population)*100
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent is not null 
AND dea.population is not null
-- ORDER BY 2,3
select *, (RollingPeoplevaccinated/population)*100 as PercentagePopulationVaccinated
FROM #Temp_PercentagePopulationVaccinated


-- Create View to store data for later visualizations	
CREATE VIEW PercentagePopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CAST(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as RollingPeoplevaccinated
--, RollingPeoplevaccinated/population)*100
FROM CovidDeaths as dea
JOIN CovidVaccinations as vac
 ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent is not null 
AND dea.population is not null
-- ORDER BY 2,3