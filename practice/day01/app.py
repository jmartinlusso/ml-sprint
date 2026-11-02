import streamlit as st
from sklearn.datasets import load_breast_cancer
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

data = load_breast_cancer(as_frame=True)
X_train, X_test, y_train, y_test = train_test_split(
    data.data, data.target, test_size=0.25, stratify=data.target, random_state=42
    )

@st.cache_resource
def train_model():
    return RandomForestClassifier(n_estimators=300, random_state=42).fit(X_train, y_train)

model = train_model()
st.title("Day 1: tumor classifier")
i = st.slider("Test row", 0, len(X_test) - 1, 0)
row = X_test.iloc[[i]]
st.metric("P(benign)", f"{model.predict_proba(row)[0, 1]:.2f}")
st.write("True label:", data.target_names[y_test.iloc[i]])
st.dataframe(row.T)