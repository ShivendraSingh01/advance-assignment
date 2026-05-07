from fastapi import FastAPI
from model.predict import predict_customer

app = FastAPI()


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/predict")
def predict(data: dict):
    result = predict_customer(data)
    return {"prediction": result}
