# fact_checker.py
import os
import requests
from typing import List, Dict, Any
from dotenv import load_dotenv
from sentence_transformers import SentenceTransformer, util

load_dotenv()  # loads .env if present

NEWSAPI_KEY = os.getenv("NEWSAPI_KEY", "")
NEWSAPI_URL = "https://newsapi.org/v2/everything"
DEFAULT_PAGE_SIZE = int(os.getenv("MAX_ARTICLES", 10))

# load a fast embedding model
EMBED_MODEL_NAME = "all-MiniLM-L6-v2"  # lightweight & good
embedder = SentenceTransformer(EMBED_MODEL_NAME)


def fetch_news_articles(query: str, page_size: int = DEFAULT_PAGE_SIZE) -> List[Dict[str, Any]]:
    """
    Calls NewsAPI to get recent articles related to query.
    Returns list of articles with keys: title, description, url, source, publishedAt
    """
    if not NEWSAPI_KEY:
        raise RuntimeError("NEWSAPI_KEY not set. Put your key in .env or environment variables.")

    params = {
        "q": query,
        "pageSize": page_size,
        "language": "en",
        "sortBy": "relevancy",
    }
    r = requests.get(NEWSAPI_URL, params={**params, "apiKey": NEWSAPI_KEY}, timeout=10)
    r.raise_for_status()
    data = r.json()
    articles = data.get("articles", [])
    # compact representation
    result = []
    for a in articles:
        title = a.get("title") or ""
        desc = a.get("description") or ""
        text = (title + " " + desc).strip()
        result.append({
            "title": title,
            "description": desc,
            "text": text,
            "url": a.get("url"),
            "source": a.get("source", {}).get("name"),
            "publishedAt": a.get("publishedAt"),
        })
    return result


def get_top_similar_articles(claim: str, articles: List[Dict[str, Any]], top_k: int = 3):
    """
    Returns top_k articles sorted by cosine similarity with 'claim'.
    Each returned entry contains similarity score in [0,1].
    """
    if not articles:
        return []

    # create corpus of article texts (title+desc)
    docs = [a["text"] for a in articles]
    # embed claim and docs
    claim_emb = embedder.encode(claim, convert_to_tensor=True, show_progress_bar=False)
    doc_embs = embedder.encode(docs, convert_to_tensor=True, show_progress_bar=False)
    # cosine similarities
    cos_scores = util.cos_sim(claim_emb, doc_embs)[0]  # shape (num_docs,)
    cos_scores = cos_scores.cpu().numpy().tolist()

    scored = []
    for art, score in zip(articles, cos_scores):
        # map cosine [-1,1] to [0,1]
        mapped = max(0.0, min(1.0, (score + 1) / 2))
        scored.append({**art, "similarity": float(mapped)})

    # sort descending by similarity
    scored.sort(key=lambda x: x["similarity"], reverse=True)
    return scored[:top_k]


def fact_check_claim(claim: str, page_size: int = DEFAULT_PAGE_SIZE, top_k: int = 3):
    """
    Full pipeline: fetch articles, compute similarity, return top_k matches.
    Returns:
      {
        "found": bool,              # whether any articles retrieved
        "top_matches": [ ... ],
        "raw_count": n
      }
    """
    articles = fetch_news_articles(claim, page_size=page_size)
    if not articles:
        return {"found": False, "top_matches": [], "raw_count": 0}

    scored = get_top_similar_articles(claim, articles, top_k=top_k)
    return {"found": True, "raw_count": len(articles), "top_matches": scored}
