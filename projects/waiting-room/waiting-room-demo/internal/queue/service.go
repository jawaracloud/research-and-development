package queue

import (
	"context"
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jawaracloud/waiting-room-demo/internal/storage"
	"github.com/jawaracloud/waiting-room-demo/pkg/models"
)

var (
	ErrInvalidToken = errors.New("invalid token")
	ErrExpiredToken = errors.New("expired token")
)

type Service struct {
	storage   *storage.RedisStorage
	jwtSecret []byte
}

func NewService(storage *storage.RedisStorage, secret string) *Service {
	return &Service{
		storage:   storage,
		jwtSecret: []byte(secret),
	}
}

func (s *Service) Enqueue(ctx context.Context) (string, *models.QueueStatus, error) {
	queueID := uuid.New().String()
	score := time.Now().UnixNano()

	total, err := s.storage.Enqueue(ctx, queueID, score)
	if err != nil {
		return "", nil, err
	}

	// Create JWT
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, models.QueueToken{
		QueueID:  queueID,
		IssuedAt: score,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
		},
	})

	tokenString, err := token.SignedString(s.jwtSecret)
	if err != nil {
		return "", nil, err
	}

	allowed, pos, _, err := s.storage.GetStatus(ctx, queueID, score)
	if err != nil {
		return "", nil, err
	}

	return tokenString, &models.QueueStatus{
		InQueue:      true,
		Position:     pos,
		TotalInQueue: total,
		Allowed:      allowed,
	}, nil
}

func (s *Service) CheckStatus(ctx context.Context, tokenString string) (*models.QueueStatus, error) {
	token, err := jwt.ParseWithClaims(tokenString, &models.QueueToken{}, func(token *jwt.Token) (interface{}, error) {
		return s.jwtSecret, nil
	})

	if err != nil || !token.Valid {
		return nil, ErrInvalidToken
	}

	claims := token.Claims.(*models.QueueToken)
	now := time.Now().UnixNano()

	allowed, pos, total, err := s.storage.GetStatus(ctx, claims.QueueID, now)
	if err != nil {
		return nil, err
	}

	return &models.QueueStatus{
		InQueue:      pos != -1,
		Position:     pos,
		TotalInQueue: total,
		Allowed:      allowed,
	}, nil
}

func (s *Service) AllowMore(ctx context.Context, n int64) (int64, error) {
	return s.storage.AllowNext(ctx, n)
}

func (s *Service) RunCleanup(ctx context.Context, interval time.Duration, timeout int64) {
	ticker := time.NewTicker(interval)
	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			s.storage.CleanupStaleSessions(ctx, timeout)
		}
	}
}
