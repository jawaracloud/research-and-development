package main

import (
	"log"
	"os"
	"time"

	"github.com/jawaracloud/nats-event-driven-demo/shared"
	"github.com/nats-io/nats.go"
)

func main() {
	// NATS server address from environment variable or default
	natsURL := os.Getenv("NATS_URL")
	if natsURL == "" {
		natsURL = "nats://localhost:4222"
	}

	// Subject to subscribe to from environment variable or default
	subject := os.Getenv("NATS_SUBJECT")
	if subject == "" {
		subject = "orders.created"
	}

	// Connect to NATS
	log.Printf("Connecting to NATS at: %s", natsURL)
	nc, err := nats.Connect(natsURL)
	if err != nil {
		log.Fatalf("Failed to connect to NATS: %v", err)
	}
	defer nc.Close()
	log.Println("Connected to NATS successfully!")

	log.Printf("Subscribing to subject: %s", subject)

	// Subscribe to the subject
	_, err = nc.Subscribe(subject, func(m *nats.Msg) {
		var event shared.OrderCreatedEvent
		if err := event.FromJSON(m.Data); err != nil {
			log.Printf("Error unmarshaling message: %v", err)
			return
		}

		// Simulate processing time
		time.Sleep(50 * time.Millisecond)

		log.Printf("Received OrderCreatedEvent: OrderID=%s, CustomerID=%s, Amount=%.2f, Latency=%s",
			event.OrderID,
			event.CustomerID,
			event.Amount,
			time.Since(event.Timestamp).Round(time.Millisecond),
		)
	})
	if err != nil {
		log.Fatalf("Failed to subscribe to subject: %v", err)
	}

	// Keep the consumer running
	log.Println("Consumer is running. Press Ctrl+C to exit.")
	select {}
}
