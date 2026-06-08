# Requerimientos del Proyecto — Pipeline de Datos de Fútbol Europeo

---

## 1. Descripción del Proyecto

Este proyecto implementa un **pipeline ETL (Extract, Transform, Load)** automatizado para la ingesta y almacenamiento de datos estadísticos de fútbol europeo. El sistema consume la API pública `football-data.org` (v4), extrae datos de 8 competiciones europeas en 5 entidades distintas, normaliza la estructura JSON anidada a formato tabular y carga los archivos resultantes en **Google Cloud Storage (GCS)** con particionamiento por fecha.

La orquestación del pipeline es gestionada por **GitHub Actions**, ejecutándose diariamente de forma programada y ante eventos de integración continua.

---

## 2. Alcance

### Dentro del alcance

- Extracción de datos mediante la API REST de `football-data.org` v4.
- Cobertura de 8 ligas/competiciones europeas y 5 entidades de datos por liga.
- Normalización y aplanamiento de estructuras JSON anidadas a DataFrames tabulares.
- Almacenamiento local intermedio en formato Parquet (capa staging).
- Carga de datos al bucket de Google Cloud Storage con particionamiento por fecha (`year/month/day`).
- Orquestación automatizada del pipeline mediante GitHub Actions (ejecución diaria y por push).
- Consolidación de datos de todas las ligas en archivos unificados (`all_*.parquet`).

### Fuera del alcance

- Transformaciones avanzadas de datos (capa Silver/Gold en arquitectura Medallion).
- Modelado dimensional o creación de Data Warehouse.
- Dashboards o visualizaciones de datos.
- Carga a bases de datos relacionales o BigQuery.
- Procesamiento en tiempo real (streaming).
- Exposición de datos mediante API REST propia.
- Pruebas automatizadas de calidad de datos (Data Quality).

---

## 3. Requerimientos Funcionales

| ID | Requerimiento |
|----|--------------|
| RF-01 | El sistema debe autenticarse con la API de `football-data.org` mediante token de autenticación por cabecera HTTP (`X-Auth-Token`). |
| RF-02 | El sistema debe extraer datos de **8 competiciones**: Premier League (PL), UEFA Champions League (CL), LaLiga (PD), Serie A (SA), Bundesliga (BL1), Ligue 1 (FL1), Eredivisie (DED) y Primeira Liga (PPL). |
| RF-03 | El sistema debe extraer **5 entidades de datos** por cada competición: Partidos (matches), Posiciones (standings), Equipos (teams), Jugadores (players) y Goleadores (scorers). |
| RF-04 | El sistema debe normalizar las respuestas JSON anidadas a estructuras tabulares planas mediante `pd.json_normalize`. |
| RF-05 | El sistema debe enriquecer cada registro con los campos `liga_codigo` y `liga_nombre` para trazabilidad. |
| RF-06 | El sistema debe extraer el árbitro principal de cada partido desde listas anidadas y almacenarlo como campos `arbitro_principal` y `arbitro_nacionalidad`. |
| RF-07 | El sistema debe vincular cada jugador con su equipo, incluyendo los campos `club_id`, `club_name` y `club_short`. |
| RF-08 | El sistema debe guardar los datos extraídos por liga en archivos Parquet individuales en el directorio local `data/raw/`. |
| RF-09 | El sistema debe generar archivos consolidados (`all_matches.parquet`, `all_standings.parquet`, `all_teams.parquet`, `all_players.parquet`, `all_scorers.parquet`) concatenando los datos de todas las ligas. |
| RF-10 | El sistema debe cargar todos los archivos al bucket de GCS con la estructura de particionamiento: `bronze/football_data/year={YYYY}/month={MM}/day={DD}/`. |
| RF-11 | El sistema debe autenticarse con Google Cloud Platform mediante credenciales de cuenta de servicio (Service Account JSON). |
| RF-12 | El pipeline debe ejecutarse automáticamente **a las 18:00 UTC de lunes a viernes** mediante cron de GitHub Actions. |
| RF-13 | El pipeline debe ejecutarse ante cualquier **push a la rama principal** del repositorio. |
| RF-14 | El sistema debe implementar un mecanismo de **reintentos automáticos** ante respuestas HTTP 429 (rate limit), esperando 60 segundos antes de reintentar. |
| RF-15 | El sistema debe respetar un intervalo de `6 segundos` entre llamadas consecutivas a la API para evitar exceder los límites de tasa. |

