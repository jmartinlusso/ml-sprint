from sklearn.datasets import load_breast_cancer
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import accuracy_score
from sklearn.model_selection import train_test_split
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
import numpy as np

N_SEEDS = 20
TEST_SIZE = 0.25

X, y = load_breast_cancer(return_X_y=True, as_frame=True)

results = {}
for seed in range(N_SEEDS):
    X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=TEST_SIZE, stratify=y, random_state=seed
    )

    models = {
    "logistic_regression": make_pipeline(StandardScaler(), LogisticRegression(max_iter=1000)),
    "random_forest": RandomForestClassifier(n_estimators=300, random_state=seed)
    }

    for name, model in models.items():
        model.fit(X_train, y_train)
        preds = model.predict(X_test)
        acc = accuracy_score(y_test, preds)
        results.setdefault(name, []).append(acc)

for name, accs in results.items():
    accs = np.array(accs)
    print(f"{name:20s} mean = {accs.mean():.3f} std = {accs.std():.3f}")

lr = np.array(results["logistic_regression"])
rf = np.array(results["random_forest"])
print(f"\n Over 20 seeds: LR wins {(lr > rf).sum()}, ")
print(f"RF wins {(rf > lr).sum()}, ties {(rf == lr).sum()}")
