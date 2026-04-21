# 90 — NATS for AI/ML Pipelines

> **Type:** Explanation  
> **Phase:** Advanced & Real-World

## Overview

AI and Machine Learning workloads involve high throughput, large payloads (models/weights), and complex data pipelines. NATS is the "connective tissue" that links inference, training, and data collection.

## 1. Fast Data Ingestion
Use **JetStream** to collect real-time data from millions of sources (IoT, Web, Logs) and feed it into your training pipeline.
- Producers publish features.
- Training workers consume via **Pull Consumers** in batches for high-efficiency GPU processing.

## 2. Distributing Inference
Run inference workers globally and use **Request/Reply** (Lesson 4) to route prompts to the nearest available GPU instance.

```bash
# User Prompt
nats req ai.inference.text "Tell me a story about NATS"
# -> Routed to fastest/closest available inference microservice
```

## 3. Model Weight Distribution
Use **Object Store** (Lesson 88) to distribute oversized model weights (`.bin`, `.safetensors`) to edge inference nodes.
- **Hub:** Publishes a new model to Object Store.
- **Edge:** Notices the change (Watch) and pulls the new weights before reloading the local model.

## 4. Real-time Model Monitoring
Use **Fan-Out** (Lesson 45) to send inference inputs/outputs to a separate side-channel for drift detection and quality auditing without impacting user latency.

## 5. Architecture Pattern: The AI Mesh
- **Core Node:** High-end GPUs for training.
- **Leaf Nodes:** Edge GPUs or CPUs for inference.
- **NATS:** Hand-offs data, synchronizes models, and provides the glue for the entire lifecycle.

---
*Part of the 100-Lesson NATS Series.*
