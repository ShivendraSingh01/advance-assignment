import pickle
import pandas as pd


# Load model
with open("model/model.pkl", "rb") as f:
    model = pickle.load(f)

with open("model/columns.pkl", "rb") as f:
    columns = pickle.load(f)


def predict_customer(input_data):
    df = pd.DataFrame([input_data])

    # One-hot encode input
    df = pd.get_dummies(df)

    # Match training columns
    df = df.reindex(columns=columns, fill_value=0)

    prediction = model.predict(df)[0]

    return "Churn" if prediction == 1 else "No Churn"
