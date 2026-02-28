import flask, json
from flask import request, jsonify
import numpy as np
import random
from keras.models import load_model
import os

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    precision_recall_curve,
    auc,
)
from model import evaluate_thresholds

metrices = {
    "Round": [],
    "Accuracy": [],
    "Precision": [],
    "Recall": [],
    "F1 Score": [],
    "PR-AUC": [],
}

try:
    with open("federated_model_config.json", "r") as conf:
        conf_data = json.load(conf)
    FEDERATED_THRESHOLD = conf_data["threshold"]
except Exception as e:
    print("Error initializing FEDERATED_THRESHOLD:", e)

try:
    with np.load("data/test_sequences.npz") as data:
        # We convert to memory-resident arrays immediately
        X_DATA = data["X"]
        y_DATA = data["y"]
    print("Data loaded successfully.")
except FileNotFoundError:
    print("Error: test_sequences.npz not found.")
    X_DATA, y_DATA = None, None


script_dir = os.path.dirname(os.path.abspath(__file__))
models_path = os.path.join(script_dir, "models")

app = flask.Flask(__name__)


@app.get("/")
def home():
    return "Hello, World!"


@app.get("/get_health")
def health_check():
    return jsonify({"status": "ready"}), 200


@app.post("/update_metrics")
def update_metrics():
    data = request.json

    # Store the incoming data into the global dictionary
    metrices["Round"].append(data["round"])
    metrices["Accuracy"].append(data["accuracy"])
    metrices["Precision"].append(data["precision"])
    metrices["Recall"].append(data["recall"])
    metrices["F1 Score"].append(data["f1_score"])
    metrices["PR-AUC"].append(data["pr_auc"])

    return jsonify({"status": "success"}), 200


@app.post("/update_threshold")
def update_threshold():
    global FEDERATED_THRESHOLD

    data = request.json
    FEDERATED_THRESHOLD = data.get("threshold", FEDERATED_THRESHOLD)

    try:
        with open("federated_model_config.json", "r") as conf:
            conf_data = json.load(conf)
        conf_data["threshold"] = FEDERATED_THRESHOLD
        with open("federated_model_config.json", "w") as conf_file:
            json.dump(conf_data, conf_file, indent=2)
        print(f"Updated threshold to: {FEDERATED_THRESHOLD}")

        return jsonify({"status": "success", "new_threshold": FEDERATED_THRESHOLD}), 200

    except Exception as e:
        print(f"Failed to update config file: {e}")
        return (
            jsonify({"status": "error", "message": "Failed to write to config file"}),
            500,
        )


@app.route("/get_sequences", methods=["GET"])
def get_sequences():
    if X_DATA is None:
        return jsonify({"error": "Data not initialized"}), 500

    fraud_indices = np.where(y_DATA == 1)[0].tolist()
    normal_indices = np.where(y_DATA == 0)[0].tolist()

    # 2. Add a safety check in case your dataset has fewer than 2 frauds
    num_fraud = min(2, len(fraud_indices))
    num_normal = min(5 - num_fraud, len(normal_indices))

    sampled_fraud = random.sample(fraud_indices, num_fraud)
    sampled_normal = random.sample(normal_indices, num_normal)

    indices = sampled_fraud + sampled_normal
    random.shuffle(indices)
    payload = {}

    for i in indices:
        payload[f"sequence_{i}"] = {
            "features": X_DATA[i].tolist(),
            "label": int(y_DATA[i]),
        }

    return jsonify(payload), 200


@app.get("/training_metrics")
def get_training_metrics():
    print(metrices)
    return jsonify({"finished": len(metrices["Round"]) > 5, "metrics": metrices}), 200


@app.route("/predict", methods=["GET"])
def predict():
    # Get the sequence ID from the request (e.g., /predict?id=sequence_42)
    seq_id = request.args.get("id")

    if X_DATA is None or seq_id is None:
        return jsonify({"error": "Data or ID missing"}), 400

    try:
        # Extract the index from the string "sequence_42" -> 42
        idx = int(seq_id.split("_")[1])
        test_data = X_DATA[idx : idx + 1]
        y_true = int(y_DATA[idx])

        model = load_model("models/best_federated_model.keras")
        y_pred_prob = model.predict(test_data, verbose=0)
        y_pred_label = int(y_pred_prob[0][0] > FEDERATED_THRESHOLD)

        payload = {
            "sequence_id": seq_id,
            "actual_label": y_true,
            "predicted_probability": float(y_pred_prob[0][0]),
            "predicted_label": y_pred_label,
        }
        print(payload)

        return (
            jsonify(payload),
            200,
        )
    except Exception as e:
        return jsonify({"error": str(e)}), 500


@app.get("/get_models")
def get_models():
    try:
        models = os.listdir(models_path)
        print(f"Contents of 'models' directory: {models}")
        return jsonify({"models": models}), 200
    except Exception as e:
        print(f"An error occurred: {e}")
        return jsonify({"error": str(e)}), 500


@app.get("/get_evaluation_metrics")
def get_evaluation_metrics():
    model_name = request.args.get("model")

    if not model_name:
        return jsonify({"error": "No model name provided"}), 400

    try:
        model_file_path = os.path.join(models_path, model_name)
        if not os.path.isfile(model_file_path):
            return jsonify({"error": "Model file not found"}), 404

        model = load_model(model_file_path)

        y_probs = model.predict(X_DATA, verbose=0).ravel()

        threshold = evaluate_thresholds(y_probs, y_DATA)
        y_pred = (y_probs > threshold).astype(int)

        # --- NEW CODE TO CALCULATE PR-AUC ---
        precision_vals, recall_vals, _ = precision_recall_curve(y_DATA, y_probs)
        calculated_pr_auc = auc(recall_vals, precision_vals)
        # ------------------------------------

        metrics = {
            "Accuracy": round(accuracy_score(y_DATA, y_pred), 6),
            "Precision": round(precision_score(y_DATA, y_pred, zero_division=0), 6),
            "Recall": round(recall_score(y_DATA, y_pred), 6),
            "F1 Score": round(f1_score(y_DATA, y_pred), 6),
            "PR_AUC": round(calculated_pr_auc, 6),  # <--- USE THE CALCULATED VALUE HERE
        }

        return jsonify(metrics), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500


if __name__ == "__main__":

    app.run(host="0.0.0.0", port=5000)
