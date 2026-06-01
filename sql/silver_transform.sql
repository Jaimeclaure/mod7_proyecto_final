-- silver_transform.sql
-- Objetivo: Limpiar datos y cargar de forma incremental (evitando duplicados)

-- 1. Crear la tabla nativa
CREATE TABLE IF NOT EXISTS `mod7-proyecto-liga.mod7_proyecto_liga.silver_matches` (
    match_id STRING,
    liga STRING,
    fecha DATE,
    estado STRING,
    equipo_local STRING,
    equipo_visitante STRING,
    home_goals INT64,
    away_goals INT64,
    ganador STRING
);

-- 2. Lógica Incremental usando WHERE NOT EXISTS y validaciones de calidad de datos
INSERT INTO `mod7-proyecto-liga.mod7_proyecto_liga.silver_matches`
SELECT 
    CAST(match_id AS STRING) as match_id,
    liga,
    CAST(fecha AS DATE) as fecha,
    estado,
    equipo_local,
    equipo_visitante,
    CAST(goles_local AS INT64) as home_goals,
    CAST(goles_visitante AS INT64) as away_goals,
    ganador
FROM `mod7-proyecto-liga.mod7_proyecto_liga.ext_matches` AS ext
WHERE NOT EXISTS (
    SELECT 1 
    FROM `mod7-proyecto-liga.mod7_proyecto_liga.silver_matches` AS sil
    WHERE sil.match_id = CAST(ext.MatchID AS STRING)
)
-- Reglas de validación de calidad de datos (NICE-TO-HAVE)
AND ext.equipo_local IS NOT NULL
AND ext.equipo_visitante IS NOT NULL
AND CAST(ext.goles_local AS INT64) >= 0
AND CAST(ext.goles_visitante AS INT64) >= 0;