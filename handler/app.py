import flask
from flask import request, jsonify


app = flask.Flask(__name__)
@app.get('/get_health')
def health_check():
    return jsonify({"status": "ready"}), 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)