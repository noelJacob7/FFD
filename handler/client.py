import flwr as fl
import numpy as np
import sys
from model import create_model
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    average_precision_score,
)

# Load local dataset
try:
    data = np.load(sys.argv[1])
    X_train = data["X"]
    y_train = data["y"]
except Exception as e:
    print(f"Error loading dataset: {e}")
    exit(1)


SEQ_LEN = X_train.shape[1]
NUM_FEATURES = X_train.shape[2]

# Create model architecture only
model = create_model(SEQ_LEN, NUM_FEATURES)


class FraudClient(fl.client.NumPyClient):

    def get_parameters(self, config):
        return model.get_weights()

    def fit(self, parameters, config):

        model.set_weights(parameters)

        model.fit(
            X_train,
            y_train,
            epochs=2,
            batch_size=256,
            class_weight={0: 1, 1: 20},
            verbose=1,
        )

        # Evaluate locally
        y_probs = model.predict(X_train, verbose=0).ravel()
        threshold = 0.83

        y_pred = (y_probs > threshold).astype(int)

        accuracy = accuracy_score(y_train, y_pred)
        precision = precision_score(y_train, y_pred, zero_division=0)
        recall = recall_score(y_train, y_pred)
        f1 = f1_score(y_train, y_pred)
        pr_auc = average_precision_score(y_train, y_probs)

        print("\n--- CLIENT LOCAL METRICS ---")
        print(f"Accuracy:  {accuracy:.6f}")
        print(f"Precision: {precision:.6f}")
        print(f"Recall:    {recall:.6f}")
        print(f"F1 Score:  {f1:.6f}")
        print(f"PR-AUC:    {pr_auc:.6f}")
        print("-----------------------------\n")

        return model.get_weights(), len(X_train), {}

    def evaluate(self, parameters, config):
        model.set_weights(parameters)
        loss, auc = model.evaluate(X_train, y_train, verbose=1)
        return loss, len(X_train), {"auc": float(auc)}


fl.client.start_numpy_client(
    server_address="localhost:8080",
    client=FraudClient(),
)
