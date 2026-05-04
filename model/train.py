import pickle

from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier

from preprocess import load_and_prepare_data


# Load data
X, y = load_and_prepare_data("data/Telco-Customer-Churn.csv")

# Split
X_train, X_test, y_train, y_test = train_test_split(
    X, y,
    test_size=0.2,
    random_state=42,
    stratify=y
)

# Train model
model = RandomForestClassifier(
    n_estimators=200,
    random_state=42,
    class_weight="balanced"
)

model.fit(X_train, y_train)

# Save model
with open("model/model.pkl", "wb") as f:
    pickle.dump(model, f)

# Save columns
with open("model/columns.pkl", "wb") as f:
    pickle.dump(X.columns.tolist(), f)

print("Model trained and saved.")