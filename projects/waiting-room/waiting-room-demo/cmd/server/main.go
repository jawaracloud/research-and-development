// Package main is the entry point for the waiting room server.
package main

import (
	"context"
	"crypto/rand"
	"crypto/rsa"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"
	"github.com/go-chi/chi/v5/middleware"
	"github.com/jawaracloud/waiting-room-demo/internal/broker"
	"github.com/jawaracloud/waiting-room-demo/internal/handler"
	custommw "github.com/jawaracloud/waiting-room-demo/internal/middleware"
	"github.com/jawaracloud/waiting-room-demo/internal/service"
	"github.com/jawaracloud/waiting-room-demo/internal/store"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

func main() {
	// Load configuration
	config := loadConfig()

	// Initialize RSA key pair for JWT
	privateKey, err := rsa.GenerateKey(rand.Reader, 2048)
	if err != nil {
		log.Fatalf("Failed to generate RSA key: %v", err)
	}

	// Initialize Redis client
	redisClient := store.NewRedisClient(config.DragonFlyDBURL, 100)
	ctx := context.Background()

	// Test Redis connection
	if err := redisClient.Ping(ctx).Err(); err != nil {
		log.Fatalf("Failed to connect to DragonFlyDB: %v", err)
	}
	log.Println("Connected to DragonFlyDB")

	// Initialize store
	redisStore := store.NewRedisStore(redisClient, store.StoreConfig{
		PositionTTL: 30 * time.Minute,
		SessionTTL:  1 * time.Hour,
	})

	// Initialize NATS broker
	natsBroker, err := broker.NewNATSBroker(broker.NATSConfig{
		URL:    config.NatsURL,
		Source: "waitingroom-server",
	})
	if err != nil {
		log.Fatalf("Failed to connect to NATS: %v", err)
	}
	defer natsBroker.Close()
	log.Println("Connected to NATS")

	// Setup JetStream streams
	if err := natsBroker.SetupStreams(ctx); err != nil {
		log.Printf("Warning: Failed to setup streams: %v", err)
	}

	// Initialize services
	tokenService := service.NewTokenService(service.TokenServiceConfig{
		PrivateKey: privateKey,
		KeyID:      "key-2024-01",
		QueueTTL:   30 * time.Minute,
		SessionTTL: 1 * time.Hour,
		IPSalt:     config.IPSalt,
	}, redisStore)

	queueService := service.NewQueueService(redisStore, natsBroker, tokenService, service.QueueServiceConfig{
		DefaultPositionTTL: 30 * time.Minute,
		DefaultSessionTTL:  1 * time.Hour,
		HeartbeatTimeout:   60 * time.Second,
		HeartbeatInterval:  10 * time.Second,
	})

	heartbeatService := service.NewHeartbeatService(redisStore, natsBroker, service.HeartbeatConfig{
		Timeout:         60 * time.Second,
		CleanupInterval: 5 * time.Second,
		BatchSize:       100,
	})

	// Start heartbeat cleanup worker
	if err := heartbeatService.Start(ctx); err != nil {
		log.Fatalf("Failed to start heartbeat service: %v", err)
	}
	defer heartbeatService.Stop()

	// Initialize handlers
	h := handler.NewHandler(queueService, tokenService, heartbeatService, handler.HandlerConfig{
		HeartbeatInterval:  10 * time.Second,
		HeartbeatTimeout:   60 * time.Second,
		DefaultPositionTTL: 30 * time.Minute,
	})

	// Setup router
	r := chi.NewRouter()

	// Global middleware
	r.Use(middleware.RequestID)
	r.Use(middleware.RealIP)
	r.Use(middleware.Recoverer)
	r.Use(middleware.Timeout(60 * time.Second))

	// Custom middleware
	r.Use(custommw.Logger)
	r.Use(custommw.Recovery)
	r.Use(custommw.CORS([]string{"*"}))

	// API routes
	r.Route("/api/v1", func(r chi.Router) {
		h.RegisterRoutes(r)
	})

	// Health check
	r.Get("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Prometheus metrics
	r.Handle("/metrics", promhttp.Handler())

	// Start server
	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", config.Port),
		Handler:      r,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
		IdleTimeout:  60 * time.Second,
	}

	// Graceful shutdown
	go func() {
		sigChan := make(chan os.Signal, 1)
		signal.Notify(sigChan, syscall.SIGINT, syscall.SIGTERM)
		<-sigChan

		log.Println("Shutting down server...")
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()

		if err := server.Shutdown(ctx); err != nil {
			log.Printf("Server shutdown error: %v", err)
		}
	}()

	log.Printf("Starting server on port %d", config.Port)
	if err := server.ListenAndServe(); err != http.ErrServerClosed {
		log.Fatalf("Server error: %v", err)
	}
}

// Config holds application configuration.
type Config struct {
	Port           int
	DragonFlyDBURL string
	NatsURL        string
	IPSalt         string
	LogLevel       string
}

// loadConfig loads configuration from environment variables.
func loadConfig() Config {
	return Config{
		Port:           getEnvInt("PORT", 8080),
		DragonFlyDBURL: getEnv("DRAGONFLYDB_URL", "localhost:6379"),
		NatsURL:        getEnv("NATS_URL", "nats://localhost:4222"),
		IPSalt:         getEnv("IP_SALT", "default-salt-change-in-production"),
		LogLevel:       getEnv("LOG_LEVEL", "info"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

func getEnvInt(key string, defaultValue int) int {
	if value := os.Getenv(key); value != "" {
		var result int
		fmt.Sscanf(value, "%d", &result)
		return result
	}
	return defaultValue
}
