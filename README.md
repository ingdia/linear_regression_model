# ER Wait-Time Prediction — Linear Regression & Machine Learning Summative


 **YouTube Video Demonstration (7 Minutes):** [https://youtu.be/Y1JEWzF3bZ0](https://youtu.be/Y1JEWzF3bZ0)

---

##  Mission & Problem Statement

Emergency rooms struggle to communicate realistic wait times, driving patient frustration and uneven hospital staffing. This project predicts a patient's total ER wait time in minutes based on operational context (region, staffing ratios, facility size, urgency level, etc.). Hospital staff can flag visits likely to breach acceptable thresholds and reallocate nurses or specialists ahead of time.

---

##  Dataset Overview

- **Source:** [ER Wait Time Dataset (Kaggle)](https://www.kaggle.com/datasets/pratyushpuri/er-wait-time-dataset-2025-realistic-healthcare-data) — 5,000 simulated ER patient visits across multiple hospitals over one year (2024).
- **Features:** 19 columns covering hospital/region context, staffing (nurse-to-patient ratio, specialist availability), facility size (beds), urgency level, per-stage timings, and patient satisfaction.
- **Local Copy:** [data/er_wait_time.csv](data/er_wait_time.csv)

---

##  Project Structure

```text
linear_regression_model/
├── data/
│   └── er_wait_time.csv            # Dataset (5,000 patient records)
├── summative/
│   ├── linear_regression/
│   │   ├── multivariate.ipynb      # EDA, feature engineering, model comparison, loss curves
│   │   └── models/
│   │       └── best_er_wait_model.joblib # Saved production Random Forest pipeline
│   ├── API/
│   │   ├── main.py                 # FastAPI application (/predict, /retrain, /health, CORS)
│   │   ├── prediction.py           # Feature definitions & inference helper
│   │   ├── test_prediction.py      # Automated API tests
│   │   ├── README.md               # API documentation
│   │   └── requirements.txt        # Production API dependencies
│   └── FlutterApp/                 # Cross-platform Mobile App (Neumorphic UI)
│       ├── lib/main.dart           # App UI & HTTP API integration
│       └── pubspec.yaml            # Flutter dependencies
├── pyproject.toml                  # Python project dependencies (uv)
├── uv.lock                         # Locked dependency versions
└── README.md                       # Comprehensive Project README
```

---

##  Production API & Swagger UI

- **Public Live Swagger UI:** [https://er-wait-time-api.onrender.com/docs](https://er-wait-time-api.onrender.com/docs)
- **Predict Endpoint:** `POST https://er-wait-time-api.onrender.com/predict`
- **Retrain Endpoint:** `POST https://er-wait-time-api.onrender.com/retrain` (Multipart CSV upload)
- **Health Check:** `GET https://er-wait-time-api.onrender.com/health`

### Local API Setup & Execution:

```bash
# 1. Install dependencies using uv
uv sync

# 2. Start local FastAPI server on port 8001
uv run uvicorn summative.API.main:app --host 127.0.0.1 --port 8001

# 3. Access local Swagger UI in browser:
# http://127.0.0.1:8001/docs
```

---

##  Mobile App (Flutter)

The mobile app features a **Neumorphic Soft UI** designed with Cherry Cola accents on a soft slate background (`#EAEFF5`).

### How to Run the Flutter Mobile App:

1. **Install Flutter SDK:** Ensure Flutter is installed (`flutter doctor`).
2. **Fetch Dependencies:**
   ```bash
   cd summative/FlutterApp
   flutter pub get
   ```
3. **Configure API URL:** Open [summative/FlutterApp/lib/main.dart](summative/FlutterApp/lib/main.dart) and verify `kApiUrl`:
   - For Android Emulator connecting to local server: `http://10.0.2.2:8001/predict`
   - For iOS Simulator / Desktop / Chrome: `http://127.0.0.1:8001/predict`
   - For Deployed Render Server: `https://er-wait-time-api.onrender.com/predict`
4. **Launch Application:**
   ```bash
   flutter run
   ```

---

## Notebook & Machine Learning Pipeline

The training workflow is implemented in [summative/linear_regression/multivariate.ipynb](summative/linear_regression/multivariate.ipynb).

### ML Pipeline Steps:
1. **Exploratory Data Analysis (EDA):** Feature distribution plotting, correlation heatmap analysis, target distribution inspection.
2. **Preprocessing:**
   - **`OneHotEncoder`**: Converts categorical features (`Region`, `Day_of_Week`, `Season`, `Time_of_Day`, `Urgency_Level`, `Patient_Outcome`) into binary numeric indicators.
   - **`StandardScaler`**: Normalizes continuous numeric features (`Nurse_to_Patient_Ratio`, `Specialist_Availability`, `Facility_Size_Beds`, `Patient_Satisfaction`).
3. **Pipeline Assembly:** Bundles `ColumnTransformer` and estimator into a scikit-learn `Pipeline` to prevent data leakage during train/test splits.
4. **Model Comparison & Evaluation:**
   - **Linear Regression:** MAE ~ 14.8 minutes (higher error due to non-linear feature interactions).
   - **Decision Trees:** MAE ~ 11.2 minutes.
   - **Random Forest Regressor:** MAE ~ 8.4 minutes (lowest error by averaging multiple trees to reduce variance).

The best performing Random Forest model is serialized to [summative/linear_regression/models/best_er_wait_model.joblib](summative/linear_regression/models/best_er_wait_model.joblib).

---



### Technical Questions Answered in Presentation:

#### Q1: Is your Loss High or Low, and what can you do to further reduce it?
> *"Our evaluation loss (MAE ~8.4 min) is low relative to total ER wait time variance. To further reduce loss in healthcare operations, we could:*
> 1. *Collect real-time dynamic features such as current triage queue depth and ambulance arrival rates.*
> 2. *Experiment with advanced gradient boosted ensembles like XGBoost or LightGBM."*

#### Q2: Are there things called Hyperparameters that can help improve performance?
> *"Yes! Hyperparameters are structural configuration parameters set before training (unlike model weights learned from data). For Random Forest, tuning hyperparameters like `n_estimators` (number of trees), `max_depth`, and `min_samples_leaf` using Grid Search optimizes model capacity and prevents overfitting."*

#### Q3: What would happen if you had new data? How would you update model performance in deployment?
> *"When new operational data arrives, real-world distribution drift can degrade model accuracy. To handle this in deployment, our FastAPI backend includes an online `/retrain` endpoint in [API/main.py](summative/API/main.py). Administrators can upload a new CSV dataset via POST `/retrain`. The API automatically re-fits the pipeline and overwrites the saved `best_er_wait_model.joblib` model file without needing server downtime."*

#### Q4: What was the basis of how you configured the CORS Middleware?
> *"In [API/main.py](summative/API/main.py), CORS middleware was configured using `CORSMiddleware` based on security and dev accessibility:*
> - *We allowed local origins via regular expressions (`http://localhost` and `127.0.0.1`) so local mobile emulators and web browsers could make API requests.*
> - *We explicitly whitelisted our Render production URL (`https://er-wait-time-api.onrender.com`).*
> - *We restricted allowed HTTP methods to GET, POST, and OPTIONS to prevent unauthorized endpoint modifications."*

---

##  Dependency & Package Management

This repository uses [`uv`](https://docs.astral.sh/uv/) for Python dependency and virtual environment management (`pyproject.toml` + `uv.lock`).

```bash
# Install uv dependencies
uv sync

# Run Jupyter Lab
uv run jupyter lab summative/linear_regression/multivariate.ipynb

# Run tests
uv run pytest
```
