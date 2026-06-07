# Documentación de Desarrollo e Incidentes del Proyecto

Este documento resume la evolución arquitectónica del pipeline de datos de fútbol europeo, detallando los bloqueos técnicos a los que nos enfrentamos, las decisiones tomadas para superarlos y la estructura final adoptada.

---

## 1. La Primera Versión: CSVs y el Bloqueo de Seguridad de Google Cloud

Durante la primera iteración del proyecto, construimos un pipeline completamente funcional que operaba de la siguiente manera:
- **Extracción y Carga:** Se extraían los datos de la API y se guardaban y subían al Data Lake utilizando archivos **CSV**.
- **Visualización:** Habíamos logrado conectar exitosamente nuestras tablas con Google Data Studio (ahora Looker Studio), y contábamos con dashboards operativos mostrando las gráficas y KPIs de negocio.

### 🚨 El Incidente de las Llaves JSON
Todo funcionaba bien hasta que intentamos automatizar y escalar el despliegue. Nos encontramos con una pared al intentar generar y descargar la llave `.json` de la Service Account (Cuenta de Servicio) en Google Cloud. 

A pesar de intentar asignarle múltiples roles y permisos de administrador, el botón de descarga simplemente no permitía obtener el archivo. Tras investigar, descubrimos que esto se debía a **nuevas políticas y cambios de seguridad implementados por Google** que se venían desplegando desde el **Google I/O** (hace aproximadamente un par de semanas). Google está forzando fuertemente el abandono de las llaves estáticas (JSON) en favor de métodos de autenticación efímeros por motivos de seguridad.

---

## 2. La Segunda Iteración: Pivoteando a WIF y Parquet

Dado que la ruta tradicional del JSON estaba bloqueada (y era una mala práctica a futuro de todas formas), nos vimos obligados a realizar una nueva iteración profunda del proyecto. Aprovechamos este rediseño forzado no solo para arreglar la autenticación, sino para mejorar radicalmente el formato de almacenamiento.

### Autenticación con Workload Identity Federation (WIF)
Decidimos implementar **Workload Identity Federation** en nuestro flujo de GitHub Actions (`.github/workflows/footbal-pipeline.yml`). 
No fue un camino exento de baches. Al configurarlo, nos topamos con un error de GitHub Actions (`invalid_target`), documentado en nuestro `ERROR_LOG.md`:
> *failed to generate Google Cloud federated token... The target service indicated by the "audience" parameters is invalid.*

Esto ocurrió por pequeños detalles en la configuración de la ruta del proveedor (diferencia entre Project ID y Project Number `1084996365203`). Tras corregir los nombres del Pool (`github-pool`) y el Provider (`github-provider`), logramos que el pipeline se autenticara de forma segura y sin archivos JSON.

### Transición a Parquet
En esta iteración nos enfocamos explícitamente en **desechar los CSVs y trabajar exclusivamente con archivos Parquet**, como se refleja en nuestro `STATUS_LOG.md`. 
Utilizamos la librería `pyarrow` y modificamos `extract.py` para generar estos archivos columnares de forma nativa. Esto nos trajo ventajas inmediatas:
- **Particionado Hive:** En Google Cloud Storage (Capa Bronze) ahora estructuramos los archivos de manera óptima (`bronze/football_data/{tabla}/year=.../month=...`).
- **Rendimiento:** Las tablas externas en BigQuery ahora leen Parquet, reduciendo costos de escaneo de datos.

### Impacto en la Visualización (Looker Studio)
El daño colateral de migrar nuestra capa de almacenamiento (de CSV sin particionar a Parquet con particionado Hive) fue que **se rompió la conexión con nuestras gráficas de Looker Studio**. Las tablas en BigQuery tuvieron que ser recreadas desde cero a través de sentencias DDL (ej. `tbl_matches` y `tbl_standings`), por lo que nos tocó volver a relanzar la conexión en la herramienta de BI y vincular / crear los gráficos nuevamente.

---

## 3. Estructura Actual del Proyecto

Tras superar los incidentes, la arquitectura quedó robusta, segura y automatizada. La estructura actual consta de los siguientes componentes principales:

### 📂 Directorio Local y Scripts
- **`scripts/extract.py`**: Se conecta a la API de `football-data.org`, maneja la paginación/límites (429) y exporta 5 entidades principales a Parquet (`matches`, `standings`, `teams`, `players`, `scorers`) así como archivos consolidados globales.
- **`scripts/load.py`**: Toma los archivos Parquet del directorio `data/raw/` y los carga en el bucket de Google Cloud Storage manteniendo las rutas relativas.
- **`utils.py`**: Funciones auxiliares centralizadas, incluyendo la configuración de GCS y la función `to_parquet` con `pyarrow`.
- **`pipeline.yml`**: Orquesta la ejecución diaria (18:00 UTC) validando mediante WIF.

### ☁️ Capas de Datos (Data Lake & Data Warehouse)
1. **Capa Bronze (GCS & BigQuery):**
   - Datos crudos almacenados como `.parquet` en GCS.
   - Tablas externas en BigQuery (esquema `liga_bonze`) generadas automáticamente.
2. **Capa Silver & Gold (BigQuery):**
   - Transformaciones en SQL (mediante comandos `bq query` automatizados en Actions) para limpiar los datos y generar la tabla `tbl_matches`. 
   - *Pendiente:* Finalizar las transformaciones para la tabla `tbl_standings`.
   - Tablas de KPIs de negocio alojadas en el esquema `liga_gold`.

---

**Conclusión:** Lo que comenzó como un dolor de cabeza ocasionado por los cambios de seguridad de Google I/O, terminó impulsando el proyecto a un estándar mucho más profesional, implementando Workload Identity Federation y consolidando el uso de un Data Lake basado en archivos Parquet particionados.