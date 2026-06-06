import argparse
import json
import os
import pickle
import warnings
warnings.filterwarnings('ignore')

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')
import seaborn as sns

from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.preprocessing import StandardScaler
from sklearn.naive_bayes import GaussianNB
from sklearn.linear_model import LogisticRegression
from sklearn.ensemble import RandomForestClassifier
from sklearn.metrics import (
    accuracy_score, f1_score, roc_auc_score,
    confusion_matrix, classification_report, roc_curve
)
from xgboost import XGBClassifier


BASE_DIR   = os.path.dirname(os.path.abspath(__file__))
MODELS_DIR = os.path.join(BASE_DIR, "models")
PLOTS_DIR  = os.path.join(BASE_DIR, "models", "plots")
os.makedirs(MODELS_DIR, exist_ok=True)
os.makedirs(PLOTS_DIR,  exist_ok=True)


DROP_COLS = [
    "origin", "destination",      
    "departure_date", "generated_at",  
    "actual_hours",              
    "label",                       
]

CATEGORICAL = ["road_type", "holiday_name"]

TARGET = "label"



def load_data(path: str) -> pd.DataFrame:
    print(f"\n[1/6] Loading data from {path}…")
    records = []
    with open(path) as f:
        for line in f:
            line = line.strip()
            if line:
                records.append(json.loads(line))
    df = pd.DataFrame(records)
    print(f"      Loaded {len(df):,} records, {df.shape[1]} columns")
    print(f"      Label distribution:")
    vc = df[TARGET].value_counts()
    for label, count in vc.items():
        name = "DELAYED" if label == 1 else "ON_TIME"
        print(f"        {name}: {count:,} ({count/len(df)*100:.1f}%)")
    return df


def preprocess(df: pd.DataFrame):
    print("\n[2/6] Preprocessing…")

    df = pd.get_dummies(df, columns=CATEGORICAL, drop_first=False)
    bool_cols = df.select_dtypes(include=bool).columns
    df[bool_cols] = df[bool_cols].astype(int)
    print(f"      After one-hot encoding: {df.shape[1]} columns")

    y = df[TARGET].astype(int)
    X = df.drop(columns=[c for c in DROP_COLS if c in df.columns])

    non_numeric = X.select_dtypes(exclude=[np.number]).columns.tolist()
    if non_numeric:
        print(f"      Dropping non-numeric cols: {non_numeric}")
        X = X.drop(columns=non_numeric)

    feature_names = X.columns.tolist()
    print(f"      Features: {len(feature_names)}")

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.20, random_state=42, stratify=y
    )
    print(f"      Train: {len(X_train):,}  Test: {len(X_test):,}")

    scaler = StandardScaler()
    X_train_sc = scaler.fit_transform(X_train)
    X_test_sc  = scaler.transform(X_test)

    return (X_train, X_test, y_train, y_test,
            X_train_sc, X_test_sc,
            scaler, feature_names)



def get_models():
    return {
        "Naive Bayes": GaussianNB(),
        "Logistic Regression": LogisticRegression(
            max_iter=1000, random_state=42, class_weight="balanced"
        ),
        "Random Forest": RandomForestClassifier(
            n_estimators=100,
            max_depth=15,
            max_features="sqrt",
            random_state=42,
            class_weight="balanced",
            n_jobs=2
        ),
        "XGBoost": XGBClassifier(
            n_estimators=200, random_state=42,
            eval_metric="logloss", verbosity=0,
            scale_pos_weight=1
        ),
    }



def evaluate_models(models, X_train_sc, X_test_sc, y_train, y_test):
    print("\n[3/6] Training & evaluating models…")
    results = {}

    for name, model in models.items():
        print(f"\n  ── {name} ──")

        cv_scores = cross_val_score(
            model, X_train_sc, y_train,
            cv=5, scoring="f1_weighted", n_jobs=-1
        )
        print(f"    CV F1 (5-fold): {cv_scores.mean():.4f} ± {cv_scores.std():.4f}")

        model.fit(X_train_sc, y_train)

        y_pred  = model.predict(X_test_sc)
        y_proba = model.predict_proba(X_test_sc)[:, 1]

        acc     = accuracy_score(y_test, y_pred)
        f1      = f1_score(y_test, y_pred, average="weighted")
        f1_mac  = f1_score(y_test, y_pred, average="macro")
        auc     = roc_auc_score(y_test, y_proba)
        cm      = confusion_matrix(y_test, y_pred)

        print(f"    Accuracy:    {acc:.4f}")
        print(f"    F1 weighted: {f1:.4f}")
        print(f"    F1 macro:    {f1_mac:.4f}")
        print(f"    ROC-AUC:     {auc:.4f}")
        print(f"    Confusion matrix:\n{cm}")
        print(f"\n    Classification report:")
        print(classification_report(y_test, y_pred,
                                     target_names=["ON_TIME", "DELAYED"]))

        results[name] = {
            "model":    model,
            "cv_mean":  cv_scores.mean(),
            "cv_std":   cv_scores.std(),
            "accuracy": acc,
            "f1":       f1,
            "f1_macro": f1_mac,
            "roc_auc":  auc,
            "cm":       cm,
            "y_pred":   y_pred,
            "y_proba":  y_proba,
        }

    return results



