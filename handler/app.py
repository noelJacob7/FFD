import flask
from flask import request, jsonify

"""
TODO:
-model_predict
"""
metrices = {
    "Round": [],
    "Accuracy": [],
    "Precision": [],
    "Recall": [],
    "F1 Score": [],
    "PR-AUC": [],
}

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

@app.get("/training_metrics")
def get_training_metrics():
    print(metrices)
    return jsonify({"finished": len(metrices["Round"]) > 5, "metrics": metrices}), 200


if __name__ == "__main__":

    app.run(host="0.0.0.0", port=5000)
