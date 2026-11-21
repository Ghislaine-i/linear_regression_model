# Early-Career Developer Salary Prediction

## 1. Mission and Problem

**Mission:** To help early-career developers understand and negotiate their market salaries using experience, education, location, company size, work arrangement, and role.

**Problem:** Early-career developers often do not have a clear estimate of their expected salary, making salary negotiation and career planning difficult.

This project uses machine learning to estimate annual salaries based on developer characteristics. The predictions are estimates, not guaranteed market salaries.

## 2. Dataset Description and Source

This project uses the [Stack Overflow Developer Survey 2025](https://survey.stackoverflow.co/2025/). The original dataset contains 49,191 responses.

The data was filtered to include employed developers under 35, salaries between $5,000 and $300,000, complete model features, and experience values within the defined limits. The 12 most common countries were retained. The final filtered dataset contains 5,317 rows.

The eight model input features are:

- `Country`
- `WorkExp`
- `YearsCode`
- `EdLevel`
- `OrgSize`
- `WorkArrangement`
- `DevType`
- `ICorPM`

The target is `salary_k`, which represents annual salary in thousands of US dollars.

### Dataset setup

The processed dataset (`results.csv`) is not included in this repository because of its large file size (approximately 134 MB).

To run the regression notebook:

1. Download the processed dataset from [this Google Drive link](PASTE_YOUR_GOOGLE_DRIVE_LINK_HERE).
2. Place the downloaded file inside `summative/linear_regression/`.
3. Ensure the filename is exactly `results.csv`.
4. Open `multivariate.ipynb` from the `summative/linear_regression/` directory.
5. Run the notebook cells in order.

The repository also includes `schema.csv`, which contains survey question metadata.

## 3. Public Swagger UI

The deployed API documentation is available here:

[Open Public Swagger UI](https://linear-regression-model-ikuw.onrender.com/docs)

The API provides the following endpoints:

- `POST /predict` – Predicts one developer's estimated annual salary.
- `POST /retrain` – Accepts a labeled CSV file for model retraining.

The API status can also be checked directly at:

[API Status](https://linear-regression-model-ikuw.onrender.com/)

## 4. YouTube Video Demonstration

[Watch the project demonstration](https://youtu.be/DYQFw8BOmys)

## 5. How to Run the Flutter Mobile Application

### Prerequisites

Before running the application, make sure you have:

- Flutter SDK installed and configured.
- Dart SDK installed.
- Android Studio or an Android device.
- An Android emulator running or a physical Android device connected with USB debugging enabled.
- Python and `uv` installed if you intend to run the API locally.

### Step 1: Clone the repository

```bash
git clone YOUR_GITHUB_REPOSITORY_URL
cd linear_regression_model
```

### Step 2: Start the API locally (optional)

If you want to use the local API instead of the deployed API, open a terminal in the repository root and run:

```powershell
cd summative/API
uv sync
uv run uvicorn prediction:app --host 0.0.0.0 --port 8000 --reload
```

The local API will be available at:

- API status: http://127.0.0.1:8000/
- Swagger documentation: http://127.0.0.1:8000/docs

Keep this terminal running.

### Step 3: Configure the API URL

Open `summative/FlutterApp/lib/main.dart` and configure the API URL to match your environment.

For the deployed API:

```dart
https://linear-regression-model-ikuw.onrender.com/predict
```

For an Android emulator connecting to your computer's local API:

```dart
http://10.0.2.2:8000/predict
```

For a physical Android device, use your computer's local network IP address:

```dart
http://YOUR_COMPUTER_LOCAL_IP:8000/predict
```

Make sure the API URL in `main.dart` is configured correctly before running the application.

**Note:** Local HTTP connections may require a debug-only Android cleartext traffic configuration. Do not enable unrestricted cleartext traffic in a production build. Using the deployed HTTPS API avoids this local HTTP requirement.

### Step 4: Install Flutter dependencies

Open another terminal in the repository root and run:

```powershell
cd summative/FlutterApp
flutter pub get
```

### Step 5: Check connected devices

Run:

```powershell
flutter devices
```

Choose the device ID displayed in the terminal.

### Step 6: Run the application

Run:

```powershell
flutter run
```

To specify a particular device:

```powershell
flutter run -d DEVICE_ID
```

Replace `DEVICE_ID` with the actual ID returned by `flutter devices`.

Enter the required developer information and select **Predict** to receive an estimated annual salary.

---

## Project Overview

The project contains three main components:

1. A regression notebook that explores the dataset, prepares features, trains and compares multiple models, and saves the selected model.
2. A FastAPI service that exposes prediction and retraining endpoints.
3. A Flutter mobile application that sends developer information to the API and displays salary predictions.

The four regression models compared in the notebook are:

- SGDRegressor
- Linear Regression
- Decision Tree Regressor
- Random Forest Regressor

The model with the lowest test MSE is selected and saved for deployment.

## Repository Structure

```text
linear_regression_model/
├── README.md
├── .gitignore
├── schema.csv
└── summative/
    ├── linear_regression/
    │   ├── multivariate.ipynb
    │   └── results.csv (download separately)
    │
    ├── API/
    │   ├── prediction.py
    │   ├── retrain.py
    │   ├── best_model.pkl
    │   ├── sample_retrain.csv
    │   ├── pyproject.toml
    │   ├── uv.lock
    │   └── requirements.txt
    │
    ├── FlutterApp/
    │   ├── lib/
    │   │   └── main.dart
    │   ├── android/
    │   ├── ios/
    │   └── pubspec.yaml
    │
    ├── pyproject.toml
    └── uv.lock
```

## Main Components

### Regression Notebook

[View the regression notebook](summative/linear_regression/multivariate.ipynb)

The notebook filters and prepares the data, analyzes correlations and feature importance, compares the four regression models, creates before-and-after scatter plots, and saves the selected model.

### FastAPI Service

- [View the prediction API](summative/API/prediction.py)
- [View the retraining module](summative/API/retrain.py)

The API provides:

- `GET /` – Returns an API status message.
- `POST /predict` – Accepts developer information and returns a salary prediction.
- `POST /retrain` – Accepts a labeled CSV file and updates the model.
- `/docs` – Provides interactive Swagger documentation.

### Flutter Application

[View the Flutter application](summative/FlutterApp/)

The application collects the eight model inputs, validates entered values, sends a JSON request to the API, and displays the annual salary prediction or an error message.

## API Local Setup

The API dependencies are managed using the configuration in `summative/API/pyproject.toml`.

From the repository root, run:

```powershell
cd summative/API
uv sync
uv run uvicorn prediction:app --host 0.0.0.0 --port 8000 --reload
```

The API will be available at:

http://127.0.0.1:8000

Swagger documentation is available at:

http://127.0.0.1:8000/docs

## Retraining Data

The repository includes `sample_retrain.csv` inside `summative/API/` for demonstrating the retraining endpoint.

The retraining endpoint accepts a CSV containing the eight model input features and the target:

- `Country`
- `WorkExp`
- `YearsCode`
- `EdLevel`
- `OrgSize`
- `WorkArrangement`
- `DevType`
- `ICorPM`
- `salary_k`

The uploaded rows are validated before retraining. The existing preprocessing pipeline processes the new data, and the model is updated so that subsequent predictions use the updated model.