def plot_roc_curves(results, y_test):
    print("\n[4a/6] Plotting ROC curves…")
    plt.figure(figsize=(8, 6))
    colors = ["#e74c3c", "#3498db", "#2ecc71", "#f39c12"]

    for (name, res), color in zip(results.items(), colors):
        fpr, tpr, _ = roc_curve(y_test, res["y_proba"])
        plt.plot(fpr, tpr, color=color, lw=2,
                 label=f"{name} (AUC={res['roc_auc']:.3f})")

    plt.plot([0, 1], [0, 1], "k--", lw=1, label="Random")
    plt.xlabel("False Positive Rate")
    plt.ylabel("True Positive Rate")
    plt.title("ROC Curves — All Models")
    plt.legend(loc="lower right")
    plt.tight_layout()
    path = os.path.join(PLOTS_DIR, "roc_curves.png")
    plt.savefig(path, dpi=120)
    plt.close()
    print(f"      Saved: {path}")


def plot_confusion_matrices(results):
    print("[4b/6] Plotting confusion matrices…")
    fig, axes = plt.subplots(2, 2, figsize=(10, 8))
    axes = axes.flatten()

    for ax, (name, res) in zip(axes, results.items()):
        sns.heatmap(res["cm"], annot=True, fmt="d", cmap="Blues", ax=ax,
                    xticklabels=["ON_TIME", "DELAYED"],
                    yticklabels=["ON_TIME", "DELAYED"])
        ax.set_title(name)
        ax.set_xlabel("Predicted")
        ax.set_ylabel("Actual")

    plt.suptitle("Confusion Matrices", fontsize=14, fontweight="bold")
    plt.tight_layout()
    path = os.path.join(PLOTS_DIR, "confusion_matrices.png")
    plt.savefig(path, dpi=120)
    plt.close()
    print(f"      Saved: {path}")


def plot_model_comparison(results):
    print("[4c/6] Plotting model comparison…")
    names   = list(results.keys())
    metrics = {
        "F1 (weighted)": [r["f1"]       for r in results.values()],
        "ROC-AUC":       [r["roc_auc"]  for r in results.values()],
        "Accuracy":      [r["accuracy"] for r in results.values()],
    }

    x = np.arange(len(names))
    width = 0.25
    fig, ax = plt.subplots(figsize=(10, 6))
    colors = ["#3498db", "#e74c3c", "#2ecc71"]

    for i, (metric, vals) in enumerate(metrics.items()):
        bars = ax.bar(x + i * width, vals, width, label=metric,
                      color=colors[i], alpha=0.85)
        for bar, val in zip(bars, vals):
            ax.text(bar.get_x() + bar.get_width() / 2, bar.get_height() + 0.005,
                    f"{val:.3f}", ha="center", va="bottom", fontsize=8)

    ax.set_xticks(x + width)
    ax.set_xticklabels(names, rotation=10)
    ax.set_ylim(0, 1.05)
    ax.set_ylabel("Score")
    ax.set_title("Model Comparison")
    ax.legend()
    plt.tight_layout()
    path = os.path.join(PLOTS_DIR, "model_comparison.png")
    plt.savefig(path, dpi=120)
    plt.close()
    print(f"      Saved: {path}")


def plot_feature_importance(results, feature_names):
    print("[4d/6] Plotting feature importance…")

    for model_name in ["Random Forest", "XGBoost"]:
        if model_name not in results:
            continue
        model = results[model_name]["model"]

        if hasattr(model, "feature_importances_"):
            importances = model.feature_importances_
        else:
            continue

        fi = pd.Series(importances, index=feature_names).sort_values(ascending=False)
        top_n = fi.head(15)

        fig, ax = plt.subplots(figsize=(9, 6))
        top_n.plot(kind="barh", ax=ax, color="#3498db", alpha=0.85)
        ax.invert_yaxis()
        ax.set_xlabel("Importance")
        ax.set_title(f"Feature Importance — {model_name} (Top 15)")
        plt.tight_layout()
        safe_name = model_name.lower().replace(" ", "_")
        path = os.path.join(PLOTS_DIR, f"feature_importance_{safe_name}.png")
        plt.savefig(path, dpi=120)
        plt.close()
        print(f"      Saved: {path}")



