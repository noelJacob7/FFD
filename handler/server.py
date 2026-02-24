import flwr as fl
import numpy as np
from keras.models import load_model
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    precision_recall_curve,
    auc,
)
from model import evaluate_thresholds
import requests

# Load pretrained centralized model
try:
    model = load_model("models/initial_lstm_model.keras")
except Exception as e:
    print(f"Error loading model: {e}")
    exit(1)

# Convert weights to Flower parameters
initial_weights = model.get_weights()
initial_parameters = fl.common.ndarrays_to_parameters(initial_weights)


class SaveBestPRStrategy(fl.server.strategy.FedAvg):
    def __init__(self, model, X_test, y_test, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.model = model
        self.X_test = X_test
        self.y_test = y_test
        self.best_prauc = 0

    def aggregate_fit(self, server_round, results, failures):

        aggregated_parameters, aggregated_metrics = super().aggregate_fit(
            server_round, results, failures
        )

        if aggregated_parameters is None:
            return aggregated_parameters, aggregated_metrics

        # Convert parameters to numpy arrays
        weights = fl.common.parameters_to_ndarrays(aggregated_parameters)

        # Set model weights
        self.model.set_weights(weights)

        # Evaluate PR-AUC
        y_probs = self.model.predict(self.X_test, verbose=0).ravel()

        threshold = evaluate_thresholds(y_probs, self.y_test)

        y_pred = (y_probs > threshold).astype(int)

        # Compute metrics
        accuracy = round(accuracy_score(self.y_test, y_pred), 6)
        precision = round(precision_score(self.y_test, y_pred, zero_division=0), 6)
        recall = round(recall_score(self.y_test, y_pred), 6)
        f1 = round(f1_score(self.y_test, y_pred), 6)
        precision_vals, recall_vals, _ = precision_recall_curve(self.y_test, y_probs)
        pr_auc = round(auc(recall_vals, precision_vals), 6)

        print(f"\n==== GLOBAL METRICS - ROUND {server_round} ====")
        print(f"Accuracy:  {accuracy}")
        print(f"Precision: {precision}")
        print(f"Recall:    {recall}")
        print(f"F1 Score:  {f1}")
        print(f"PR-AUC:    {pr_auc}")
        print("====================================\n")

        # Update metrices dictionary
        try:
            payload = {
                "round": server_round,
                "accuracy": float(accuracy),
                "precision": float(precision),
                "recall": float(recall),
                "f1_score": float(f1),
                "pr_auc": float(pr_auc),
            }
            # Sending to your existing Flask app running on 5000
            requests.post(
                "http://localhost:5000/update_metrics", json=payload, timeout=2
            )
        except Exception as e:
            print(f"Flask update failed (is the API running?): {e}")

        if pr_auc > self.best_prauc:
            self.best_prauc = pr_auc
            self.model.save("models/best_federated_model.keras")
            print("Saved new best model")
            requests.post(
                "http://localhost:5000/update_threshold",
                json={"threshold": threshold},
                timeout=2,
            )
        return aggregated_parameters, aggregated_metrics


if __name__ == "__main__":
    try:
        data = np.load("data/test_sequences.npz")
        X_test = data["X"]
        y_test = data["y"]
    except Exception as e:
        print(f"Error loading test dataset: {e}")
        exit(1)

    strategy = SaveBestPRStrategy(
        model=model,
        X_test=X_test,
        y_test=y_test,
        fraction_fit=1.0,
        min_fit_clients=2,
        min_available_clients=2,
        initial_parameters=initial_parameters,
    )

    fl.server.start_server(
        server_address="localhost:8080",
        config=fl.server.ServerConfig(num_rounds=5),
        strategy=strategy,
    )
