package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	"github.com/google/uuid"
	"github.com/jawaracloud/nats-event-driven-demo/shared"
	"github.com/nats-io/nats.go"
)

const ()

func main() {
	// NATS server address from environment variable or default
	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = "nats://localhost:4222"
	}

	// Subject to publish to from environment variable or default
	subject := os.Getenv("NATS_SUBJECT")
	if subject == "" {
		subject = "orders.created"
	}

	// Publish interval from environment variable or default
	intervalStr := os.Getenv("PUBLISH_INTERVAL_SECONDS")
	intervalSeconds, err := strconv.Atoi(intervalStr)
	if err != nil || intervalSeconds <= 0 {
		intervalSeconds = 2 // Default to 2 seconds
	}
	publishInterval := time.Duration(intervalSeconds) * time.Second

	// Connect to NATS
	log.Printf("Connecting to NATS at: %s", natsURL)
	nc, err := nats.Connect(natsURL)
	if err != nil {
		log.Fatalf("Failed to connect to NATS: %v", err)
	}
	defer nc.Close()
	log.Println("Connected to NATS successfully!")

	log.Printf("Starting producer, publishing to subject: %s every %d seconds", subject, intervalSeconds)

	// Publish messages periodically
	ticker := time.NewTicker(publishInterval)
	defer ticker.Stop()

	orderCount := 0
	for range ticker.C {
		orderCount++
		// Create a new OrderCreatedEvent
		event := shared.OrderCreatedEvent{
			OrderID:    uuid.New().String(),
			CustomerID: fmt.Sprintf("cust-%s", uuid.New().String()[:8]),
			Amount:     float64(orderCount) * 10.5,
			Currency:   "USD",
			Timestamp:  time.Now(),
		}

		// Marshal event to JSON
		data, err := event.ToJSON()
		if err != nil {
			log.Printf("Error marshaling event: %v", err)
			continue
		}

		// Publish the message
		err = nc.Publish(subject, data)
		if err != nil {
			log.Printf("Error publishing message: %v", err)
			continue
		}

		log.Printf("Published OrderCreatedEvent: OrderID=%s, Amount=%.2f", event.OrderID, event.Amount)
	}
}
