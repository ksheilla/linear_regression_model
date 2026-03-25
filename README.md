# READit — Student Performance Prediction Model

## Mission
My mission is to cultivate a strong reading culture among young people 
in Africa by making reading interactive, social, and accessible through 
technology.

## Problem Statement
Many students in Africa struggle to build consistent reading habits due 
to limited access to engaging platforms and lack of motivation. This model 
predicts student exam performance to help READit identify which factors 
most influence academic success.

## Dataset
- **Source:** Kaggle — Student Performance Dataset
- **Link:** https://www.kaggle.com/datasets/adilshamim8/student-performance-and-learning-style
- **Rows:** 14,003 students

## Models Used
- Linear Regression (SGD Gradient Descent)
- Decision Tree
- Random Forest ← Best Model (R² = 78.30%)

---

## Video Demo
**[YouTube Video Demo](https://youtu.be/V9MCR91DJmA)**

---

## Live API — Swagger UI

**[https://readit-api.onrender.com/docs](https://readit-api.onrender.com/docs)**

### API Endpoints
| Method | Endpoint | Description |
|---|---|---|
| GET | `/` | Health check |
| POST | `/predict` | Predict student exam score |
| POST | `/retrain` | Retrain model with new CSV data |

### Sample Prediction Input
```json
{
  "StudyHours": 19,
  "Attendance": 98,
  "Resources": 1,
  "Motivation": 1,
  "Internet": 1,
  "Discussions": 1,
  "AssignmentCompletion": 71,
  "EduTech": 1
}
```

## Project Structure
```
linear_regression_model/
│
├── summative/
│   ├── linear_regression/
│   │   ├── multivariate.ipynb        
│   │   ├── student_performance.csv   
│   │   └── best_readit_model.pkl    
│   │
│   ├── API/
│   │   ├── prediction.py             
│   │   └── requirements.txt
│   │
│   └── flutterapp/
│       ├── lib/
│       │   └── main.dart             
│       └── pubspec.yaml
```

---

## How to Run the Flutter Mobile App

### Steps

**1. Clone the repository**
```bash
git clone https://github.com/ksheilla/linear_regression_model.git
cd linear_regression_model
```

**2. Navigate to the Flutter app folder**
```bash
cd summative/flutterapp
```

**3. Install dependencies**
```bash
flutter pub get
```

**4. Run the app**
```bash
# For Android device
flutter run -d android

# For iOS device
flutter run -d ios
```

**5. Using the App**
- Fill in all 8 student detail fields
- Press the **Predict** button
- The predicted exam score will appear below with a performance label

## How to Run the API Locally

**1. Navigate to the API folder**
```bash
cd summative/API
```

**2. Install dependencies**
```bash
pip install -r requirements.txt
```

**3. Run the API**
```bash
uvicorn prediction:app --reload
```

**4. Open Swagger UI**
```
http://localhost:8000/docs
```

