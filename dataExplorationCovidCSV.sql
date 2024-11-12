--SELECT
--    location,
--    date,
--    total_cases,
--    total_deaths,
--    deathRate
--FROM (
--    SELECT 
--        location,
--        date,
--        total_cases,
--        total_deaths,
--        (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) AS deathRate
--    FROM 
--        [covidDB].[dbo].[CovidDeaths]
--) AS Subquery
--WHERE 
--    location = 'Albania' AND deathRate > 0.06
--ORDER BY 
--    location, date;


--SELECT location , Max(total_deaths) as totalDeathOfCountry
--from [dbo].[CovidDeaths]
--where location = 'united states'
--group by location

--select location,max(cast(total_deaths as int)) as maxDeathOfTheCountry
--from [covidDB].[dbo].[CovidDeaths]
--where continent = ''
--group by location
--order by maxDeathOfTheCountry desc


--SELECT 
--    date,
--    SUM(CAST(new_cases AS INT)) AS totalCases,
--    SUM(CAST(new_deaths AS INT)) AS totalDeaths,
--    SUM(CAST(new_deaths AS float))  / NULLIF(SUM(CAST(new_cases AS float)), 0)*100 AS deathRate
--FROM [covidDB].[dbo].[CovidDeaths]
--WHERE continent <> ''
--GROUP BY date
--ORDER BY date;

--SELECT 
--    SUM(CAST(new_cases AS INT)) AS totalCases,
--    SUM(CAST(new_deaths AS INT)) AS totalDeaths,
--    SUM(CAST(new_deaths AS float))  / NULLIF(SUM(CAST(new_cases AS float)), 0)*100 AS deathRate
--FROM [covidDB].[dbo].[CovidDeaths]
--WHERE continent <> ''



--select dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,
-- SUM(cast(vac.new_vaccinations as int)) OVER (
--        PARTITION BY dea.location 
--        ORDER BY dea.date 
--    ) AS cumulative_vaccinations 

--from [covidDB].[dbo].[CovidDeaths] dea
--join [covidDB].[dbo].[CovidVaccination] vac
--on dea.location=vac.location
--and dea.date=vac.date
--where dea.continent <> ''



--WITH CumulativeVaccinations AS (
--    SELECT 
--        dea.continent,
--        dea.location,
--        dea.date,
--        dea.population,
--        vac.new_vaccinations,
--        SUM(CAST(vac.new_vaccinations AS INT)) OVER (
--            PARTITION BY dea.location 
--            ORDER BY dea.date
--        ) AS cumulative_vaccinations
--    FROM 
--        [covidDB].[dbo].[CovidDeaths] dea
--    JOIN 
--        [covidDB].[dbo].[CovidVaccination] vac
--    ON 
--        dea.location = vac.location
--        AND dea.date = vac.date
--    WHERE 
--        dea.continent <> ''
--)
--SELECT 
--    continent,
--    location,
--    date,
--    population,
--    new_vaccinations,
--    cumulative_vaccinations,
--    CASE 
--        WHEN population = 0 THEN 0
--        ELSE CAST(cumulative_vaccinations AS FLOAT) / population 
--    END AS VaccinationPercentage
--FROM 
--    CumulativeVaccinations;


DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location nvarchar(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingPeopleVaccinated numeric
);

INSERT INTO #PercentPopulationVaccinated
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        TRY_CAST(dea.population AS NUMERIC),  -- Use TRY_CAST for safe conversion
        TRY_CAST(vac.new_vaccinations AS NUMERIC),  -- Use TRY_CAST for safe conversion
        SUM(TRY_CAST(vac.new_vaccinations AS INT)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS cumulative_vaccinations
    FROM 
        [covidDB].[dbo].[CovidDeaths] dea
    JOIN 
        [covidDB].[dbo].[CovidVaccination] vac
    ON 
        dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent <> '';

SELECT *, 
       CASE 
           WHEN Population = 0 THEN 0
           WHEN Population IS NULL THEN 0  -- Handle possible NULL values
           ELSE (RollingPeopleVaccinated / Population) * 100 
       END AS VaccinationPercentage
FROM #PercentPopulationVaccinated;



-- Creating View to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
    SELECT 
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CAST(vac.new_vaccinations AS INT)) OVER (
            PARTITION BY dea.location 
            ORDER BY dea.date
        ) AS cumulative_vaccinations
    FROM 
        [covidDB].[dbo].[CovidDeaths] dea
    JOIN 
        [covidDB].[dbo].[CovidVaccination] vac
    ON 
        dea.location = vac.location
        AND dea.date = vac.date
    WHERE 
        dea.continent <> ''
