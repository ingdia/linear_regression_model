# ER Wait-Time Prediction API

This API serves the trained ER wait-time regression model through a simple FastAPI service.

## Endpoints

- GET /health: returns the API health status.
- POST /predict: accepts the required feature fields and returns a predicted wait time in minutes.
- POST /retrain: accepts a CSV upload and retrains/overwrites the saved model (see below).
- GET /docs: interactive Swagger UI for testing all endpoints.

## Run locally

From the project root:

```bash
uvicorn summative.API.main:app --host 127.0.0.1 --port 8001
```

## CORS policy

- **allow_origins**: a small explicit allowlist (localhost/dev origins), not `*` — the API
  should only be callable from known frontends (this repo's Flutter app and local dev
  tools), not from arbitrary third-party sites. Add your deployed app origin here when available.
- **allow_methods**: `GET`, `POST`, `OPTIONS` only — the API never needs `PUT`/`DELETE`/etc.
- **allow_headers**: `Content-Type`, `Authorization`, `Accept` only — the minimum needed
  to send JSON bodies and (future) auth tokens, rather than an unrestricted `*`.
- **allow_credentials**: `True` — reserved for future cookie/session-based auth from the
  allowed origins above.

## Retraining the model

POST `/retrain` accepts a CSV file upload (`multipart/form-data`) with the feature columns and the target column named `Total Wait Time (min)`. Example using `curl`:

```bash
curl -X POST "http://127.0.0.1:8001/retrain" -F "file=@/path/to/er_wait_time.csv"
```

On success the endpoint overwrites the saved model at the repository path and returns JSON with the model path.

## Deploying to Render

This repo includes a [`render.yaml`](../../render.yaml) blueprint at the project root.

1. Push this repo to GitHub.
2. In the Render dashboard: **New > Blueprint**, connect the repo, and Render will read
   `render.yaml` automatically (build command installs `summative/API/requirements.txt`,
   start command runs `uvicorn summative.API.main:app --host 0.0.0.0 --port $PORT`).
   Alternatively create the service manually as a **Web Service** with those same build/
   start commands and root directory left at the repo root.
3. Once deployed, your Swagger UI is at `https://<your-service-name>.onrender.com/docs`.
   Add that URL to the root [README.md](../../README.md) and to `allow_origins` in
   `main.py` if a hosted frontend needs to call it, then to `apiBaseUrl` in
   `summative/FlutterApp/lib/main.dart`.
4. Free-tier Render services spin down when idle — the first request after idling can
   take ~30-60s to respond.
