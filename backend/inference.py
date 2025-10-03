# inference.py
import os
import torch
from transformers import AutoTokenizer, AutoModelForSequenceClassification

# MODEL_PATH points to the folder where you placed the Kaggle model files.
MODEL_PATH = os.getenv("MODEL_PATH", "model")  # default 'model' dir

# load tokenizer + model (local files)
# local_files_only=True avoids internet calls if you're offline
tokenizer = AutoTokenizer.from_pretrained(MODEL_PATH, local_files_only=True)
model = AutoModelForSequenceClassification.from_pretrained(MODEL_PATH, local_files_only=True)

# device selection
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)
model.eval()

# label mapping
# NOTE: your training used: True (real) -> label 0, Fake -> label 1
LABEL_MAP = {0: "Real", 1: "Fake"}

def predict(text: str, max_length: int = 256):
    """
    Returns:
      {
        "label": "Real"/"Fake",
        "pred_label_id": int,
        "probabilities": [prob_real, prob_fake]
      }
    """
    if not isinstance(text, str) or not text.strip():
        raise ValueError("Input text must be a non-empty string")

    inputs = tokenizer(
        text,
        return_tensors="pt",
        truncation=True,
        padding="max_length",
        max_length=max_length
    )

    # move inputs to device
    inputs = {k: v.to(device) for k, v in inputs.items()}

    with torch.no_grad():
        outputs = model(**inputs)
        logits = outputs.logits
        probs = torch.softmax(logits, dim=1).cpu().numpy()[0].tolist()
        pred_id = int(torch.argmax(logits, dim=1).item())

    return {
        "label": LABEL_MAP.get(pred_id, str(pred_id)),
        "pred_label_id": pred_id,
        "probabilities": {"Real": probs[0], "Fake": probs[1]},
    }
