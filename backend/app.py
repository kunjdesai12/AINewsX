# app.py
import os
from flask import Flask, request, jsonify
from flask_cors import CORS
from pipeline import run_full_pipeline

app = Flask(__name__)
CORS(app)  # Enable Cross-Origin Resource Sharing (important for Flutter/Web)

# ---------------------------
# Health Check Route
# ---------------------------
@app.route("/", methods=["GET"])
def health():
    """
    Simple health check to confirm service is running.
    """
    return jsonify({
        "status": "ok",
        "service": "FakeNewsChecker",
        "message": "Service is live and healthy ✅"
    })


# ---------------------------
# Prediction Route
# ---------------------------
@app.route("/predict", methods=["POST"])
def predict():
    """
    Endpoint: /predict
    Method: POST
    Request JSON:
      {
        "text": "news text here"
      }
    Response JSON:
      {
        "claim": "...",
        "ml": {
            "label": "Fake/Real",
            "probabilities": {"Real": 0.xx, "Fake": 0.yy}
        },
        "fact": {
            "found": true/false,
            "raw_count": int,
            "top_matches": [
                {
                  "title": "...",
                  "source": "...",
                  "url": "...",
                  "similarity": 0.xx,
                  "publishedAt": "..."
                }
            ]
        },
        "final": {
            "final_verdict": "Likely Fake/Real/Unclear",
            "reason": "Explanation"
        }
      }
    """
    try:
        payload = request.get_json(force=True)

        # Validate request
        if not payload or "text" not in payload:
            return jsonify({
                "error": "Invalid input. Please provide 'text' field in JSON body."
            }), 400

        text = payload["text"].strip()
        if not text:
            return jsonify({"error": "Input 'text' cannot be empty."}), 400

        # Run pipeline
        result = run_full_pipeline(text)

        # Return result
        return jsonify(result), 200

    except Exception as e:
        # Catch unexpected errors
        return jsonify({
            "error": "Internal server error",
            "details": str(e)
        }), 500


# ---------------------------
# Run the App
# ---------------------------
if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    app.run(host="0.0.0.0", port=port, debug=True)
