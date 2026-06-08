import json
import logging
import os
from pathlib import Path

import pandas as pd
from dotenv import load_dotenv
from google.cloud import storage
from google.oauth2 import service_account

# 1. DEFINICIÓN DE RUTAS BASE DEL PROYECTO
# ROOT apunta a la raíz del proyecto
ROOT = Path(__file__).resolve().parent
load_dotenv(ROOT / ".env")

# CONSTANTES REQUERIDAS POR LOAD.PY
RAW_DIR = ROOT / "data" / "raw"
RAW_PREFIX = os.getenv("RAW_PREFIX", "raw")
GCS_BUCKET = os.getenv("GCS_BUCKET")


# 2. FUNCIONES UTILITARIAS DEL PROYECTO
def slug(text: str) -> str:
    return (
        str(text)
        .lower()
        .replace(" ", "_")
        .replace("-", "_")
        .replace("/", "_")
        .replace(".", "")
    )


def to_parquet(df: pd.DataFrame, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_parquet(path, index=False, engine="pyarrow")
    print(f"[OK] Archivo generado: {path}")


def setup_logger(name: str = "football_pipeline") -> logging.Logger:
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s [%(levelname)s] %(message)s"
    )

    return logging.getLogger(name)


# 3. CONEXIÓN A GOOGLE CLOUD STORAGE
def get_gcs_client() -> storage.Client:
    gcp_sa_key = os.getenv("GCP_SA_KEY")

    if gcp_sa_key:
        try:
            credentials_info = json.loads(gcp_sa_key)
            credentials = service_account.Credentials.from_service_account_info(credentials_info)

            return storage.Client(
                project=credentials_info["project_id"],
                credentials=credentials
            )
        except Exception as e:
            print(f"⚠️ Error al parsear GCP_SA_KEY: {e}. Intentando cliente por defecto...")

    return storage.Client()


def gcs_client() -> storage.Client:
    return get_gcs_client()