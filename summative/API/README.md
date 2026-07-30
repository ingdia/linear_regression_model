# ER Wait-Time Prediction API

This API serves the trained ER wait-time regression model through a simple FastAPI service.

## Endpoints

- GET /health: returns the API health status.
- POST /predict: accepts the required feature fields and returns a predicted wait time in minutes.

## Run locally

From the project root:

```bash
uvicorn summative.API.main:app --host 127.0.0.1 --port 8001
```
