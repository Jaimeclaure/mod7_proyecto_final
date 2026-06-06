-- gold_aggregations.sql
-- Objetivo: Crear vistas o tablas materializadas con KPIs de negocio (Cumpliendo el requisito NICE-TO-HAVE de 2+ tablas)

-- Tabla 1: Resumen General por Liga
CREATE OR REPLACE TABLE `mod7-proyecto-liga.mod7_proyecto_liga.gold_league_kpis` AS
SELECT 
    liga,
    COUNT(match_id) as total_matches_played,
    SUM(home_goals + away_goals) as total_goals_scored,
    ROUND(SUM(home_goals + away_goals) / COUNT(match_id), 2) as avg_goals_per_match
FROM `mod7-proyecto-liga.mod7_proyecto_liga.silver_matches`
WHERE estado = 'FINISHED'
GROUP BY liga
ORDER BY total_goals_scored DESC;

-- Tabla 2: Rendimiento Histórico por Equipo (Local)
CREATE OR REPLACE TABLE `mod7-proyecto-liga.mod7_proyecto_liga.gold_team_performance_home` AS
SELECT 
    equipo_local as team_name,
    COUNT(match_id) as total_home_matches,
    SUM(home_goals) as total_goals_scored_home,
    SUM(CASE WHEN ganador = 'HOME_TEAM' THEN 1 ELSE 0 END) as total_home_wins
FROM `mod7-proyecto-liga.mod7_proyecto_liga.silver_matches`
GROUP BY equipo_local
ORDER BY total_home_wins DESC;