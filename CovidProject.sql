
use CovidDeath_DB;
Select * From covid_deaths;

Select * From covid_vaccinations;

Select location, date, total_cases, new_cases, total_deaths, population
From covid_deaths
Order by 1,2;

Select location, date, total_cases, new_cases, total_deaths, population
From covid_deaths
Where continent is not null
Order by 1,2;

--- Total Cases Vs Total Deaths

Select  location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) as death_percentage
From covid_deaths
order by 1,2;

Alter Table covid_deaths
Alter Column total_cases float;

Alter Table covid_deaths
Alter Column total_deaths float;

Select  location, date, total_cases, total_deaths, ((total_deaths/total_cases)*100) as death_percentage
From covid_deaths
where location like'%states%'
order by 1,2;

--- Total Cases Vs Population (percentage of population that got covid)

Select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From covid_deaths
Where location like '%state%'
order by PercentPopulationInfected desc;

--- Countries With Highest Infection Rate Compared to Population

Select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
From covid_deaths
Where continent is not null
Group by location, population
order by PercentPopulationInfected desc;

--- Countries With The Highest Death Counts per Population
Select  location,  max(cast(total_deaths as int)) as 'Total Death Count'
From covid_deaths
Where continent is not null
Group by location
order by 'Total Death Count' desc;

-- Continent With The Highest Death Count
Select  continent,  max(cast(total_deaths as int)) as 'Total Death Count'
From covid_deaths
Where continent is not null
Group by continent
order by 'Total Death Count' desc;

Select  location,  max(cast(total_deaths as int)) as 'Total Death Count'
From covid_deaths
Where continent is  null
Group by location
order by 'Total Death Count' desc;

--- Global Numbers
Select 
	date, 
	sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
	Case
		When sum(new_cases) = 0 Then 0
		Else sum(cast(new_deaths as int)) *100/ NULLIF(sum(new_cases),0)
	End as 'Death Percentage'	
From covid_deaths
Where 
	cast(new_deaths as int) !=0 or new_deaths is not null 
	And continent is not null 
Group by date
order by 1,2;

Select  
	sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
	Case
		When sum(new_cases) = 0 Then 0.0
		Else sum(cast(new_deaths as int)) / NULLIF(sum(new_cases),0) *100.0
	End as 'Death Percentage'	
From covid_deaths
Where 
	cast(new_deaths as int) !=0 or new_deaths is not null 
	And continent is not null 
order by 1,2;



--- Covid Vaccination Info
Select * From covid_vaccinations;

Select * 
From covid_deaths as cd
Join covid_vaccinations as cv
	On cd.location = cv.location
	and cd.date = cv.date;

--- Total Population vs Vaccination
with PopvsVac (continent, location, date, population, new_vaccinations, total_vaccinations)
as
(
	Select cd.continent, cd.location, cd.date, 
		cd.population, cv.new_vaccinations,
		SUM(cast(cv.new_vaccinations as bigint)) 
		Over (Partition by cd.location 
		Order by cd.location, cd.date
		Rows Between Unbounded Preceding and Current Row) as total_vaccinations
	From covid_deaths as cd
	Join covid_vaccinations as cv
	On cd.location = cv.location
	and cd.date = cv.date
	Where cd.continent is not null
)
Select *, (total_vaccinations/population)*100
From PopvsVac;

--- Temp table

Drop Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
	Continent nvarchar(50),
	Location nvarchar(50),
	Date datetime,
	Population int,
	New_Vaccinations int,
	Total_Vaccinated int
)
Select cd.continent, cd.location, cd.date, 
	cd.population, cv.new_vaccinations,
	SUM(cast(cv.new_vaccinations as bigint)) 
	Over (Partition by cd.location 
	Order by cd.location, cd.date
	Rows Between Unbounded Preceding and Current Row) as total_vaccinations
From covid_deaths as cd
	Join covid_vaccinations as cv
	On cd.location = cv.location
	and cd.date = cv.date
Where cd.continent is not null

Select *, (Total_Vaccinated/Population)*100
From #PercentPopulationVaccinated

--- Create Views

CREATE VIEW Death_Percentage as
Select 
	date, 
	sum(new_cases) as total_cases, 
	sum(cast(new_deaths as int)) as total_deaths, 
	Case
		When sum(new_cases) = 0 Then 0.0
		Else sum(cast(new_deaths as int)) *100.0/ NULLIF(sum(new_cases),0)
	End as [Death Percentage]	
From covid_deaths
Where 
	cast(new_deaths as int) !=0 or new_deaths is not null 
	And continent is not null 
Group by date;

SELECT * FROM Death_Percentage ORDER BY date;


--- Create PercentPopulationVaccinated View
Create View PercentPopulationVaccinated as

Select cd.continent, cd.location, cd.date, 
	cd.population, cv.new_vaccinations,
	SUM(cast(cv.new_vaccinations as bigint)) 
	Over (Partition by cd.location 
	Order by cd.location, cd.date
	Rows Between Unbounded Preceding and Current Row) as total_vaccinations
From covid_deaths as cd
	Join covid_vaccinations as cv
	On cd.location = cv.location
	and cd.date = cv.date
Where cd.continent is not null

Select * From PercentPopulationVaccinated 
Order by date;