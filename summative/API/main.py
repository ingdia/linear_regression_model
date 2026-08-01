from typing import Any

from fastapi import FastAPI, HTTPException, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field, conint, confloat

import io
import pandas as pd
import joblib

from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestRegressor

from .prediction import FEATURE_COLUMNS, predict_wait_time, MODEL_PATH, CATEGORICAL_FEATURES, NUMERIC_FEATURES

app = FastAPI(title='ER Wait Time Prediction API', version='0.1.0')

# CORS configuration: allow localhost for development and the deployed app origin.
# Reasoning: restrict origins to known hosts to avoid arbitrary cross-origin requests.
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        'http://localhost:8000',
        'http://127.0.0.1:8000',
        'http://localhost:5173',
        # Add your deployed Flutter web or proxy origin here when available
    ],
    allow_credentials=True,
    allow_methods=['GET', 'POST', 'OPTIONS'],
    allow_headers=['Content-Type', 'Authorization', 'Accept'],
)


class PredictionRequest(BaseModel):
    """All fields use underscore-separated names (consistent for Swagger UI, curl, and
    the Flutter app) and are mapped internally to the original dataset column names."""

    # Categorical features (simple string enforcement)
    Region: str = Field(..., min_length=1, description='Urban or Rural')
    Day_of_Week: str = Field(..., min_length=1, description='e.g. Monday')
    Season: str = Field(..., min_length=1, description='Winter, Spring, Summer, or Fall')
    Time_of_Day: str = Field(..., min_length=1, description='e.g. Morning, Afternoon, Evening')
    Urgency_Level: str = Field(..., min_length=1, description='Low, Medium, High, or Critical')
    Patient_Outcome: str = Field(..., min_length=1, description='e.g. Discharged, Admitted')

    # Numeric features with range constraints
    Nurse_to_Patient_Ratio: confloat(ge=0.1, le=50)
    Specialist_Availability: conint(ge=0, le=50)
    Facility_Size_Beds: conint(ge=1, le=10000)
    Patient_Satisfaction: confloat(ge=0, le=5)


@app.get('/health')
def health() -> dict[str, str]:
    return {'status': 'ok'}


@app.post('/predict')
def predict(request: PredictionRequest) -> dict[str, Any]:
    # Convert Pydantic model back to the original payload key names expected by the predictor
    payload = {}
    # categorical fields back to original keys
    payload['Region'] = request.Region
    payload['Day of Week'] = request.Day_of_Week
    payload['Season'] = request.Season
    payload['Time of Day'] = request.Time_of_Day
    payload['Urgency Level'] = request.Urgency_Level
    payload['Patient Outcome'] = request.Patient_Outcome

    # numeric fields use aliases
    payload['Nurse-to-Patient Ratio'] = request.Nurse_to_Patient_Ratio
    payload['Specialist Availability'] = request.Specialist_Availability
    payload['Facility Size (Beds)'] = request.Facility_Size_Beds
    payload['Patient Satisfaction'] = request.Patient_Satisfaction

    try:
        prediction = predict_wait_time(payload)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    except KeyError as exc:
        raise HTTPException(status_code=422, detail=f'Missing required field: {exc}') from exc
    except TypeError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc
    except ValueError as exc:
        raise HTTPException(status_code=422, detail=str(exc)) from exc

    return {
        'prediction_minutes': round(prediction, 2),
        'features_used': FEATURE_COLUMNS,
    }


@app.post('/retrain')
async def retrain_model(file: UploadFile = File(...)) -> dict[str, Any]:
    """Retrain the model from an uploaded CSV file and overwrite the saved model.

    The CSV must contain the feature columns and the target column
    named 'Total Wait Time (min)'. Returns the path where the model was saved.
    """
    content = await file.read()
    try:
        df = pd.read_csv(io.BytesIO(content))
    except Exception as exc:
        raise HTTPException(status_code=400, detail=f'Failed to read CSV: {exc}') from exc

    target_name = 'Total Wait Time (min)'
    missing_features = [c for c in FEATURE_COLUMNS + [target_name] if c not in df.columns]
    if missing_features:
        raise HTTPException(status_code=422, detail=f'Missing columns in uploaded data: {missing_features}')

    X = df[FEATURE_COLUMNS]
    y = df[target_name]

    # Build preprocessor and pipeline similar to the notebook
    preprocessor = ColumnTransformer(
        transformers=[
            ('categorical', OneHotEncoder(handle_unknown='ignore'), CATEGORICAL_FEATURES),
            ('numeric', StandardScaler(), NUMERIC_FEATURES),
        ]
    )

    pipeline = Pipeline([
        ('preprocess', preprocessor),
        ('model', RandomForestRegressor(n_estimators=200, random_state=42, max_depth=12, min_samples_leaf=2)),
    ])

    pipeline.fit(X, y)

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(pipeline, MODEL_PATH)

    return {'status': 'success', 'model_path': str(MODEL_PATH)}