---

## 4. Requerimientos No Funcionales

### Rendimiento

- El pipeline completo (extracción + carga) debe finalizar dentro del tiempo límite de ejecución de GitHub Actions (máximo 60 minutos por ejecución).
- El tiempo de espera por solicitud HTTP a la API no debe superar **30 segundos** (timeout configurado).
- La serialización en formato Parquet debe aprovechar el motor **PyArrow** para máxima eficiencia en lectura/escritura.

### Seguridad

- Las credenciales de API (`FOOTBALL_DATA_API_KEY`) y de GCP (`GCP_SA_KEY`) no deben estar almacenadas en el repositorio bajo ninguna circunstancia.
- Las credenciales sensibles deben gestionarse exclusivamente como **GitHub Secrets** en entorno CI/CD y como variables de entorno locales (archivo `.env`, excluido de Git).
- Los archivos `.env`, `.csv`, `.json` y credenciales deben estar listados en `.gitignore`.
- La autenticación con GCS debe realizarse mediante **Service Account** con el principio de mínimo privilegio.

### Escalabilidad

- La arquitectura del script de extracción debe permitir agregar nuevas ligas o competiciones con cambios mínimos de configuración.
- El particionamiento por fecha en GCS debe permitir la ingesta incremental sin sobrescribir datos históricos.

### Mantenibilidad

- El código debe estar modularizado en scripts independientes (`extract.py`, `load.py`, `utils.py`) con responsabilidades bien definidas.
- Las funciones utilitarias compartidas deben centralizarse en `utils.py`.
- Las variables de configuración globales (rutas, nombre de bucket, pausa entre llamadas) deben estar definidas como constantes en el módulo correspondiente.

### Disponibilidad

- El pipeline debe ser capaz de continuar ante fallos parciales por liga individual, registrando el error y continuando con las ligas restantes.
- La ejecución programada diaria garantiza disponibilidad de datos actualizados cada día hábil.

---

## 5. Requerimientos Técnicos

| Componente | Tecnología / Herramienta | Versión |
|------------|--------------------------|---------|
| Lenguaje principal | Python | 3.11 |
| Procesamiento de datos | Pandas | 2.3.3 |
| Serialización columnar | PyArrow | 22.0.0 |
| Cliente HTTP | Requests | 2.32.5 |
| Gestión de variables de entorno | python-dotenv | 1.1.1 |
| Cliente de almacenamiento en nube | google-cloud-storage | 3.4.1 |
| Autenticación GCP | google-auth / OAuth2 Service Account | (incluida en SDK) |
| Orquestación CI/CD | GitHub Actions | Nativo |
| Sistema de control de versiones | Git / GitHub | — |
| Fuente de datos | football-data.org API | v4 |

---

## 6. Requerimientos de Datos

### Fuentes de datos

| Fuente | Tipo | Endpoint Base | Autenticación |
|--------|------|---------------|---------------|
| football-data.org | API REST (JSON) | `https://api.football-data.org/v4/competitions` | Header `X-Auth-Token` |

### Competiciones cubiertas

| Código | Nombre | País/Región |
|--------|--------|-------------|
| `PL` | Premier League | Inglaterra |
| `CL` | UEFA Champions League | Europa |
| `PD` | LaLiga | España |
| `SA` | Serie A | Italia |
| `BL1` | Bundesliga | Alemania |
| `FL1` | Ligue 1 | Francia |
| `DED` | Eredivisie | Países Bajos |
| `PPL` | Primeira Liga | Portugal |

### Entidades de datos extraídas

