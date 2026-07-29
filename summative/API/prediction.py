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
    'Time to Registration (min)',
    'Time to Triage (min)',
    'Time to Medical Professional (min)',
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


def build_feature_frame(payload: dict[str, Any]) -> pd.DataFrame:
    missing = [feature for feature in FEATURE_COLUMNS if feature not in payload]
    if missing:
        raise KeyError(missing[0])

    row = {feature: payload[feature] for feature in FEATURE_COLUMNS}
    for feature in NUMERIC_FEATURES:
        row[feature] = float(row[feature])

    return pd.DataFrame([row])


def predict_wait_time(payload: dict[str, Any]) -> float:
    model = load_model()
    frame = build_feature_frame(payload)
    prediction = model.predict(frame)[0]
    return float(prediction)
