# API Endpoints and Contracts

## Overview

This document defines the REST API endpoints for the Waiting Room service. All endpoints return JSON responses and follow standard HTTP status codes.

---

## Base URL

```
Production: https://waitingroom.example.com/api/v1
Development: http://localhost:8080/api/v1
```

## Authentication

All endpoints (except health) require authentication via JWT token:

```
Authorization: Bearer <jwt_token>
```

---

## Endpoints

### Health Check

**GET** `/health`

Check service health status.

**Request:**
```http
GET /health HTTP/1.1
```

**Response:**
```json
{
    "status": "healthy",
    "version": "1.0.0",
    "uptime_seconds": 3600,
    "components": {
        "dragonflydb": "healthy",
        "nats": "healthy"
    }
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Service is healthy |
| 503 | Service is unhealthy |

---

### Enqueue

**POST** `/queues/{queue_id}/enqueue`

Join a waiting room queue.

**Path Parameters:**
| Name | Type | Description |
|------|------|-------------|
| queue_id | string | Queue identifier |

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| X-Forwarded-For | No | Client IP address |
| User-Agent | No | Client user agent |

**Request Body:**
```json
{
    "priority": 0,
    "metadata": {
        "user_id": "user-123",
        "campaign": "summer-sale"
    }
}
```

**Request Schema:**
```json
{
    "$schema": "http://json-schema.org/draft-07/schema#",
    "type": "object",
    "properties": {
        "priority": {
            "type": "integer",
            "minimum": 0,
            "maximum": 3,
            "default": 0
        },
        "metadata": {
            "type": "object",
            "additionalProperties": {
                "type": ["string", "number", "boolean"]
            }
        }
    }
}
```

**Response:**
```json
{
    "position_id": "550e8400-e29b-41d4-a716-446655440000",
    "queue_id": "concert-tickets",
    "position": 1523,
    "queue_length": 1523,
    "estimated_wait_seconds": 300,
    "status": "waiting",
    "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
    "heartbeat_interval_seconds": 10,
    "heartbeat_timeout_seconds": 60,
    "expires_at": "2024-01-01T12:30:00Z"
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Successfully joined queue (existing position returned) |
| 201 | Successfully joined queue (new position created) |
| 400 | Invalid request body |
| 429 | Rate limit exceeded |
| 503 | Queue is full or in maintenance mode |

**Rate Limit:**
- 10 requests per minute per IP

---

### Get Status

**GET** `/queues/{queue_id}/status`

Get current position in queue.

**Path Parameters:**
| Name | Type | Description |
|------|------|-------------|
| queue_id | string | Queue identifier |

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| Authorization | Yes | Bearer token from enqueue |

**Request:**
```http
GET /queues/concert-tickets/status HTTP/1.1
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Response (Waiting):**
```json
{
    "position_id": "550e8400-e29b-41d4-a716-446655440000",
    "queue_id": "concert-tickets",
    "status": "waiting",
    "position": 1523,
    "queue_length": 1523,
    "estimated_wait_seconds": 300,
    "admitted": false,
    "token": "eyJhbGciOiJSUzI1NiIs...",
    "expires_at": "2024-01-01T12:30:00Z"
}
```

**Response (Admitted):**
```json
{
    "position_id": "550e8400-e29b-41d4-a716-446655440000",
    "queue_id": "concert-tickets",
    "status": "admitted",
    "position": 0,
    "queue_length": 1522,
    "estimated_wait_seconds": 0,
    "admitted": true,
    "session_token": "eyJhbGciOiJSUzI1NiIs...",
    "redirect_url": "https://example.com/checkout",
    "session_expires_at": "2024-01-01T13:00:00Z"
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Position found |
| 401 | Invalid or missing token |
| 404 | Position not found |
| 410 | Position has expired |

---

### Heartbeat

**POST** `/queues/{queue_id}/heartbeat`

Send heartbeat to maintain position in queue.

**Path Parameters:**
| Name | Type | Description |
|------|------|-------------|
| queue_id | string | Queue identifier |

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| Authorization | Yes | Bearer token |

**Request Body:**
```json
{
    "timestamp": 1704067260000,
    "client_id": "browser-fingerprint-abc123"
}
```

**Response:**
```json
{
    "position_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "waiting",
    "position": 1520,
    "queue_length": 1520,
    "estimated_wait_seconds": 290,
    "token": "eyJhbGciOiJSUzI1NiIs...",
    "next_heartbeat_seconds": 10
}
```

**Response (Admitted):**
```json
{
    "position_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "admitted",
    "session_token": "eyJhbGciOiJSUzI1NiIs...",
    "redirect_url": "https://example.com/checkout"
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Heartbeat recorded |
| 401 | Invalid or missing token |
| 410 | Position has expired |

**Rate Limit:**
- 30 requests per minute per token

---

### Cancel Position

**DELETE** `/queues/{queue_id}/position`

Cancel position and leave the queue.

**Path Parameters:**
| Name | Type | Description |
|------|------|-------------|
| queue_id | string | Queue identifier |

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| Authorization | Yes | Bearer token |

**Request:**
```http
DELETE /queues/concert-tickets/position HTTP/1.1
Authorization: Bearer eyJhbGciOiJSUzI1NiIs...
```

**Response:**
```json
{
    "position_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "cancelled",
    "cancelled_at": "2024-01-01T12:05:00Z"
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Position cancelled |
| 401 | Invalid or missing token |
| 404 | Position not found |

---

### Session Status

**GET** `/sessions/{session_id}`

Get active session status.

**Path Parameters:**
| Name | Type | Description |
|------|------|-------------|
| session_id | string | Session identifier |

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| Authorization | Yes | Session token |

**Response:**
```json
{
    "session_id": "a1b2c3d4-e5f6-7890",
    "queue_id": "concert-tickets",
    "position_id": "550e8400-e29b-41d4-a716-446655440000",
    "status": "active",
    "started_at": "2024-01-01T12:00:00Z",
    "expires_at": "2024-01-01T13:00:00Z",
    "last_activity": "2024-01-01T12:30:00Z",
    "page_views": 5,
    "remaining_seconds": 1800
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Session found |
| 401 | Invalid or missing token |
| 404 | Session not found |
| 410 | Session has expired |

---

### Session Activity

**POST** `/sessions/{session_id}/activity`

Record session activity (page view, action).

**Path Parameters:**
| Name | Type | Description |
|------|------|-------------|
| session_id | string | Session identifier |

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| Authorization | Yes | Session token |

**Request Body:**
```json
{
    "action": "page_view",
    "page": "/checkout",
    "timestamp": 1704067260000
}
```

**Response:**
```json
{
    "session_id": "a1b2c3d4-e5f6-7890",
    "status": "active",
    "page_views": 6,
    "expires_at": "2024-01-01T13:00:00Z"
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 200 | Activity recorded |
| 401 | Invalid or missing token |
| 410 | Session has expired |

---

## Admin Endpoints

### Create Queue

**POST** `/admin/queues`

Create a new waiting room queue.

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| X-Admin-Key | Yes | Admin API key |

**Request Body:**
```json
{
    "id": "concert-tickets",
    "name": "Concert Ticket Sale",
    "target_url": "https://example.com/checkout",
    "max_active_users": 1000,
    "max_queue_size": 50000,
    "admission_rate": 10,
    "session_timeout_seconds": 3600,
    "heartbeat_interval_seconds": 10,
    "heartbeat_timeout_seconds": 60
}
```

**Response:**
```json
{
    "id": "concert-tickets",
    "name": "Concert Ticket Sale",
    "status": "active",
    "created_at": "2024-01-01T00:00:00Z"
}
```

**Status Codes:**
| Code | Description |
|------|-------------|
| 201 | Queue created |
| 400 | Invalid request |
| 409 | Queue already exists |
| 403 | Invalid admin key |

---

### Update Queue

**PATCH** `/admin/queues/{queue_id}`

Update queue configuration.

**Path Parameters:**
| Name | Type | Description |
|------|------|-------------|
| queue_id | string | Queue identifier |

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| X-Admin-Key | Yes | Admin API key |

**Request Body:**
```json
{
    "admission_rate": 20,
    "max_active_users": 2000,
    "status": "paused"
}
```

**Response:**
```json
{
    "id": "concert-tickets",
    "name": "Concert Ticket Sale",
    "status": "paused",
    "admission_rate": 20,
    "max_active_users": 2000,
    "updated_at": "2024-01-01T12:00:00Z"
}
```

---

### Get Queue Stats

**GET** `/admin/queues/{queue_id}/stats`

Get queue statistics.

**Path Parameters:**
| Name | Type | Description |
|------|------|-------------|
| queue_id | string | Queue identifier |

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| X-Admin-Key | Yes | Admin API key |

**Response:**
```json
{
    "queue_id": "concert-tickets",
    "status": "active",
    "current_waiting": 1523,
    "current_active": 850,
    "total_enqueued_today": 15000,
    "total_admitted_today": 5000,
    "total_expired_today": 200,
    "avg_wait_time_seconds": 180,
    "peak_queue_size": 12000,
    "admission_rate_actual": 9.5
}
```

---

### Terminate Session

**DELETE** `/admin/sessions/{session_id}`

Force terminate an active session.

**Path Parameters:**
| Name | Type | Description |
|------|------|-------------|
| session_id | string | Session identifier |

**Request Headers:**
| Name | Required | Description |
|------|----------|-------------|
| X-Admin-Key | Yes | Admin API key |

**Request Body:**
```json
{
    "reason": "abuse_detected"
}
```

**Response:**
```json
{
    "session_id": "a1b2c3d4-e5f6-7890",
    "status": "terminated",
    "terminated_at": "2024-01-01T12:00:00Z",
    "reason": "abuse_detected"
}
```

---

## Error Responses

All errors follow a consistent format:

```json
{
    "error": {
        "code": "POSITION_EXPIRED",
        "message": "Your position in the queue has expired",
        "details": {
            "position_id": "550e8400-e29b-41d4-a716-446655440000",
            "expired_at": "2024-01-01T12:00:00Z"
        }
    },
    "request_id": "req-abc123"
}
```

### Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `INVALID_REQUEST` | 400 | Request validation failed |
| `UNAUTHORIZED` | 401 | Missing or invalid authentication |
| `FORBIDDEN` | 403 | Insufficient permissions |
| `NOT_FOUND` | 404 | Resource not found |
| `POSITION_EXPIRED` | 410 | Position has expired |
| `SESSION_EXPIRED` | 410 | Session has expired |
| `RATE_LIMITED` | 429 | Rate limit exceeded |
| `QUEUE_FULL` | 503 | Queue is at maximum capacity |
| `MAINTENANCE_MODE` | 503 | Queue is in maintenance mode |
| `INTERNAL_ERROR` | 500 | Internal server error |

---

## Rate Limiting

### Headers

All responses include rate limit headers:

```http
X-RateLimit-Limit: 10
X-RateLimit-Remaining: 7
X-RateLimit-Reset: 1704067260
```

### Limits by Endpoint

| Endpoint | Limit | Window | Scope |
|----------|-------|--------|-------|
| `/enqueue` | 10 | 1 minute | IP |
| `/status` | 60 | 1 minute | Token |
| `/heartbeat` | 30 | 1 minute | Token |
| `/sessions/*/activity` | 100 | 1 minute | Token |
| Admin endpoints | 100 | 1 minute | API Key |

---

## WebSocket Endpoint

### Real-time Updates

**WebSocket** `/ws/queues/{queue_id}`

Connect for real-time position updates.

**Connection:**
```javascript
const ws = new WebSocket('wss://waitingroom.example.com/ws/queues/concert-tickets', {
    headers: {
        'Authorization': 'Bearer <token>'
    }
});
```

**Server Messages:**

Position Update:
```json
{
    "type": "position_update",
    "data": {
        "position": 1520,
        "queue_length": 1520,
        "estimated_wait_seconds": 290
    }
}
```

Admitted:
```json
{
    "type": "admitted",
    "data": {
        "session_token": "eyJhbGciOiJSUzI1NiIs...",
        "redirect_url": "https://example.com/checkout"
    }
}
```

Expired:
```json
{
    "type": "expired",
    "data": {
        "reason": "heartbeat_timeout"
    }
}
```

**Client Messages:**

Heartbeat:
```json
{
    "type": "heartbeat",
    "data": {
        "timestamp": 1704067260000
    }
}
```

---

## OpenAPI Specification

```yaml
openapi: 3.0.3
info:
  title: Waiting Room API
  version: 1.0.0
  description: API for managing virtual waiting rooms

servers:
  - url: https://waitingroom.example.com/api/v1
    description: Production
  - url: http://localhost:8080/api/v1
    description: Development

paths:
  /health:
    get:
      summary: Health check
      responses:
        '200':
          description: Service is healthy
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/HealthResponse'

  /queues/{queue_id}/enqueue:
    post:
      summary: Join queue
      parameters:
        - name: queue_id
          in: path
          required: true
          schema:
            type: string
      requestBody:
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/EnqueueRequest'
      responses:
        '200':
          description: Existing position returned
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/EnqueueResponse'
        '201':
          description: New position created
          content:
            application/json:
              schema:
                $ref: '#/components/schemas/EnqueueResponse'

components:
  schemas:
    HealthResponse:
      type: object
      properties:
        status:
          type: string
          enum: [healthy, unhealthy]
        version:
          type: string
        uptime_seconds:
          type: integer
        components:
          type: object
          additionalProperties:
            type: string

    EnqueueRequest:
      type: object
      properties:
        priority:
          type: integer
          minimum: 0
          maximum: 3
          default: 0
        metadata:
          type: object
          additionalProperties:
            type: [string, number, boolean]

    EnqueueResponse:
      type: object
      properties:
        position_id:
          type: string
          format: uuid
        queue_id:
          type: string
        position:
          type: integer
        queue_length:
          type: integer
        estimated_wait_seconds:
          type: integer
        status:
          type: string
          enum: [waiting, admitted, expired]
        token:
          type: string
        heartbeat_interval_seconds:
          type: integer
        heartbeat_timeout_seconds:
          type: integer
        expires_at:
          type: string
          format: date-time

  securitySchemes:
    BearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT

security:
  - BearerAuth: []
```
