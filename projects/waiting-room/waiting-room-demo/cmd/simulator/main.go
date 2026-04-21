// Package main implements a simulation client for the waiting room.
package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"math/rand"
	"net/http"
	"os"
	"os/signal"
	"sync"
	"sync/atomic"
	"syscall"
	"time"
)

// Config holds simulation configuration.
type Config struct {
	ServerURL     string
	QueueID       string
	NumUsers      int
	HeartbeatRate time.Duration
	ThinkTime     time.Duration
}

// User represents a simulated user.
type User struct {
	ID       int
	Token    string
	Position int64
	Status   string
}

// Stats holds simulation statistics.
type Stats struct {
	TotalEnqueued   int64
	TotalAdmitted   int64
	TotalExpired    int64
	TotalHeartbeats int64
}

func main() {
	config := Config{
		ServerURL:     getEnv("SERVER_URL", "http://localhost:8080"),
		QueueID:       getEnv("QUEUE_ID", "concert-tickets"),
		NumUsers:      100,
		HeartbeatRate: 10 * time.Second,
		ThinkTime:     5 * time.Second,
	}

	stats := &Stats{}
	ctx, cancel := context.WithCancel(context.Background())

	// Handle shutdown
	sigChan := make(chan os.Signal, 1)
	signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
	go func() {
		<-sigChan
		log.Println("\nShutting down simulation...")
		cancel()
	}()

	log.Printf("Starting simulation with %d users", config.NumUsers)
	log.Printf("Server: %s", config.ServerURL)
	log.Printf("Queue: %s", config.QueueID)

	var wg sync.WaitGroup
	users := make(chan int, config.NumUsers)

	// Create users
	for i := 0; i < config.NumUsers; i++ {
		users <- i + 1
	}
	close(users)

	// Start workers
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for userID := range users {
				simulateUser(ctx, config, userID, stats)
			}
		}()
	}

	// Print stats periodically
	go func() {
		ticker := time.NewTicker(5 * time.Second)
		defer ticker.Stop()

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				printStats(stats)
			}
		}
	}()

	wg.Wait()

	log.Println("\n=== Final Statistics ===")
	printStats(stats)
}

func simulateUser(ctx context.Context, config Config, userID int, stats *Stats) {
	// Random delay before joining
	time.Sleep(time.Duration(rand.Intn(5000)) * time.Millisecond)

	// Join queue
	user, err := enqueue(config, userID)
	if err != nil {
		log.Printf("User %d: Failed to enqueue: %v", userID, err)
		return
	}
	atomic.AddInt64(&stats.TotalEnqueued, 1)
	log.Printf("User %d: Joined queue at position %d", userID, user.Position)

	// Heartbeat loop
	ticker := time.NewTicker(config.HeartbeatRate)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			// Send heartbeat
			status, err := heartbeat(config, user.Token)
			if err != nil {
				log.Printf("User %d: Heartbeat failed: %v", userID, err)
				atomic.AddInt64(&stats.TotalExpired, 1)
				return
			}

			atomic.AddInt64(&stats.TotalHeartbeats, 1)
			user.Position = status.Position
			user.Status = status.Status

			if status.Status == "admitted" {
				log.Printf("User %d: Admitted! Session token received", userID)
				atomic.AddInt64(&stats.TotalAdmitted, 1)
				return
			}

			// Random chance to abandon
			if rand.Float64() < 0.01 { // 1% chance per heartbeat
				log.Printf("User %d: Abandoned queue", userID)
				return
			}
		}
	}
}

type EnqueueResponse struct {
	PositionID           string    `json:"position_id"`
	QueueID              string    `json:"queue_id"`
	Position             int64     `json:"position"`
	QueueLength          int64     `json:"queue_length"`
	EstimatedWaitSeconds int64     `json:"estimated_wait_seconds"`
	Status               string    `json:"status"`
	Token                string    `json:"token"`
	ExpiresAt            time.Time `json:"expires_at"`
}

type StatusResponse struct {
	PositionID  string `json:"position_id"`
	Status      string `json:"status"`
	Position    int64  `json:"position"`
	QueueLength int64  `json:"queue_length"`
	Admitted    bool   `json:"admitted"`
}

func enqueue(config Config, userID int) (*User, error) {
	url := fmt.Sprintf("%s/api/v1/queues/%s/enqueue", config.ServerURL, config.QueueID)

	resp, err := http.Post(url, "application/json", nil)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result EnqueueResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return &User{
		ID:       userID,
		Token:    result.Token,
		Position: result.Position,
		Status:   result.Status,
	}, nil
}

func heartbeat(config Config, token string) (*StatusResponse, error) {
	url := fmt.Sprintf("%s/api/v1/queues/%s/heartbeat", config.ServerURL, config.QueueID)

	req, _ := http.NewRequest("POST", url, nil)
	req.Header.Set("Authorization", "Bearer "+token)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	var result StatusResponse
	if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
		return nil, err
	}

	return &result, nil
}

func printStats(stats *Stats) {
	enqueued := atomic.LoadInt64(&stats.TotalEnqueued)
	admitted := atomic.LoadInt64(&stats.TotalAdmitted)
	expired := atomic.LoadInt64(&stats.TotalExpired)
	heartbeats := atomic.LoadInt64(&stats.TotalHeartbeats)

	log.Printf("Enqueued: %d | Admitted: %d | Expired: %d | Heartbeats: %d",
		enqueued, admitted, expired, heartbeats)
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
