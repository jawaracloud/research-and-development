# 85 — IoT & MQTT Bridge

> **Type:** Tutorial  
> **Phase:** Advanced & Real-World

## What you're building

Enable the **MQTT protocol** on the NATS server to allow low-power IoT devices (Arduinos, ESP32s) to communicate with your NATS infrastructure without needing a NATS-specific client.

## 1. Why MQTT in NATS?

MQTT is the industry standard for IoT.
- **Lower overhead** than standard NATS for tiny devices.
- **Native NATS integration:** MQTT topics are treated as NATS subjects.
- **No separate broker:** One NATS cluster handles both your backend microservices and your IoT devices.

## 2. Enabling MQTT

`server.conf`:
```
mqtt {
    port: 1883
}
```

## 3. Connecting an IoT Device

Using a standard MQTT client (like `mosquitto_pub`):

```bash
mosquitto_pub -h localhost -p 1883 -t "sensors/temp" -m "22.5"
```

In NATS, you can see this message immediately:
```bash
nats sub "sensors.temp"
```
*Note: MQTT uses `/` as a separator, which NATS automatically maps to `.` internally.*

## 4. JetStream and MQTT

Messages published via MQTT can be persisted in JetStream streams. 

```go
// Stream config to capture MQTT sensor data
js.AddStream(&nats.StreamConfig{
    Name: "IOT_DATA",
    Subjects: []string{"sensors.>"},
})
```

## 5. Retained Messages and LWT

NATS supports core MQTT features:
- **Retained Messages:** The last value published to a topic is saved and delivered to new subscribers.
- **Last Will and Testament (LWT):** Notifies NATS (and other devices) if an IoT device unexpectedly disconnects.

## 6. Use Case: Smart City
- **Sensors:** 10,000 light poles use MQTT to send status to NATS.
- **Backend:** Go microservices use JetStream to process the data and store it in a time-series DB.

---
*Part of the 100-Lesson NATS Series.*
