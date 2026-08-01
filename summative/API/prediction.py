from pathlib import Path
from typing import Any

import pandas as pd
import joblib

CATEGORICAL_FEATURES = [
    'Region',
    'Day of Week',
    'Season',
    'Time of Day',
    'Urgency Level',
    'Patient Outcome',
]
NUMERIC_FEATURES = [
    'Nurse-to-Patient Ratio',
    'Specialist Availability',
    'Facility Size (Beds)',
    'Patient Satisfaction',
]
FEATURE_COLUMNS = CATEGORICAL_FEATURES + NUMERIC_FEATURES

MODEL_PATH = (
    Path(__file__).resolve().parents[1] / 'linear_regression' / 'models' / 'best_er_wait_model.joblib'
)


def load_model():
    if not MODEL_PATH.exists():
        raise FileNotFoundError(f'Model not found at {MODEL_PATH}')
    return joblib.load(MODEL_PATH)


def normalize_payload(payload: dict[str, Any]) -> dict[str, Any]:
    if not isinstance(payload, dict):
        raise TypeError('Payload must be a dictionary of feature values')

    missing = [feature for feature in FEATURE_COLUMNS if feature not in payload]
    if missing:
        raise KeyError(missing[0])

    normalized_payload = {feature: payload[feature] for feature in FEATURE_COLUMNS}
    for feature in NUMERIC_FEATURES:
        normalized_payload[feature] = float(normalized_payload[feature])

    return normalized_payload


def build_feature_frame(payload: dict[str, Any]) -> pd.DataFrame:
    normalized_payload = normalize_payload(payload)
    return pd.DataFrame([normalized_payload], columns=FEATURE_COLUMNS)


def predict_wait_time(payload: dict[str, Any]) -> float:
    model = load_model()
    frame = build_feature_frame(payload)
    prediction = model.predict(frame)[0]
    return float(prediction)
