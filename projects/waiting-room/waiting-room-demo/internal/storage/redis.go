package storage

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

const (
	KeyQueue     = "waiting_room:queue"
	KeySessions  = "waiting_room:sessions"
	KeyAllowedTS = "waiting_room:allowed_timestamp"
)

type RedisStorage struct {
	client *redis.Client
}

func NewRedisStorage(addr string) (*RedisStorage, error) {
	client := redis.NewClient(&redis.Options{
		Addr: addr,
	})

	if err := client.Ping(context.Background()).Err(); err != nil {
		return nil, err
	}

	return &RedisStorage{client: client}, nil
}

// Enqueue adds a user to the queue and returns the current queue size
func (s *RedisStorage) Enqueue(ctx context.Context, queueID string, score int64) (int64, error) {
	script := `
		redis.call('ZADD', KEYS[1], ARGV[2], ARGV[1])
		redis.call('HSET', KEYS[2], ARGV[1], ARGV[2])
		return redis.call('ZCARD', KEYS[1])
	`
	res, err := s.client.Eval(ctx, script, []string{KeyQueue, KeySessions}, queueID, score).Int64()
	if err != nil {
		return 0, err
	}
	return res, nil
}

// GetStatus checks if user is allowed or returns their position
func (s *RedisStorage) GetStatus(ctx context.Context, queueID string, currentTime int64) (bool, int64, int64, error) {
	script := `
		local queue_id = ARGV[1]
		local current_time = tonumber(ARGV[2])
		local allowed_ts = tonumber(redis.call('GET', KEYS[1]) or 0)
		local score = redis.call('ZSCORE', KEYS[2], queue_id)

		if not score then return {-1, 0} end
		score = tonumber(score)

		-- Update heartbeat in sessions hash
		redis.call('HSET', KEYS[3], queue_id, current_time)

		local total = redis.call('ZCARD', KEYS[2])
		if score <= allowed_ts then
			return {0, total} -- Allowed
		else
			local rank = redis.call('ZRANK', KEYS[2], queue_id)
			return {rank + 1, total} -- Position
		end
	`
	res, err := s.client.Eval(ctx, script, []string{KeyAllowedTS, KeyQueue, KeySessions}, queueID, currentTime).Int64Slice()
	if err != nil {
		return false, 0, 0, err
	}

	if res[0] == -1 {
		return false, -1, 0, nil
	}
	if res[0] == 0 {
		return true, 0, res[1], nil
	}
	return false, res[0], res[1], nil
}

// AllowNext increments the allowed timestamp to the score of the Nth user
func (s *RedisStorage) AllowNext(ctx context.Context, n int64) (int64, error) {
	// Get the score of the Nth user in the queue
	vals, err := s.client.ZRangeWithScores(ctx, KeyQueue, n-1, n-1).Result()
	if err != nil || len(vals) == 0 {
		return 0, err
	}

	newAllowedTS := int64(vals[0].Score)
	err = s.client.Set(ctx, KeyAllowedTS, newAllowedTS, 0).Err()
	if err != nil {
		return 0, err
	}

	return newAllowedTS, nil
}

// CleanupStaleSessions removes users who haven't heartbeated for more than the timeout
func (s *RedisStorage) CleanupStaleSessions(ctx context.Context, timeoutSeconds int64) (int64, error) {
	// This is a bit complex for a single Lua script if the set is huge.
	// We'll do it in Go for now or a multi-step Lua.
	// For the demo, let's keep it simple.

	now := time.Now().UnixNano()
	timeoutNano := timeoutSeconds * 1e9
	threshold := now - timeoutNano

	// Get all sessions
	sessions, err := s.client.HGetAll(ctx, KeySessions).Result()
	if err != nil {
		return 0, err
	}

	removed := int64(0)
	for queueID, lastSeenStr := range sessions {
		var lastSeen int64
		fmt.Sscanf(lastSeenStr, "%d", &lastSeen)
		if lastSeen < threshold {
			s.client.ZRem(ctx, KeyQueue, queueID)
			s.client.HDel(ctx, KeySessions, queueID)
			removed++
		}
	}

	return removed, nil
}
