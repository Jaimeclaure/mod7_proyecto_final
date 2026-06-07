# Football Data Pipeline (MCI-561)

Este proyecto implementa un pipeline de datos ETL/ELT automatizado que extrae información de las 8 ligas de fútbol más importantes de Europa utilizando la API de **Football-Data.org**, procesa y aplana las respuestas en archivos estructurados `.parquet` de forma local, y los carga automáticamente en un Data Lake de **Google Cloud Storage (GCS)** utilizando **GitHub Actions**.

---

## Estructura del Proyecto

El repositorio mantiene una arquitectura modular que separa la lógica de extracción, utilitarios de configuración y los flujos de carga automatizados:

```text
mod7_proyecto_final/
├── .github/
│   └── workflows/
│       └── run_pipeline.yml     # Configuración de automatización diaria (GitHub Actions)
├── data/
│   └── raw/                     # Almacenamiento local temporal (Ignorado en Git)
│       ├── matches/             # Historial de partidos de la temporada (.parquet)
│       ├── players/             # Plantillas de jugadores por club (.parquet)
│       ├── scorers/             # Top 10 máximos goleadores por liga (.parquet)
│       ├── standings/           # Tablas de posiciones históricas (.parquet)
│       └── teams/               # Fichas técnicas e infraestructura de los clubes (.parquet)
├── scripts/
│   ├── extract.py               # Consulta a la API y persistencia local en Parquet
│   └── load.py                  # Escaneo recursivo y carga estructurada a GCS
├── utils.py                     # Centralización de credenciales, clientes GCP y formateo
├── requirements.txt             # Dependencias del entorno de producción
└── .gitignore                   # Blindaje de archivos locales y credenciales (.env)