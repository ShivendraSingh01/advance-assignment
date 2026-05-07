import pandas as pd


def load_and_prepare_data(path):
    df = pd.read_csv(path)

    # Remove useless column
    df.drop("customerID", axis=1, inplace=True)

    # Convert TotalCharges
    df["TotalCharges"] = pd.to_numeric(df["TotalCharges"], errors="coerce")

    # Remove nulls
    df.dropna(inplace=True)

    # Encode target
    df["Churn"] = df["Churn"].map({"Yes": 1, "No": 0})

    # One-hot encode categorical columns
    df = pd.get_dummies(df, drop_first=True)

    X = df.drop("Churn", axis=1)
    y = df["Churn"]

    return X, y
