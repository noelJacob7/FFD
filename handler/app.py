import flask
from flask import request, jsonify

import os
import signal
import sys
import ctypes

'''
TODO:
-model_predict
'''

app = flask.Flask(__name__)


@app.get("/")
def home():
    return "Hello, World!"


@app.get("/get_health")
def health_check():
    return jsonify({"status": "ready"}), 200


if __name__ == "__main__":
    try:
        libc = ctypes.CDLL("libc.so.6")
        PR_SET_PDEATHSIG = 1
        libc.prctl(PR_SET_PDEATHSIG, signal.SIGTERM)
    except Exception as e:
        print(f"Warning: Could not set parent death signal: {e}", file=sys.stderr)  
    
    app.run(host="0.0.0.0", port=5000)