| Entidad | Descripción | Archivo local | Archivo GCS |
|---------|-------------|---------------|-------------|
| Partidos | Resultados y detalles de encuentros | `matches/matches_{liga}.parquet` | `matches_{liga}.csv` |
| Posiciones | Tabla de clasificación por liga | `standings/standings_{liga}.parquet` | `standings_{liga}.csv` |
| Equipos | Información de clubes participantes | `teams/teams_{liga}.parquet` | `teams_{liga}.csv` |
| Jugadores | Plantillas completas de equipos | `players/players_{liga}.parquet` | `players_{liga}.csv` |
| Goleadores | Ranking de máximos goleadores | `scorers/scorers_{liga}.parquet` | `scorers_{liga}.csv` |

### Formatos de datos

| Capa | Formato | Descripción |
|------|---------|-------------|
| Staging local | Apache Parquet (PyArrow) | Almacenamiento intermedio optimizado en disco |
| Bronze (GCS) | CSV | Datos crudos particionados en la nube |

### Estructura de almacenamiento en GCS

```
gs://{GCS_BUCKET_NAME}/
└── bronze/
    └── football_data/
        └── year={YYYY}/
            └── month={MM}/
                └── day={DD}/
                    ├── matches_pl.csv
                    ├── standings_pl.csv
                    ├── teams_pl.csv
                    ├── players_pl.csv
                    ├── scorers_pl.csv
                    └── ... (8 ligas × 5 entidades = 40 archivos por ejecución)
```

### Estructura de almacenamiento local

```
data/
└── raw/
    ├── all_matches.parquet
    ├── all_players.parquet
    ├── all_scorers.parquet
    ├── all_standings.parquet
    ├── all_teams.parquet
    ├── matches/         → matches_{liga}.parquet  (8 archivos)
    ├── standings/       → standings_{liga}.parquet (8 archivos)
    ├── teams/           → teams_{liga}.parquet    (8 archivos)
    ├── players/         → players_{liga}.parquet  (8 archivos)
    └── scorers/         → scorers_{liga}.parquet  (8 archivos)
```

### Volumen esperado de datos

| Entidad | Registros estimados por liga | Total estimado (8 ligas) |
|---------|------------------------------|--------------------------|
| Partidos | ~380 por temporada | ~3.040 |
| Posiciones | ~20 equipos | ~160 |
| Equipos | ~20 equipos | ~160 |
| Jugadores | ~500 jugadores | ~4.000 |
| Goleadores | ~20 jugadores | ~160 |

---

## 7. Requerimientos de Infraestructura

### Google Cloud Platform

| Servicio | Propósito | Configuración requerida |
|----------|-----------|------------------------|
| **Google Cloud Storage (GCS)** | Almacenamiento persistente de datos Bronze | Bucket creado con nombre configurable via `GCS_BUCKET_NAME` |
| **Service Account (IAM)** | Autenticación programática con GCP | Cuenta de servicio con rol `Storage Object Admin` sobre el bucket destino |
| **Credenciales JSON** | Clave de autenticación de la cuenta de servicio | Exportada como JSON y almacenada en `GCP_SA_KEY` |

### GitHub Actions

| Recurso | Descripción |
|---------|-------------|
| Runner | `ubuntu-latest` (runner gestionado por GitHub) |
| Python | 3.11 instalado via `actions/setup-python` |
| GCP Auth | Autenticación mediante `google-github-actions/auth` |
| Secrets | `GCP_SA_KEY` y `FOOTBALL_DATA_API_KEY` configurados en el repositorio |

### Entorno local (desarrollo)

| Requisito | Detalle |
|-----------|---------|
| Python | >= 3.11 |
| Acceso a internet | Requerido para consumir la API de football-data.org |
| Archivo `.env` | Variables de entorno configuradas localmente |
| Directorio `data/raw/` | Creado previamente para almacenamiento intermedio |

---

## 8. Dependencias del Proyecto

```text
fastf1==3.8.3
pandas==2.3.3
pyarrow==22.0.0
requests==2.32.5
python-dotenv==1.1.1
google-cloud-storage==3.4.1
```

Instalación:

```bash
pip install -r requirements.txt
```

