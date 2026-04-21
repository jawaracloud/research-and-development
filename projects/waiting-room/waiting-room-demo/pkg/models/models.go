package models

import "github.com/golang-jwt/jwt/v5"

// QueueToken claims for JWT
type QueueToken struct {
	QueueID   string `json:"queue_id"`
	IssuedAt  int64  `json:"issued_at"`
	ExpiresAt int64  `json:"expires_at"`
	jwt.RegisteredClaims
}

// QueueStatus represents the current status of a user in the queue
type QueueStatus struct {
	InQueue      bool   `json:"in_queue"`
	Position     int64  `json:"position"`
	TotalInQueue int64  `json:"total_in_queue"`
	Allowed      bool   `json:"allowed"`
	TargetURL    string `json:"target_url,omitempty"`
	WaitTimeEst  int64  `json:"wait_time_est_seconds"` // Estimated wait time
}

// HeartbeatRequest from client
type HeartbeatRequest struct {
	Token string `json:"token"`
}
