# ER Wait-Time Prediction — Linear Regression Summative

## Mission & Problem

Emergency rooms struggle to communicate realistic wait times, which drives patient
frustration and uneven staffing decisions. This project predicts a patient's total ER
wait time from operational context (region, staffing ratios, facility size, urgency,
etc.) so hospital staff can flag visits likely to breach acceptable thresholds and
reallocate nurses/specialists ahead of time.

## Dataset

[ER Wait Time Dataset](https://www.kaggle.com/datasets/pratyushpuri/er-wait-time-dataset-2025-realistic-healthcare-data) (Kaggle) — 5,000 simulated
ER patient visits across multiple hospitals over one year (2024), with 19 columns
covering hospital/region context, staffing (nurse-to-patient ratio, specialist
availability), facility size, urgency level, per-stage timings, and patient outcome/
satisfaction. Local copy: [data/er_wait_time.csv](data/er_wait_time.csv).

## Project Structure

```
linear_regression_model/
├── summative/
│   ├── linear_regression/
│   │   ├── multivariate.ipynb      # EDA, feature engineering, model comparison, loss curve
│   │   └── models/                 # saved best model (joblib)
│   ├── API/
│   │   ├── main.py                 # FastAPI app (predict/retrain/health)
│   │   ├── prediction.py           # feature list + prediction helper
│   │   └── requirements.txt
│   └── FlutterApp/                 # mobile app (single prediction page)
├── pyproject.toml
└── uv.lock
```

## API

- **Public Swagger UI:** https://er-wait-time-api.onrender.com/docs
- **Predict endpoint:** `POST {base_url}/predict`
- **Retrain endpoint:** `POST {base_url}/retrain` (multipart CSV upload, retrains and overwrites the saved model)
- CORS, request/response schema, and range constraints are documented in
  [summative/API/README.md](summative/API/README.md).

Run locally:

```bash
uv sync
uv run uvicorn summative.API.main:app --host 127.0.0.1 --port 8001
# Swagger UI: http://127.0.0.1:8001/docs
```

## Video Demo

`TODO — add YouTube link (max 7 minutes): mobile app predicting + Swagger UI tests + model performance discussion`

## Running the Mobile App (Flutter)

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and run `flutter doctor` to confirm your setup.
2. From `summative/FlutterApp`, fetch packages:
   ```bash
   cd summative/FlutterApp
   flutter pub get
   ```
3. Set the API URL the app should call: open `lib/main.dart` and update the
   `kApiUrl` constant to your deployed Render URL + `/predict` (defaults to
   `http://10.0.2.2:8002/predict` for the Android emulator talking to a locally running
   API on port 8002 — adjust the port to match whatever you pass to `uvicorn --port`).
4. Run on a connected device/emulator:
   ```bash
   flutter run
   ```
5. Fill in all fields and press **Predict** — the predicted wait time (or a validation
   error) appears in the display area below the button.

## Notebook & Model

`uv run jupyter lab summative/linear_regression/multivariate.ipynb` — trains and
compares Linear Regression, SGD (stochastic gradient descent) Regression, Random
Forest, and Decision Tree models, plots the correlation heatmap, target distribution,
before/after best-fit line, train/test loss curve, and saves the best-performing model
by MAE to `summative/linear_regression/models/best_er_wait_model.joblib`.

## Package Management

This repo uses [`uv`](https://docs.astral.sh/uv/) for Python dependency and virtual
environment management (`pyproject.toml` + `uv.lock`). Run `uv sync` to install.
