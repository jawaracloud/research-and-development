# 84 — Mobile & NATS (Android/iOS)

> **Type:** Explanation  
> **Phase:** Advanced & Real-World

## Overview

Building mobile apps that scale to millions of users requires a messaging backbone that is both lightweight and resilient. NATS is a perfect fit for real-time mobile features.

## 1. Choosing the Protocol

- **WebSockets:** Great for cross-platform apps (React Native, Flutter).
- **Core NATS Protocol:** Available for Android (Java/Kotlin client) and iOS (Swift client).

## 2. Handling Battery and Connectivity

Mobile devices aren't always connected.
- **JetStream is Mandatory:** Use JetStream so that when a phone comes back online (from a tunnel or dead zone), it can "catch up" on missed messages.
- **Ephemeral Consumers:** Every phone should have its own ephemeral consumer or a unique durable ID.

## 3. Authentication at Scale

Use **NKeys** and **JWTs**.
1. **App Login:** Phone authentication with your API.
2. **NATS Provisioning:** Your API generates a temporary User JWT for NATS with narrow permissions (e.g., can only subscribe to `user.123.>`).
3. **Connect:** Phone uses the JWT to connect to NATS directly.

## 4. Push Notifications vs. NATS

- **NATS:** Use for active app states (chat, live tracking, game updates).
- **FCM/APNS:** Use for background alerts when the app is closed.
- **Pattern:** Use a NATS consumer on your server that listens for messages and triggers an FCM/APNS push if the mobile client is offline.

## 5. Security: Account Scoping
Assign each mobile user to their own NATS Account or use strict ACLs (Lesson 72) to ensure they cannot sniff other users' traffic.

---
*Part of the 100-Lesson NATS Series.*
