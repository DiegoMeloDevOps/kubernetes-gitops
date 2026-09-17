from flask import Flask, jsonify
import os

app = Flask(__name__)
# teste

@app.route("/")
def home():
    return jsonify({
        "application": "kubernetes-gitops-api",
        "version": "1.3.0",
        "environment": os.getenv("APP_ENV", "unknown")
    })


@app.route("/health")
def health():
    return jsonify({
        "status": "healthy"
    })


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)