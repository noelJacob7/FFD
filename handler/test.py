import numpy as np

try:
    with np.load("data/test_sequences.npz") as data:
        # We convert to memory-resident arrays immediately
        X_DATA = data["X"]
        y_DATA = data["y"]
    print("Data loaded successfully.")
except FileNotFoundError:
    print("Error: test_sequences.npz not found.")
    X_DATA, y_DATA = None, None


print(f'X_DATA: {X_DATA[5]}')
print(f'y_DATA: {y_DATA[5]}')
