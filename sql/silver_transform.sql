-- silver_transform.sql
-- Objetivo: Limpiar datos y cargar de forma incremental (evitando duplicados)

-- 0. Asegurar que la tabla externa lea Parquet y soporte particionado Hive
CREATE OR REPLACE EXTERNAL TABLE `mci506-futbol-europeo.liga_bonze.tbl_matches`
WITH PARTITION COLUMNS (year STRING, month STRING, day STRING)
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://mci506-futbol-europeo-bronze/bronze/football_data/matches/*'],
  hive_partition_uri_prefix = 'gs://mci506-futbol-europeo-bronze/bronze/football_data/matches'
);

-- 0.1 Asegurar que la tabla externa de posiciones (standings) lea Parquet y soporte particionado Hive
CREATE OR REPLACE EXTERNAL TABLE `mci506-futbol-europeo.liga_bonze.tbl_standings`
WITH PARTITION COLUMNS (year STRING, month STRING, day STRING)
OPTIONS (
  format = 'PARQUET',
  uris = ['gs://mci506-futbol-europeo-bronze/bronze/football_data/standings/*'],
  hive_partition_uri_prefix = 'gs://mci506-futbol-europeo-bronze/bronze/football_data/standings'
);

-- 1. Crear la tabla nativa
CREATE TABLE IF NOT EXISTS `mci506-futbol-europeo.liga_silver.silver_matches` (
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
INSERT INTO `mci506-futbol-europeo.liga_silver.silver_matches`
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
FROM `mci506-futbol-europeo.liga_bonze.tbl_matches` AS ext
WHERE NOT EXISTS (
    SELECT 1 
    FROM `mci506-futbol-europeo.liga_silver.silver_matches` AS sil
    WHERE sil.match_id = CAST(ext.match_id AS STRING)
)
-- Reglas de validación de calidad de datos (NICE-TO-HAVE)
AND ext.equipo_local IS NOT NULL
AND ext.equipo_visitante IS NOT NULL
AND CAST(ext.goles_local AS INT64) >= 0
AND CAST(ext.goles_visitante AS INT64) >= 0;