# 📰 AINewsX – AI-Powered News & Fake News Detection App

<p align="center">
  <img src="Doc/logo.png" alt="Logo" width="150">
</p>

AINewsX is a cross-platform Flutter application designed to deliver **real-time, reliable news** while actively combating misinformation.  
It aggregates top stories from **NewsAPI.org**, organizes them by topics and countries, and enhances user experience with:  

📌 **Bookmarks & Saved Articles** – offline access anytime  
🌙 **Light/Dark Mode** – seamless theme support  
🔍 **Smart Search** – find relevant news instantly  

---

## 🔑 What Makes AINewsX Unique?  

AINewsX integrates a **hybrid fake news detection system** that blends machine learning with live verification:  

📊 **BERT-based Classifier** – fine-tuned on the Kaggle Fake/Real News dataset (~45K articles), achieving **99% F1-score** for detecting misleading content.  
🌐 **Real-Time Fact-Checking** – verifies claims against live sources from NewsAPI.org using **Sentence-Transformers embeddings** for semantic similarity.  
⚡ **Fusion Logic** – combines ML probabilities with similarity-based evidence retrieval for a final verdict.  

✅ **Dual-Layered Reliability**  
- **Accuracy** – powered by deep learning classification  
- **Recency** – validated against the latest credible news sources  

---

## 🏗️ System Architecture

The following diagram illustrates the complete workflow of **AINewsX**, showing how news is fetched, processed, and verified before being presented to the user.

<p align="center">
  <img src="Doc/AINewsX.png" alt="AINewsX Architecture" width="800">
</p>

### 🔄 Workflow Overview

1. **News Fetching**  
   - NewsAPI.org is used to fetch category-wise articles as well as the latest headlines for the home page.  

2. **Search & Save Features**  
   - A search bar enables exploring related news.  
   - Saved articles are stored locally using **SQLite** to enable offline access.  

3. **Fake News Detection System**  
   - User input is sent to the Python backend.  
   - **ML Inference (`inference.py`)**: Uses a fine-tuned BERT model for Fake/Real classification.  
   - **Fact Checker (`fact_checker.py`)**: Retrieves and compares claims against live sources using Sentence-Transformers.  
   - **Fusion Logic**: Combines ML probabilities with external evidence.  

4. **Final Verdict**  
   - The system outputs whether the news is *Real*, *Fake*, or *Unclear*, along with supporting sources and evidence.



By fusing AI-driven predictions with real-world verification, **AINewsX delivers a transparent, trustworthy, and next-generation news experience**—overcoming the limitations of static AI models.  