---

## 9. Variables de Entorno

| Variable | Descripción | Tipo | Requerida |
|----------|-------------|------|-----------|
| `FOOTBALL_DATA_API_KEY` | Token de autenticación para la API de football-data.org | Secreto | Sí |
| `GCP_SA_KEY` | Contenido JSON de las credenciales de la cuenta de servicio de GCP | Secreto | Sí |
| `GCS_BUCKET_NAME` | Nombre del bucket de Google Cloud Storage destino | Variable | Sí |

### Configuración local

Crear un archivo `.env` en la raíz del proyecto:

```dotenv
FOOTBALL_DATA_API_KEY=tu_token_aqui
GCP_SA_KEY={"type": "service_account", "project_id": "...", ...}
GCS_BUCKET_NAME=analisis_liga
```

> **Importante:** El archivo `.env` está excluido del control de versiones mediante `.gitignore`. Nunca debe ser commiteado al repositorio.

### Configuración en GitHub Actions

Las variables deben configurarse como **GitHub Secrets** en:
`Settings → Secrets and variables → Actions → New repository secret`

| Secret | Valor |
|--------|-------|
| `FOOTBALL_DATA_API_KEY` | Token de API de football-data.org |
| `GCP_SA_KEY` | JSON completo de la cuenta de servicio GCP |

---

## 10. Criterios de Aceptación

| ID | Criterio | Verificación |
|----|----------|--------------|
| CA-01 | El script `extract.py` extrae datos de las 8 ligas configuradas sin errores de autenticación ni de conexión. | Ejecución exitosa con código de salida 0; archivos Parquet generados en `data/raw/`. |
| CA-02 | Se generan correctamente los 40 archivos Parquet individuales (8 ligas × 5 entidades) en sus subdirectorios correspondientes. | Verificación de existencia y tamaño mayor a 0 bytes de cada archivo. |
| CA-03 | Se generan los 5 archivos consolidados (`all_*.parquet`) con datos de todas las ligas concatenados. | Cada archivo consolidado contiene el número de registros equivalente a la suma de los 8 archivos individuales. |
| CA-04 | El script `load.py` carga exitosamente todos los archivos al bucket de GCS con la estructura de particionamiento por fecha correcta. | Los archivos son visibles en GCS bajo la ruta `bronze/football_data/year=.../month=.../day=.../`. |
| CA-05 | Las credenciales de API y GCP son leídas exclusivamente desde variables de entorno y no están hardcodeadas en ningún script. | Revisión de código: ningún token ni clave aparece en texto plano en los archivos `.py`. |
| CA-06 | El pipeline de GitHub Actions se ejecuta automáticamente según el cron programado (18:00 UTC) y finaliza con estado `success`. | Historial de ejecuciones en la pestaña Actions del repositorio. |
| CA-07 | El sistema maneja correctamente el rate limiting de la API (HTTP 429) reintentando la solicitud después de 60 segundos sin interrumpir el pipeline. | Simulación o log de respuesta 429 verificando la espera y reintento automático. |
| CA-08 | Los DataFrames generados contienen los campos de enriquecimiento `liga_codigo` y `liga_nombre` en todas las entidades. | Inspección de columnas de un archivo Parquet generado. |
| CA-09 | Los datos de jugadores incluyen los campos de vinculación con el equipo: `club_id`, `club_name` y `club_short`. | Inspección del archivo `players_{liga}.parquet`. |
| CA-10 | El campo `arbitro_principal` es extraído correctamente de la lista de árbitros en los datos de partidos. | Validación de que el campo no esté vacío o nulo en partidos con árbitro asignado. |
| CA-11 | El proyecto no contiene archivos `.env`, credenciales JSON ni datos sensibles en el historial de Git. | Revisión del historial con `git log` y ausencia de secretos en el repositorio remoto. |
| CA-12 | La instalación de dependencias desde `requirements.txt` se completa sin errores de compatibilidad en Python 3.11. | Ejecución de `pip install -r requirements.txt` en entorno limpio con código de salida 0. |
