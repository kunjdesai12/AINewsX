# ---------------------------
# Install dependencies
# ---------------------------
!pip install transformers datasets -q

# ---------------------------
# Imports
# ---------------------------
import pandas as pd
import numpy as np
import re
from sklearn.model_selection import train_test_split
from datasets import Dataset
import torch
from torch.utils.data import DataLoader
from torch import nn, optim
from transformers import BertTokenizer, BertForSequenceClassification
from tqdm import tqdm

# ---------------------------
# Step 1: Load dataset
# ---------------------------
true = pd.read_csv("/kaggle/input/fake-and-real-news-dataset/True.csv")
fake = pd.read_csv("/kaggle/input/fake-and-real-news-dataset/Fake.csv")

true["label"] = 0   # Real
fake["label"] = 1   # Fake

df = pd.concat([true, fake]).sample(frac=1, random_state=42).reset_index(drop=True)

# ---------------------------
# Step 2: Preprocess text
# ---------------------------
def clean_text(text):
    text = re.sub(r"http\S+", "", text)  # remove links
    text = re.sub(r"[^A-Za-z0-9 ]+", "", text)  # remove special chars
    text = text.lower().strip()
    return text

df["text"] = df["text"].apply(clean_text)

# ---------------------------
# Step 3: Train-test split
# ---------------------------
train_texts, test_texts, train_labels, test_labels = train_test_split(
    df["text"], df["label"], test_size=0.2, random_state=42
)

train_dataset = Dataset.from_dict({"text": train_texts.tolist(), "label": train_labels.tolist()})
test_dataset = Dataset.from_dict({"text": test_texts.tolist(), "label": test_labels.tolist()})

# ---------------------------
# Step 4: Tokenizer
# ---------------------------
tokenizer = BertTokenizer.from_pretrained("bert-base-uncased")

def tokenize(batch):
    return tokenizer(batch["text"], truncation=True, padding="max_length", max_length=256)

train_dataset = train_dataset.map(tokenize, batched=True)
test_dataset = test_dataset.map(tokenize, batched=True)

train_dataset.set_format("torch", columns=["input_ids", "attention_mask", "label"])
test_dataset.set_format("torch", columns=["input_ids", "attention_mask", "label"])

# ---------------------------
# Step 5: Load Model
# ---------------------------
model = BertForSequenceClassification.from_pretrained("bert-base-uncased", num_labels=2)

# ---------------------------
# Step 6: Training (Manual PyTorch Loop)
# ---------------------------
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

train_loader = DataLoader(train_dataset, batch_size=16, shuffle=True)
test_loader = DataLoader(test_dataset, batch_size=16)

optimizer = optim.AdamW(model.parameters(), lr=2e-5)
criterion = nn.CrossEntropyLoss()

num_epochs = 4  # Recommended for this dataset (medium size, BERT fine-tuning)

for epoch in range(num_epochs):
    model.train()
    total_loss = 0
    for batch in tqdm(train_loader, desc=f"Training Epoch {epoch+1}"):
        optimizer.zero_grad()
        input_ids = batch['input_ids'].to(device)
        attention_mask = batch['attention_mask'].to(device)
        labels = batch['label'].to(device)
        
        outputs = model(input_ids=input_ids, attention_mask=attention_mask, labels=labels)
        loss = outputs.loss
        loss.backward()
        optimizer.step()
        
        total_loss += loss.item()
    print(f"Epoch {epoch+1} | Loss: {total_loss/len(train_loader):.4f}")

    # Validation
    model.eval()
    correct = 0
    total = 0
    with torch.no_grad():
        for batch in test_loader:
            input_ids = batch['input_ids'].to(device)
            attention_mask = batch['attention_mask'].to(device)
            labels = batch['label'].to(device)

            outputs = model(input_ids=input_ids, attention_mask=attention_mask)
            preds = torch.argmax(outputs.logits, dim=1)
            correct += (preds == labels).sum().item()
            total += labels.size(0)
    print(f"Validation Accuracy: {correct/total:.4f}")

# ---------------------------
# Step 7: Save model
# ---------------------------
model.save_pretrained("/kaggle/working/model")
tokenizer.save_pretrained("/kaggle/working/model")

print("✅ Model saved in /kaggle/working/model")
