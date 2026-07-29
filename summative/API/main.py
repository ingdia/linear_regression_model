from typing import Any

from fastapi import FastAPI, HTTPException

from .prediction import FEATURE_COLUMNS, predict_wait_time

app = FastAPI(title='ER Wait Time Prediction API', version='0.1.0')


@app.get('/health')
def health() -> dict[str, str]:
    return {'status': 'ok'}


@app.post('/predict')
def predict(payload: dict[str, Any]) -> dict[str, Any]:
    try:
        prediction = predict_wait_time(payload)
    except FileNotFoundError as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc
    except KeyError as exc:
        raise HTTPException(status_code=422, detail=f'Missing required field: {exc}') from exc

    return {
        'prediction_minutes': round(prediction, 2),
        'features_used': FEATURE_COLUMNS,
    }
