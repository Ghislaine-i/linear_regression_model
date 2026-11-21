"""Retraining logic for the early-career developer salary API."""

import copy
import io
from pathlib import Path

import joblib
import pandas as pd
from fastapi import HTTPException, UploadFile
from pydantic import ValidationError
from sklearn.metrics import mean_squared_error


NUMERIC_COLUMNS = ["WorkExp", "YearsCode"]
CATEGORICAL_COLUMNS = [
    "Country",
    "EdLevel",
    "OrgSize",
    "WorkArrangement",
    "DevType",
    "ICorPM",
]
FEATURE_COLUMNS = NUMERIC_COLUMNS + CATEGORICAL_COLUMNS
TARGET_COLUMN = "salary_k"
RETRAIN_EPOCHS = 5
MAX_UPLOAD_BYTES = 5_000_000


async def retrain_model(
    file: UploadFile,
    state: dict,
    model_path: Path,
    salary_input_type,
) -> dict:
    """Validate uploaded rows, incrementally train a copy, and make it active."""
    if not (file.filename or "").lower().endswith(".csv"):
        raise HTTPException(status_code=400, detail="Please upload a .csv file.")

    content = await file.read()
    if len(content) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="File too large (limit 5 MB).")

    try:
        new_data = pd.read_csv(io.BytesIO(content))
    except Exception:
        raise HTTPException(status_code=400, detail="Could not read the file as a CSV.")

    needed = FEATURE_COLUMNS + [TARGET_COLUMN]
    missing = [column for column in needed if column not in new_data.columns]
    if missing:
        raise HTTPException(
            status_code=422,
            detail=f"Missing columns: {missing}. Required: {needed}",
        )
    if new_data.empty:
        raise HTTPException(status_code=422, detail="The CSV has no rows.")

    problems = []
    valid_rows = []
    for i, record in enumerate(new_data[FEATURE_COLUMNS].to_dict("records")):
        record = {
            key: value.strip() if isinstance(value, str) else value
            for key, value in record.items()
        }
        try:
            valid_rows.append(salary_input_type.model_validate(record).model_dump())
        except ValidationError as error:
            first = error.errors()[0]
            problems.append(f"row {i + 2}: {first['loc'][0]} - {first['msg']}")

    salary = pd.to_numeric(new_data[TARGET_COLUMN], errors="coerce")
    for i in salary[~salary.between(0.001, 1000)].index:
        problems.append(
            f"row {i + 2}: {TARGET_COLUMN} must be a number between 0 and 1000 "
            "(thousands USD)"
        )

    if problems:
        raise HTTPException(
            status_code=422,
            detail={
                "message": f"{len(problems)} problem(s) found. Nothing was changed.",
                "first_problems": problems[:10],
            },
        )

    X_new = pd.DataFrame(valid_rows)[FEATURE_COLUMNS]
    y_new = salary.astype(float)

    candidate = copy.deepcopy(state["model"])
    preprocess = candidate.named_steps["preprocess"]
    estimator = candidate.named_steps["model"]
    if not hasattr(estimator, "partial_fit"):
        raise HTTPException(
            status_code=501,
            detail="The saved model cannot learn incrementally.",
        )

    X_new_processed = preprocess.transform(X_new)
    mse_before = mean_squared_error(y_new, estimator.predict(X_new_processed))
    for _ in range(RETRAIN_EPOCHS):
        estimator.partial_fit(X_new_processed, y_new)
    mse_after = mean_squared_error(y_new, estimator.predict(X_new_processed))

    state["model"] = candidate
    saved = False
    try:
        joblib.dump(candidate, model_path)
        saved = True
    except OSError:
        saved = False

    return {
        "message": "Model updated and now used by /predict.",
        "rows_used": int(len(X_new)),
        "epochs": RETRAIN_EPOCHS,
        "mse_on_new_rows_before": round(mse_before, 1),
        "mse_on_new_rows_after": round(mse_after, 1),
        "saved_to_disk": saved,
    }
