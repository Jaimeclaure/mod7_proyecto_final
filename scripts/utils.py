"""
Módulo de utilidades para el pipeline de datos.
Maneja la conexión y autenticación con Google Cloud Storage.
"""
from google.cloud import storage
import logging
import sys

def setup_logger() -> logging.Logger:
    """Configura y retorna un logger estandarizado para el pipeline."""
    logger = logging.getLogger("mci506_pipeline")
    logger.setLevel(logging.INFO)
    if not logger.handlers:
        handler = logging.StreamHandler(sys.stdout)
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    return logger

def get_gcs_client() -> storage.Client:
    """
    Inicializa y retorna el cliente de Google Cloud Storage.
    Utiliza Application Default Credentials (ADC) provistas por WIF.
    """
    return storage.Client()