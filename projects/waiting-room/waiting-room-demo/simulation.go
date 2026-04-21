package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"sync"
	"time"

	"github.com/jawaracloud/waiting-room-demo/pkg/models"
)

var (
	BaseURL = getEnv("BASE_URL", "http://localhost:8080")
	Users   = 50
)

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok {
		return value
	}
	return fallback
}

func main() {
	var wg sync.WaitGroup
	startTime := time.Now()

	for i := 0; i < Users; i++ {
		wg.Add(1)
		go func(id int) {
			defer wg.Done()
			simulateUser(id)
		}(i)
		time.Sleep(100 * time.Millisecond) // Staggered arrival
	}

	wg.Wait()
	fmt.Printf("Simulation finished in %v\n", time.Since(startTime))
}

func simulateUser(id int) {
	start := time.Now()
	// 1. Enqueue
	resp, err := http.Post(BaseURL+"/enqueue", "application/json", nil)
	if err != nil {
		fmt.Printf("User %d: Enqueue failed: %v\n", id, err)
		return
	}
	defer resp.Body.Close()

	token := resp.Header.Get("X-Queue-Token")
	var status models.QueueStatus
	if err := json.NewDecoder(resp.Body).Decode(&status); err != nil {
		fmt.Printf("User %d: Failed to decode status: %v\n", id, err)
		return
	}

	fmt.Printf("User %d: Enqueued. Position: %d\n", id, status.Position)

	if status.Allowed {
		fmt.Printf("User %d: ALLOWED IMMEDIATELY! Time: %v\n", id, time.Since(start))
		return
	}

	// 2. Heartbeat until allowed
	ticker := time.NewTicker(2 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		reqBody, _ := json.Marshal(models.HeartbeatRequest{Token: token})
		resp, err := http.Post(BaseURL+"/status", "application/json", bytes.NewBuffer(reqBody))
		if err != nil {
			fmt.Printf("User %d: Status check failed: %v\n", id, err)
			continue
		}

		var currentStatus models.QueueStatus
		if err := json.NewDecoder(resp.Body).Decode(&currentStatus); err != nil {
			resp.Body.Close()
			continue
		}
		resp.Body.Close()

		if currentStatus.Allowed {
			fmt.Printf("User %d: ALLOWED! Time to entry: %v\n", id, time.Since(start))
			return
		}

		fmt.Printf("User %d: Still waiting. Position: %d/%d\n", id, currentStatus.Position, currentStatus.TotalInQueue)
	}
}
