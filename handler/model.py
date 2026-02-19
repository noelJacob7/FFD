import tensorflow as tf
from tensorflow import keras
from keras import Sequential
from keras.layers import LSTM, Dense, Dropout, Input

import numpy as np
from sklearn.metrics import f1_score

def create_model(seq_len, input_shape):
    model = Sequential(
        [
            Input(shape=(seq_len, input_shape)),
            LSTM(64),
            Dropout(0.2),
            Dense(1, activation="sigmoid"),
        ]
    )

    model.compile(
        optimizer=tf.keras.optimizers.Adam(0.001),
        loss="binary_crossentropy",
        metrics=[tf.keras.metrics.AUC(name="auc")],
    )

    return model


def evaluate_thresholds(y_pred_probs, y_val):
    thresholds = np.linspace(0.05, 0.9, 50)

    best_f1 = 0
    best_threshold = 0

    for t in thresholds:
        y_pred = (y_pred_probs > t).astype(int)
        f1 = f1_score(y_val, y_pred)

        if f1 > best_f1:
            best_f1 = f1
            best_threshold = t

    return best_threshold
