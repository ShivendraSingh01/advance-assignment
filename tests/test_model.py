import pickle
import pandas as pd

def test_model_prediction():
    with open("model/model.pkl", "rb") as f:
        model = pickle.load(f)

    with open("model/columns.pkl", "rb") as f:
        cols = pickle.load(f)

    df = pd.DataFrame([[0]*len(cols)], columns=cols)

    pred = model.predict(df)

    assert pred[0] in [0, 1]