/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

Link to Datasets: https://github.com/MoH-Malaysia/covid19-public (Up to 21 October 2022)
*/

-- Check tables

Select *
From PortfolioProject..cases_state
order by 2,1

Select *
From PortfolioProject..deaths_state
order by 2,1

Select *
From PortfolioProject..vax_state
order by 2,1

Select *
From PortfolioProject..population
order by Convert(int, idxs)


-- Join Cases, Deaths and Population

Select *
From PortfolioProject..cases_state as cas
Join PortfolioProject..population as pop
	On cas.state = pop.state
Full Join PortfolioProject..deaths_state as dea
	On cas.state = dea.state
	and cas.date = dea.date
order by cas.state, cas.date


-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your state
-- Use CTE to perform Calculation on Partition By in previous query

With CasvsDea (date, state, population, new_cases, cumul_cases, new_deaths, cumul_deaths)
as
(
Select cas.date
, cas.state
, CAST(pop.pop as int) as population
, cas.cases_new as new_cases
, SUM(cas.cases_new) OVER (Partition by cas.state Order by cas.state, cas.date) as cumul_cases
, dea.deaths_new_dod as new_deaths
, SUM(CONVERT(float,dea.deaths_new_dod)) OVER (Partition by cas.state Order by cas.state, cas.date) as cumul_deaths
From PortfolioProject..cases_state as cas
Join PortfolioProject..population as pop
	On cas.state = pop.state
Full Join PortfolioProject..deaths_state as dea
	On cas.state = dea.state
	and cas.date = dea.date
)
Select *, (cumul_deaths/cumul_cases)*100 as death_percent
From CasvsDea
Where state in ('Selangor', 'W.P. Kuala Lumpur', 'W.P. Putrajaya')


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
-- Use TEMP TABLE

DROP table if exists #PopulationInfectedDeaths
Create Table #PopulationInfectedDeaths
(
date date,
state nvarchar(255), 
population numeric,
new_cases numeric,
cumul_cases numeric,
new_deaths numeric,
cumul_deaths numeric
)

Insert into #PopulationInfectedDeaths
Select cas.date
, cas.state
, CAST(pop.pop as int) as population
, cas.cases_new as new_cases
, SUM(cas.cases_new) OVER (Partition by cas.state Order by cas.state, cas.date) as cumul_cases
, dea.deaths_new_dod as new_deaths
, SUM(CONVERT(float,dea.deaths_new_dod)) OVER (Partition by cas.state Order by cas.state, cas.date) as cumul_deaths
From PortfolioProject..cases_state as cas
Join PortfolioProject..population as pop
	On cas.state = pop.state
Full Join PortfolioProject..deaths_state as dea
	On cas.state = dea.state
	and cas.date = dea.date

Select *, (cumul_cases/population)*100 as infected_percent
From #PopulationInfectedDeaths
Where state in ('Selangor', 'W.P. Kuala Lumpur', 'W.P. Putrajaya')


-- States with Highest Infection Rate compared to Population

Select state, population, MAX(cumul_cases) as high_infect_count,  Max((cumul_cases/population))*100 as infected_percent
From #PopulationInfectedDeaths
Group by state, population
order by infected_percent desc


-- States with Highest Death Count per Population

Select state, population, MAX(cumul_deaths) as high_death_count,  Max((cumul_deaths/population))*100 as death_percent
From #PopulationInfectedDeaths
Group by state, population
order by death_percent desc


-- Country numbers

Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_Cases)*100 as death_percent
From #PopulationInfectedDeaths


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has completed a full dose, a first booster and a second booster

Select vax.date, vax.state, pop.pop as population
, vax.daily_full as new_full_vax, vax.cumul_full as cumul_full_vax, (CAST(vax.cumul_full as float)/pop.pop)*100 as full_vax_percent
, vax.daily_booster as new_booster_vax, vax.cumul_booster as cumul_booster_vax, (CAST(vax.cumul_booster as float)/pop.pop)*100 as booster_vax_percent
, vax.daily_booster2 as new_booster2_vax, vax.cumul_booster2 as cumul_booster2_vax, (CAST(vax.cumul_booster2 as float)/pop.pop)*100 as booster2_vax_percent
From PortfolioProject..vax_state as vax
Join PortfolioProject..population as pop
	On vax.state = pop.state
order by 2,1


-- Creating View to store data for later visualizations

USE PortfolioProject 
GO 

Create View PercentPopulationVaccinated as 
Select vax.date, vax.state, pop.pop as population
, vax.daily_full as new_full_vax, vax.cumul_full as cumul_full_vax, (CAST(vax.cumul_full as float)/pop.pop)*100 as full_vax_percent
, vax.daily_booster as new_booster_vax, vax.cumul_booster as cumul_booster_vax, (CAST(vax.cumul_booster as float)/pop.pop)*100 as booster_vax_percent
, vax.daily_booster2 as new_booster2_vax, vax.cumul_booster2 as cumul_booster2_vax, (CAST(vax.cumul_booster2 as float)/pop.pop)*100 as booster2_vax_percent
From PortfolioProject..vax_state as vax
Join PortfolioProject..population as pop
	On vax.state = pop.state

Select *
From PercentPopulationVaccinated
