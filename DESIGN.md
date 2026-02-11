Federated Fraud Detection (FFD) - Technical Design Document
This document defines the technical architecture, background infrastructure, and user interface for the Federated Fraud Detection (FFD) suite, a hybrid application leveraging Flutter Desktop for the interface and an ML Handler (Python sidecar) for machine learning logic.
1. Authentication & Role-Based Access (Gatekeeper)The Auth Page serves as the system's entry point, managing the transition from an unauthenticated state to a role-specific environment.
Role Mapping: Upon a successful login, the application receives a user profile containing a specific role (e.g., {"role": "admin"} or {"role": "client"}).
Dynamic UI Branching: The Flutter navigation sidebar is built conditionally based on this role. Admins are routed to the Orchestrator Suite, while Clients are routed to the Participant Suite.
Process Launch: Successful authentication automatically initializes the ML Handler (Python Sidecar) in the background.

2. Internal Working Features (Background Services)
These services run persistently to bridge the gap between the desktop UI and the machine learning logic.
ML Handler (Sidecar): A managed Python process running alongside the Flutter app. It performs all heavy computation, including local model training and inference.
Flask REST API (Inter-Process Communication): Acts as the "Control Plane," allowing Flutter to send commands (e.g., "Start Training") and receive status data from the Python process.
Flower Framework (Federated Sync): Manages the secure exchange of model weights over gRPC, ensuring data stays on the client while model patterns are aggregated.
Live Log Streaming: Flutter uses Process.start() to listen to the stdout and stderr of the ML Handler, piping every line of text into real-time UI terminals.

3. Server (Admin) Specifications
Internal Working Features
Radar Scanning: Utilizes mDNS (Multicast DNS) to discover active client nodes on the local network.
Aggregator Logic: Orchestrates the Federated Averaging (FedAvg) process, combining weights from $N$ clients into a single global model.
Auto-Validation: Evaluates the initial model against the latest aggregated model to track improvement metrics.
**Admin Pages**
* Home Page: A stylish, central hub displaying vital Status Info:
    * Active Nodes: Number of connected and verified clients.
    * Server Health: Memory/CPU usage of the local ML Handler.Current Metrics: 
    * The highest accuracy achieved in the current session.
* GlobalLogs: A tabbed terminal interface separating log streams:
    * Flask API: Internal request/response history.
    * Flower: Orchestration and weight sync logs.
    * Err: Critical system errors and exceptions.
* Connection Page: Centered on the Radar Scanning utility, allowing the Admin to search for, add, or disconnect clients.
* Training Page: The monitoring center for active rounds:
    * Live Metrics: Charts displaying global accuracy and loss trends.
    * Initial vs. Best Comparison: (Post training) Side-by-side graphs comparing the original .keras model with the federated version.
    * Push Model Button: Manual trigger to deploy the best model to all clients.
* Fraud Detection Page: A verification tool for the Admin to test the global model on sequence batches before a wide deployment.

4. Client (Participant) Specifications
Internal Working Features
* SmartDataGuard: The primary intake module for local data.File Validation: Verifies that the .npz file exists and contains the correct 75-feature PCA structure.
* SQLite Sequence Buffer: A local database that maintains the 5-transaction history required for the LSTM model's input shape.
**Client Pages**
* Home Page: Displays readiness status, data verification results from SmartDataGuard, and connection strength to the server.
* Transaction Logs: A clean, read-only data table displaying the raw contents of the local data file (Transaction IDs, timestamps, and feature samples) for user monitoring.
* Local Training Logs: A tabbed terminal for node-specific progress:
    * ML Handler Status: Logs for local resource usage and data loading.
    * Training Progress: Local round logs including Accuracy and Loss per epoch.
* Fraud Detection Page: The risk assessment tool for local transactions:
    * Inference Dashboard: Displays risk probability and classification status.
    * Sequence History Timeline: A graphical view of the 5 transactions currently being analyzed by the LSTM.

5. File Structure
/lib
  ├── main.dart                 # App entry point; initializes ML Handler process
  ├── app.dart                  # Root widget; handles routing/theme
  ├── core/                     # Global utilities and shared services
  │   ├── auth/                 # Role-based authentication logic & repository
  │   ├── network/              # REST & gRPC client configurations
  │   ├── theme/                # UI colors, fonts, and styling
  │   └── utils/                # Log streamers and process managers
  │
  ├── roles/                 # Modular feature-based directories
  │   ├── auth/                 # Login screen and authentication state
  │   │
  │   ├── admin/                # Server-exclusive features
  │   │   ├── home/             # Status dashboard (Health, Nodes, Master Model)
  │   │   ├── connection/       # Radar scanning & client management
  │   │   ├── training/         # Real-time metrics, comparison, & deploy button
  │   │   ├── global_logs/      # Tabbed log view (Flask, Flower, Err)
  │   │   └── fraud_detection/  # Admin verification/inference testing
  │   │
  │   └── client/               # Node-exclusive features
  │       ├── home/             # Readiness status & connection strength
  │       ├── transaction_logs/ # Data table displaying raw .npz contents
  │       ├── training_logs/    # Tabbed log view (ML Handler, Progress)
  │       ├── fraud_detection/  # LSTM sequence history & risk breakdown
  │       └── data_guard/       # Logic for .npz path validation & shape checks
  │
  └── shared_widgets/           # Reusable UI components (buttons, charts, terminals)

  /handler
  ├── app.py                    # Flask REST API (The Control Plane)
  ├── flower_client.py          # Flower federation logic (The Sync Plane)
  ├── model.py                  # LSTM architecture & .keras loading logic
  ├── utils/                    # Data processing and .npz validation scripts
  ├── requirements.txt          # Python dependencies (TensorFlow, Flower, Flask)
  └── venv/                     # Local virtual environment (if bundled)

  /assets
  ├── models/                   # Storage for initial_model.keras & pushed versions
  ├── images/                   # UI icons and stylish home page illustrations
  └── data/                     # Default folder for local .npz transaction files