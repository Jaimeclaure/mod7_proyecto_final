"""
Módulo de carga. Orquesta la ejecución: llama a extract.py 
y sube los archivos resultantes al bucket de Google Cloud Storage.
"""
import os
from datetime import datetime
from utils import get_gcs_client, setup_logger
from extract import extract_datasets

logger = setup_logger()

def upload_to_gcs(bucket_name: str, source_file_name: str, destination_blob_name: str) -> None:
    """Sube un archivo local a un bucket de GCS."""
    try:
        client = get_gcs_client()
        bucket = client.bucket(bucket_name)
        blob = bucket.blob(destination_blob_name)
        blob.upload_from_filename(source_file_name)
        logger.info(f"✅ Archivo subido: gs://{bucket_name}/{destination_blob_name}")
    except Exception as e:
        logger.error(f"Error al subir el archivo {source_file_name}: {e}")
        raise

def main():
    # El nombre del bucket debe configurarse en las variables de entorno
    bucket_name = os.environ.get("GCS_BUCKET_NAME")
    if not bucket_name:
        logger.error("La variable GCS_BUCKET_NAME no está definida.")
        raise ValueError("La variable GCS_BUCKET_NAME no está definida.")
    
    logger.info("Iniciando fase de Extracción (Bronze)...")
    try:
        files = extract_datasets()
    except Exception as e:
        logger.error("La extracción falló. Abortando carga.")
        return
    
    logger.info("Iniciando fase de Carga a GCS (con particionamiento)...")
    today = datetime.utcnow()
    partition = f"year={today.year}/month={today.month:02d}/day={today.day:02d}"

    for name, local_path in files:
        dest_path = f"bronze/football_data/{name}/{partition}/{name}.parquet"
        upload_to_gcs(bucket_name, local_path, dest_path)
        
    logger.info("Pipeline de ingesta finalizado con éxito.")

if __name__ == "__main__":
    main()