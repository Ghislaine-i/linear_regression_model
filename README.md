# Early-Career Developer Salary Prediction

## 1. Mission and problem

**Mission:** To help early-career developers understand and negotiate their market salaries using experience, education, location, company size, work arrangement, and role.

**Problem:** Early-career developers often do not have a clear estimate of their expected salary, making salary negotiation and career planning difficult.

## 2. Dataset description and source

This project uses the [Stack Overflow Developer Survey 2025](https://survey.stackoverflow.co/2025/). The original dataset contains 49,191 responses.

The data was filtered to include employed developers under 35, salaries between $5,000 and $300,000, complete model features, and experience values within the defined limits. The 12 most common countries were retained. The final filtered dataset contains 5,317 rows.

The eight model input features are `Country`, `WorkExp`, `YearsCode`, `EdLevel`, `OrgSize`, `WorkArrangement`, `DevType`, and `ICorPM`. The target is `salary_k`, which represents annual salary in thousands of US dollars.

## 3. Public Swagger UI

The public API documentation is available here:

[Open Swagger UI](https://linear-regression-model-ikuw.onrender.com/docs)

Swagger UI allows users to test the following endpoints:

- `GET /` — checks API status.
- `POST /predict` — predicts one developer's annual salary.
- `POST /retrain` — accepts a labeled CSV file for model retraining.

## 4. YouTube video demonstration

[Watch the project demonstration](https://youtu.be/DYQFw8BOmys)

## 5. How to run the Flutter mobile application

### Prerequisites

Before running the application, make sure you have:

- Flutter installed and configured.
- Android Studio or an Android device.
- An Android emulator running or a physical Android device connected with USB debugging enabled.
- Python and `uv` installed if you intend to run the API locally.

### Step 1: Start the local API

Open a terminal in the repository root and run:

```powershell
cd summative
uv sync
uv run uvicorn API.prediction:app --host 0.0.0.0 --port 8000 --reload
```

The local API will be available at:

- API status: http://127.0.0.1:8000/
- Swagger documentation: http://127.0.0.1:8000/docs

### Step 2: Configure the API URL

For an Android emulator connecting to your computer's local API, use:

```dart
const String apiUrl = 'http://10.0.2.2:8000/predict';
```

Use the appropriate address depending on where the application is running:

- **Android emulator:** `http://10.0.2.2:8000/predict`
- **Physical Android device:** `http://YOUR_COMPUTER_LOCAL_IP:8000/predict`
- **Deployed application:** Use the public Render API URL.

Make sure the API configuration in `main.dart` matches the environment you are using.

### Step 3: Install Flutter dependencies

Open another terminal in the repository root and run:

```powershell
cd summative\FlutterApp
flutter pub get
```

### Step 4: Check connected devices

Run:

```powershell
flutter devices
```

Choose the device ID displayed in the terminal.

### Step 5: Run the application

Run:

```powershell
flutter run
```

If you want to specify a particular device, use:

```powershell
flutter run -d DEVICE_ID
```

Replace `DEVICE_ID` with the actual ID returned by `flutter devices`.

---

## Project overview

The project contains a regression notebook that explores the data and compares multiple models, a FastAPI service that exposes prediction and retraining endpoints, and a Flutter application that sends developer details to the API.

The four main notebook models are:

- SGDRegressor
- Linear Regression
- Decision Tree Regressor
- Random Forest Regressor

The model with the lowest test MSE is selected and saved for deployment.

## Repository structure

```text
linear_regression_model/
├── README.md
└── summative/
    ├── linear_regression/
    │   └── multivariate.ipynb
    ├── API/
    │   ├── prediction.py
    │   ├── retrain.py
    │   ├── best_model.pkl
    │   ├── pyproject.toml
    │   ├── uv.lock
    │   └── requirements.txt
    ├── FlutterApp/
    │   ├── lib/
    │   │   └── main.dart
    │   ├── android/
    │   ├── ios/
    │   └── pubspec.yaml
    ├── pyproject.toml
    └── uv.lock
```

## Main components

### Regression notebook

[View the regression notebook](summative/linear_regression/multivariate.ipynb)

The notebook filters and prepares the data, analyzes correlations and feature importance, compares the four regression models, creates before-and-after scatter plots, and saves the selected model.

### FastAPI service

- [View the prediction API](summative/API/prediction.py)
- [View the retraining module](summative/API/retrain.py)

The API provides:

- `GET /` for an API status response.
- `POST /predict` for one-sample salary prediction.
- `POST /retrain` for CSV-based model retraining.
- `/docs` for interactive Swagger documentation.

### Flutter application

[View the Flutter application](summative/FlutterApp/)

The application collects the eight model inputs, validates the entered values, sends a JSON request to the API, and displays the annual salary prediction or an error message.

## API local setup

The API dependencies are managed using the project configuration in `summative/pyproject.toml`.

From the repository root, run:

```powershell
cd summative
uv sync
uv run uvicorn API.prediction:app --reload
```

The API will be available at `http://127.0.0.1:8000`.

Swagger documentation is available at `http://127.0.0.1:8000/docs`.

## Retraining data

The retraining endpoint accepts a CSV containing the following eight input features and the target:

- `WorkExp`
- `YearsCode`
- `Country`
- `EdLevel`
- `OrgSize`
- `WorkArrangement`
- `DevType`
- `ICorPM`
- `salary_k`

The uploaded rows are validated before retraining. The preprocessing pipeline processes the new data, and the model is updated so that future predictions can use the updated model.