def tune_best_model(results, X_train_sc, y_train):
    print("\n[5/6] Hyperparameter tuning for best model…")

    best_name = max(results, key=lambda n: results[n]["roc_auc"])
    print(f"      Best model: {best_name} (ROC-AUC={results[best_name]['roc_auc']:.4f})")

    if best_name == "XGBoost":
        param_grid = {
            "n_estimators":    [200, 400],
            "max_depth":       [4, 6, 8],
            "learning_rate":   [0.05, 0.1],
            "subsample":       [0.8, 1.0],
            "colsample_bytree":[0.8, 1.0],
        }
        base = XGBClassifier(
            random_state=42, eval_metric="logloss", verbosity=0
        )
    elif best_name == "Random Forest":
        param_grid = {
            "n_estimators": [100, 200],
            "max_depth":    [10, 15],
            "min_samples_split": [2, 5],
        }
        base = RandomForestClassifier(
            random_state=42, class_weight="balanced",
            max_features="sqrt", n_jobs=2
        )
    elif best_name == "Logistic Regression":
        param_grid = {
            "C":        [0.01, 0.1, 1.0, 10.0, 100.0],
            "penalty":  ["l1", "l2"],
            "solver":   ["liblinear", "saga"],
        }
        base = LogisticRegression(
            max_iter=2000, random_state=42, class_weight="balanced"
        )
    else:
        print(f"      No tuning grid for {best_name}, skipping.")
        return best_name, results[best_name]["model"]

    print(f"      Running GridSearchCV (this may take a few minutes)…")
    gs = GridSearchCV(
        base, param_grid,
        cv=3, scoring="f1_weighted",
        n_jobs=2, verbose=1
    )
    gs.fit(X_train_sc, y_train)

    print(f"      Best params: {gs.best_params_}")
    print(f"      Best CV F1:  {gs.best_score_:.4f}")

    return best_name, gs.best_estimator_



def save_artifacts(best_name, best_model, scaler,
                   feature_names, results, X_test_sc, y_test):
    print("\n[6/6] Saving artifacts…")

    y_pred  = best_model.predict(X_test_sc)
    y_proba = best_model.predict_proba(X_test_sc)[:, 1]

    final = {
        "accuracy": accuracy_score(y_test, y_pred),
        "f1":       f1_score(y_test, y_pred, average="weighted"),
        "roc_auc":  roc_auc_score(y_test, y_proba),
    }
    print(f"      Tuned {best_name} on test set:")
    print(f"        Accuracy:    {final['accuracy']:.4f}")
    print(f"        F1 weighted: {final['f1']:.4f}")
    print(f"        ROC-AUC:     {final['roc_auc']:.4f}")

    model_path = os.path.join(MODELS_DIR, "best_model.pkl")
    with open(model_path, "wb") as f:
        pickle.dump(best_model, f)
    print(f"      Model saved: {model_path}")

    scaler_path = os.path.join(MODELS_DIR, "scaler.pkl")
    with open(scaler_path, "wb") as f:
        pickle.dump(scaler, f)
    print(f"      Scaler saved: {scaler_path}")

    features_path = os.path.join(MODELS_DIR, "feature_names.json")
    with open(features_path, "w") as f:
        json.dump(feature_names, f, indent=2)
    print(f"      Feature names saved: {features_path}")

    report = {
        "best_model": best_name,
        "final_test_metrics": final,
        "all_models": {
            name: {
                "cv_f1_mean": float(r["cv_mean"]),
                "cv_f1_std":  float(r["cv_std"]),
                "test_accuracy": float(r["accuracy"]),
                "test_f1":       float(r["f1"]),
                "test_roc_auc":  float(r["roc_auc"]),
            }
            for name, r in results.items()
        },
        "n_features": len(feature_names),
        "feature_names": feature_names,
    }
    report_path = os.path.join(MODELS_DIR, "evaluation_report.json")
    with open(report_path, "w") as f:
        json.dump(report, f, indent=2)
    print(f"      Report saved: {report_path}")

    return final



def main():
    parser = argparse.ArgumentParser(description="Phase 4 — ML Training Pipeline")
    parser.add_argument("--data-path", default="data/training_data.jsonl")
    args = parser.parse_args()

    data_path = os.path.join(BASE_DIR, args.data_path) \
                if not os.path.isabs(args.data_path) else args.data_path

    print("=" * 60)
    print("  Phase 4 — Delivery Risk Predictor — Training Pipeline")
    print("=" * 60)

    df = load_data(data_path)

    (X_train, X_test, y_train, y_test,
     X_train_sc, X_test_sc,
     scaler, feature_names) = preprocess(df)

    models  = get_models()
    results = evaluate_models(models, X_train_sc, X_test_sc, y_train, y_test)

    print("\n── Model Comparison Summary ─────────────────────────────")
    print(f"{'Model':<22} {'CV F1':>8} {'Test F1':>8} {'AUC':>8} {'Acc':>8}")
    print("-" * 58)
    for name, r in results.items():
        print(f"{name:<22} {r['cv_mean']:>8.4f} {r['f1']:>8.4f} "
              f"{r['roc_auc']:>8.4f} {r['accuracy']:>8.4f}")

    best_name  = max(results, key=lambda n: results[n]["roc_auc"])
    best_model = results[best_name]["model"]
    print(f"\n[5/6] Best model by ROC-AUC: {best_name} ({results[best_name]['roc_auc']:.4f})")

    save_artifacts(best_name, best_model, scaler,
                   feature_names, results, X_test_sc, y_test)

    print("\n" + "=" * 60)
    print("  Training complete!")
    print(f"  Best model: {best_name}")
    print(f"  Artifacts:  {MODELS_DIR}/")
    print(f"  Plots:      {PLOTS_DIR}/")
    print("=" * 60)


if __name__ == "__main__":
    main()