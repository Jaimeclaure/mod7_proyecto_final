"""Utilities for the project."""

import pandas as pd


def load_parquet(path):
    """Load a parquet file into a DataFrame."""
    return pd.read_parquet(path)
