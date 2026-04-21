package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/redis/go-redis/v9"
)

// Message represents the data structure to be published
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
	logger := log.New(os.Stdout, "[PUBLISHER] ", log.LstdFlags)
	logger.Printf("Starting publisher service. Publishing to channel: %s", channel)

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

	// Start publishing in a separate goroutine
	go func() {
		messageCount := 0
		for {
			select {
			case <-ctx.Done():
				return
			default:
				messageCount++

				// Create a new message
				msg := Message{
					ID:        fmt.Sprintf("msg-%d", messageCount),
					Content:   fmt.Sprintf("This is message #%d", messageCount),
					Timestamp: time.Now(),
				}

				// Convert message to JSON
				jsonMsg, err := json.Marshal(msg)
				if err != nil {
					logger.Printf("Error marshaling message: %v", err)
					continue
				}

				// Publish message to channel
				err = client.Publish(ctx, channel, jsonMsg).Err()
				if err != nil {
					logger.Printf("Error publishing message: %v", err)
				} else {
					logger.Printf("Published message: %s", string(jsonMsg))
				}

				// Wait before sending the next message
				time.Sleep(2 * time.Second)
			}
		}
	}()

	// Wait for termination signal
	<-sigChan
	logger.Println("Shutdown signal received, closing connections...")

	// Close the Redis client connection
	if err := client.Close(); err != nil {
		logger.Printf("Error closing Redis connection: %v", err)
	}

	logger.Println("Publisher service stopped")
}
