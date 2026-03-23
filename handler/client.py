import flwr as fl
import numpy as np
import sys, requests
import argparse
from model import create_model, evaluate_thresholds
from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    precision_recall_curve,
    auc,
)


class FraudClient(fl.client.NumPyClient):
    def __init__(self, flask_port):
        self.flask_port = flask_port
        
    def get_parameters(self, config):
        return model.get_weights()

    def fit(self, parameters, config):
        current_round = config.get("server_round", 0)
        print(f"\n[Client] Starting training for Server Round {current_round}")
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
        threshold = evaluate_thresholds(y_probs, y_train)

        y_pred = (y_probs > threshold).astype(int)

        accuracy = round(accuracy_score(y_train, y_pred), 6)
        precision = round(precision_score(y_train, y_pred, zero_division=0), 6)
        recall = round(recall_score(y_train, y_pred), 6)
        f1 = round(f1_score(y_train, y_pred), 6)
        precision_vals, recall_vals, _ = precision_recall_curve(y_train, y_probs)
        pr_auc = round(auc(recall_vals, precision_vals), 6)

        print("\n--- CLIENT LOCAL METRICS ---")
        print(f"Round:  {current_round}")
        print(f"Accuracy:  {accuracy}")
        print(f"Precision: {precision}")
        print(f"Recall:    {recall}")
        print(f"F1 Score:  {f1}")
        print(f"PR-AUC:    {pr_auc}")
        print("-----------------------------\n")

        try:
            payload = {
                "round": current_round,
                "accuracy": float(accuracy),
                "precision": float(precision),
                "recall": float(recall),
                "f1_score": float(f1),
                "pr_auc": float(pr_auc),
            }
            # Send to your existing Flask app running on 5000
            requests.post(
                f"http://localhost:{self.flask_port}/update_metrics", json=payload, timeout=2
            )
        except Exception as e:
            print(f"Flask update failed (is the API running on {self.flask_port}?): {e}")

        return model.get_weights(), len(X_train), {}

    def evaluate(self, parameters, config):
        model.set_weights(parameters)
        loss, auc = model.evaluate(X_train, y_train, verbose=1)
        return loss, len(X_train), {"auc": float(auc)}


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Start the Federated Learning Client.")
    
    # Define our expected arguments
    parser.add_argument("--data", type=str, required=True, help="Path to the local dataset (.npz)")
    parser.add_argument("--server", type=str, default="127.0.0.1:8080", help="Flower server address")
    parser.add_argument("--flask-port", type=int, default=5000, help="Port where the Flask API is running")
    
    args = parser.parse_args()
    print(args)

    # Load local dataset using the argument
    try:
        data = np.load(args.data)
        X_train = data["X"]
        y_train = data["y"]
        print(f"Successfully loaded data from {args.data}")
    except Exception as e:
        print(f"Error loading dataset: {e}")
        exit(1)

    # Initialize variables that depend on the data
    SEQ_LEN = X_train.shape[1]
    NUM_FEATURES = X_train.shape[2]
    model = create_model(SEQ_LEN, NUM_FEATURES)

    fl.client.start_numpy_client(
        server_address=args.server,
        client=FraudClient(flask_port=args.flask_port),
    )