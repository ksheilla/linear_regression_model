import pickle
import numpy as np
import pandas as pd
from fastapi import FastAPI, UploadFile, File, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.ensemble import RandomForestRegressor
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error
import io

# ── Load saved model from Task 1 ──────────────────────────────
with open("best_readit_model.pkl", "rb") as f:
    model_data = pickle.load(f)

model    = model_data["model"]
scaler   = model_data["scaler"]
features = model_data["features"]

# ── App setup ─────────────────────────────────────────────────
app = FastAPI(
    title="READit Student Performance Prediction API",
    description="Predicts student exam scores based on study behavior to support the READit reading app mission.",
    version="1.0.0"
)

# ── CORS Middleware ───────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost",
        "http://localhost:3000",
        "http://localhost:8080",
        "http://localhost:58394",
        "http://127.0.0.1",
        "http://127.0.0.1:8080",
        "http://127.0.0.1:58394",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST"],
    allow_headers=["Content-Type", "Authorization"],
)

# ── Input model with data types and range constraints ─────────
class StudentInput(BaseModel):
    StudyHours: int = Field(..., ge=0, le=24,
        description="Daily study hours (0-24)")
    Attendance: int = Field(..., ge=0, le=100,
        description="Attendance percentage (0-100)")
    Resources: int = Field(..., ge=0, le=1,
        description="Access to resources (0=No, 1=Yes)")
    Motivation: int = Field(..., ge=0, le=1,
        description="Motivated (0=No, 1=Yes)")
    Internet: int = Field(..., ge=0, le=1,
        description="Internet access (0=No, 1=Yes)")
    Discussions: int = Field(..., ge=0, le=10,
        description="Class discussions participation (0-10)")
    AssignmentCompletion: int = Field(..., ge=0, le=100,
        description="Assignment completion rate (0-100)")
    EduTech: int = Field(..., ge=0, le=1,
        description="Uses educational technology (0=No, 1=Yes)")

class PredictionResponse(BaseModel):
    predicted_exam_score: float
    message: str

# ── Health check ──────────────────────────────────────────────
@app.get("/")
def root():
    return {
        "message": "READit Prediction API is running!",
        "docs": "Visit /docs for Swagger UI"
    }

# ── Prediction endpoint ───────────────────────────────────────
@app.post("/predict", response_model=PredictionResponse)
def predict(data: StudentInput):
    try:
        input_df = pd.DataFrame([{
            "StudyHours":           data.StudyHours,
            "Attendance":           data.Attendance,
            "Resources":            data.Resources,
            "Motivation":           data.Motivation,
            "Internet":             data.Internet,
            "Discussions":          data.Discussions,
            "AssignmentCompletion": data.AssignmentCompletion,
            "EduTech":              data.EduTech,
        }])
        input_scaled = scaler.transform(input_df)
        prediction   = model.predict(input_scaled)[0]

        return PredictionResponse(
            predicted_exam_score=round(float(prediction), 2),
            message=f"Predicted exam score is {round(float(prediction), 2)} out of 100"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ── Retrain endpoint ──────────────────────────────────────────
@app.post("/retrain")
async def retrain(file: UploadFile = File(...)):
    try:
        contents = await file.read()
        df = pd.read_csv(io.StringIO(contents.decode("utf-8")))

        # Validate required columns exist
        required_cols = features + ["ExamScore"]
        for col in required_cols:
            if col not in df.columns:
                raise HTTPException(
                    status_code=400,
                    detail=f"Missing column: {col}"
                )

        X = df[features]
        y = df["ExamScore"]

        new_scaler = StandardScaler()
        X_scaled   = new_scaler.fit_transform(X)
        X_train, X_test, y_train, y_test = train_test_split(
            X_scaled, y, test_size=0.2, random_state=42
        )

        new_model = RandomForestRegressor(n_estimators=100, random_state=42)
        new_model.fit(X_train, y_train)
        mse = mean_squared_error(y_test, new_model.predict(X_test))

        # Save retrained model
        with open("best_readit_model.pkl", "wb") as f:
            pickle.dump({
                "model":    new_model,
                "scaler":   new_scaler,
                "features": features
            }, f)

        # Update globals
        global model, scaler
        model  = new_model
        scaler = new_scaler

        return {
            "message":   "Model retrained successfully!",
            "new_mse":   round(mse, 4),
            "rows_used": len(df)
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# ── Run the app ───────────────────────────────────────────────
if __name__ == "__main__":
    import uvicorn
    uvicorn.run("prediction:app", host="0.0.0.0", port=8000, reload=True)