# pipeline.py
from inference import predict
from fact_checker import fact_check_claim
from typing import Dict, Any

# Tunable thresholds (you should tune these on hold-out validation)
SIMILARITY_CONFIRM = 0.72   # similarity >= this reliably indicates a matching article
SIMILARITY_WEAK = 0.45      # between weak/confirm -> "Unclear"
# Fusion weights if you want to compute a numeric final score
ALPHA_ML = 0.6              # weight for ML (fake-prob)
BETA_EVID = 0.4             # weight for evidence (support_score)

def fuse_decision(ml_out: Dict[str, Any], fact_out: Dict[str, Any]):
    """
    ml_out: output from inference.predict()
    fact_out: output from fact_checker.fact_check_claim()

    Returns final structured verdict.
    """
    ml_label = ml_out["label"]
    probs = ml_out["probabilities"]
    prob_fake = float(probs["Fake"])  # probability produced by model

    # Determine best support score from fact_out
    if fact_out["found"] and fact_out["top_matches"]:
        top = fact_out["top_matches"][0]
        support_score = float(top["similarity"])  # 0..1 where higher supports the claim
    else:
        support_score = 0.0

    # Decision rules:
    # - If strong support (>= SIMILARITY_CONFIRM) -> Real (supported by external sources)
    # - If no support and model says Fake strongly -> Likely Fake
    # - If model says Real and moderate support -> Real
    # - Otherwise Unclear
    final = {"ml_label": ml_label, "ml_prob_fake": prob_fake, "support_score": support_score}

    if support_score >= SIMILARITY_CONFIRM:
        final["final_verdict"] = "Real"
        final["reason"] = f"Strong external support (similarity={support_score:.2f})"
    else:
        # no strong external confirmation
        if ml_label == "Fake" and prob_fake >= 0.7 and support_score < SIMILARITY_WEAK:
            final["final_verdict"] = "Likely Fake"
            final["reason"] = f"Model strongly indicates Fake (p_fake={prob_fake:.2f}) and no external support"
        elif ml_label == "Real" and prob_fake >= 0.6 and support_score >= SIMILARITY_WEAK:
            final["final_verdict"] = "Likely Real"
            final["reason"] = f"Model leans Real and weak external support (similarity={support_score:.2f})"
        else:
            final["final_verdict"] = "Unclear"
            final["reason"] = "Conflicting or insufficient signals (manual review recommended)"

    # attach top matches (if any)
    final["top_matches"] = fact_out.get("top_matches", [])
    return final


def run_full_pipeline(claim: str):
    ml_out = predict(claim)
    fact_out = fact_check_claim(claim)
    final = fuse_decision(ml_out, fact_out)
    return {"claim": claim, "ml": ml_out, "fact": fact_out, "final": final}


if __name__ == "__main__":
    # quick CLI test
    import sys
    txt = sys.argv[1] if len(sys.argv) > 1 else input("Enter claim: ")
    res = run_full_pipeline(txt)
    import json
    print(json.dumps(res, indent=2))
