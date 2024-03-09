--Cool coding techniques
--Rolling totals
--Drop table statement for alterations to tables to avoid deleting and re-creating when executing multiple times

select *
from Covid..CovidDeaths$
where continent is not null
order by 3,4

--select *
--from Covid..CovidVaccinations$
--order by 3,4

select continent, Location, date, total_cases, new_cases, total_deaths, population
from Covid..CovidDeaths$
where continent is not null
order by 1,2

--Total Cases vs Total Deaths
--Shows likelihood of dying from Covid if infected in USA
select continent, Location, date, total_cases, total_deaths, (Total_deaths/total_cases)*100 as DeathPercentage
from Covid..CovidDeaths$
Where Location like '%states%'
and continent is not null
order by 1,2

--Total Cases vs Population
--Shows percentage that contracted Covid in USA
select continent, Location, date, population, total_cases, (Total_cases/population)*100 as CasePercentage
from Covid..CovidDeaths$
Where Location like '%states%'
and continent is not null
order by 1,2

--Countries with highest infection rate compared to population
select continent, Location, population, max(total_cases) as HighestInfectionCount, max((Total_cases/population))*100 as PercentagePopulationInfected
from Covid..CovidDeaths$
where continent is not null
Group by Location, Population
order by PercentagePopulationInfected desc

--Countries with highest death count per population
select continent, Location, max(cast(total_deaths as int)) as TotalDeathCount
from Covid..CovidDeaths$
where continent is not null
Group by Location
order by TotalDeathCount desc

--Continents with highest death count per population
select location, max(cast(total_deaths as int)) as TotalDeathCount
from Covid..CovidDeaths$
where continent is null
Group by location
order by TotalDeathCount desc

--OR

select continent, max(cast(total_deaths as int)) as TotalDeathCount
from Covid..CovidDeaths$
where continent is not null
Group by continent
order by TotalDeathCount desc

--Global Numbers
select date, sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(New_deaths as int))/sum(new_cases)*100 as DeathPercentage
from Covid..CovidDeaths$
Where continent is not null
group by date
order by 1,2

--Global number of total deaths
select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(New_deaths as int))/sum(new_cases)*100 as DeathPercentage
from Covid..CovidDeaths$
Where continent is not null
order by 1,2

--Total population vs Vaccinations
--Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, 
	dea.date) as RollingPeopleVaccinated
from covid..CovidDeaths$ dea
join covid..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3

--Using CTE to perform Calculation on Partition By in previous query
;With PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVacccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, 
	dea.date) as RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
from covid..CovidDeaths$ dea
join covid..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3
)

Select *
--, (RollingPeopleVaccinated/Population)*100 as RollingPercentage
From PopvsVac

--TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, 
	dea.date) as RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
from covid..CovidDeaths$ dea
join covid..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as RollingPercentage
From #PercentPopulationVaccinated

--Views for visualization data
Create View GlobalNumbers as
select date, sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(New_deaths as int))/sum(new_cases)*100 as DeathPercentage
from Covid..CovidDeaths$
Where continent is not null
group by date
--order by 1,2

--View for continents with highest death count per population
Create View HighestDeathCountPerPop as
select location, max(cast(total_deaths as int)) as TotalDeathCount
from Covid..CovidDeaths$
where continent is null
Group by location
--order by TotalDeathCount desc

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.Location order by dea.location, 
	dea.date) as RollingPeopleVaccinated
	--, (RollingPeopleVaccinated/population)*100
from covid..CovidDeaths$ dea
join covid..CovidVaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
--order by 2,3

Select *
from PercentPopulationVaccinated

--View for likelihood of dying from Covid if infected in USA
Create View USADeathLikelihoodFromInfection as
select continent, Location, date, total_cases, total_deaths, (Total_deaths/total_cases)*100 as DeathPercentage
from Covid..CovidDeaths$
Where Location like '%states%'
and continent is not null
--order by 1,2

--View for percentage that contracted Covid in USA
Create View USAPercentInfected as
select continent, Location, date, population, total_cases, (Total_cases/population)*100 as CasePercentage
from Covid..CovidDeaths$
Where Location like '%states%'
and continent is not null
--order by 1,2

--View for global number of total deaths
Create View TotalGlobalDeaths as
select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, sum(cast(New_deaths as int))/sum(new_cases)*100 as DeathPercentage
from Covid..CovidDeaths$
Where continent is not null
--order by 1,2

--View for countries with highest infection rate compared to population
Create view HighestInfectionRatePerPopByCountry as
select continent, Location, population, max(total_cases) as HighestInfectionCount, max((Total_cases/population))*100 as PercentagePopulationInfected
from Covid..CovidDeaths$
where continent is not null
--Group by Location, Population
--order by PercentagePopulationInfected desc

--view for countries with highest death count per population
Create view HighestDeathCountPerPopByCountry as
select continent, Location, max(cast(total_deaths as int)) as TotalDeathCount
from Covid..CovidDeaths$
where continent is not null
--Group by Location
--order by TotalDeathCount desc