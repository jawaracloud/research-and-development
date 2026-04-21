package main

import (
	"context"
	"encoding/json"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/redis/go-redis/v9"
)

// Message represents the data structure that is published
type Message struct {
	ID        string    `json:"id"`
	Content   string    `json:"content"`
	Timestamp time.Time `json:"timestamp"`
}

func main() {
	// Retrieve configuration from environment variables with default fallback
	redisAddr := os.Getenv("REDIS_ADDR")
	if redisAddr == "" {
		redisAddr = "localhost:6379"
	}

	channel := os.Getenv("CHANNEL")
	if channel == "" {
		channel = "messages"
	}

	// Set up logger
	logger := log.New(os.Stdout, "[SUBSCRIBER] ", log.LstdFlags)
	logger.Printf("Starting subscriber service. Listening on channel: %s", channel)

	// Connect to DragonFlyDB
	client := redis.NewClient(&redis.Options{
		Addr:     redisAddr,
		Password: "", // no password set
		DB:       0,  // use default DB
	})

	// Create a context that will be canceled on SIGINT or SIGTERM
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Set up signal handling for graceful shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)

	// Check connection
	_, err := client.Ping(ctx).Result()
	if err != nil {
		logger.Fatalf("Failed to connect to DragonFlyDB: %v", err)
	}
	logger.Println("Connected to DragonFlyDB successfully")

	// Subscribe to the channel
	pubsub := client.Subscribe(ctx, channel)
	defer pubsub.Close()

	// Wait for confirmation of subscription
	_, err = pubsub.Receive(ctx)
	if err != nil {
		logger.Fatalf("Failed to subscribe: %v", err)
	}
	logger.Printf("Subscribed to channel: %s", channel)

	// Get the channel for receiving messages
	msgChan := pubsub.Channel()

	// Start a goroutine to handle messages
	go func() {
		for {
			select {
			case <-ctx.Done():
				return
			case msg := <-msgChan:
				// Process received message
				var message Message
				err := json.Unmarshal([]byte(msg.Payload), &message)
				if err != nil {
					logger.Printf("Error unmarshaling message: %v", err)
					continue
				}

				// Calculate time since message was published
				latency := time.Since(message.Timestamp)

				logger.Printf("Received message: %s (latency: %v)", msg.Payload, latency)

				// Process the message (in a real application, you would do something with it)
				logger.Printf("Processing message: %s", message.Content)
			}
		}
	}()

	// Wait for termination signal
	<-sigChan
	logger.Println("Shutdown signal received, closing connections...")

	// Unsubscribe and close the Redis client connection
	if err := pubsub.Unsubscribe(ctx, channel); err != nil {
		logger.Printf("Error unsubscribing: %v", err)
	}

	if err := client.Close(); err != nil {
		logger.Printf("Error closing Redis connection: %v", err)
	}

	logger.Println("Subscriber service stopped")
}
