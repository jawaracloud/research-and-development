# Tokenization System Design

## Overview

The tokenization system provides secure, stateless authentication for users in the waiting room. It uses JWT (JSON Web Tokens) with RSA signatures for tamper-proof tokens that can be validated without database lookups.

---

## Token Types

### 1. Queue Token (Waiting Phase)

Issued when a user joins the queue. Used to track position and maintain state.

```
QueueToken Claims:
{
    "jti": "position-uuid",           // JWT ID = position ID
    "sub": "queue:ticket-sale",       // Subject = queue identifier
    "iat": 1704067200,                // Issued At
    "exp": 1704069000,                // Expires At (30 min)
    "typ": "queue",                   // Token Type
    "priority": 0,                    // Priority level
    "ip_hash": "abc123...",           // Hashed IP for binding
}
```

**Purpose:**
- Resume position after page refresh
- Authenticate heartbeat requests
- Prevent queue jumping

### 2. Session Token (Active Phase)

Issued when user is admitted. Grants access to protected resource.

```
SessionToken Claims:
{
    "jti": "session-uuid",            // JWT ID = session ID
    "sub": "queue:ticket-sale",       // Subject = queue identifier
    "iat": 1704067200,                // Issued At
    "exp": 1704070800,                // Expires At (1 hour)
    "typ": "session",                 // Token Type
    "position_id": "pos-uuid",        // Original position
    "ip_hash": "abc123...",           // Hashed IP for binding
}
```

**Purpose:**
- Access protected resource
- Validate session continuity
- Track user activity

---

## Token Structure

### JWT Header

```json
{
    "alg": "RS256",
    "typ": "JWT",
    "kid": "key-id-2024-01"
}
```

### JWT Payload (Queue Token)

```json
{
    "jti": "550e8400-e29b-41d4-a716-446655440000",
    "sub": "queue:concert-tickets",
    "iat": 1704067200,
    "exp": 1704069000,
    "nbf": 1704067200,
    "typ": "queue",
    "priority": 0,
    "ip_hash": "a1b2c3d4e5f6...",
    "attrs": {
        "user_agent_hash": "xyz789..."
    }
}
```

### JWT Signature

```
HMACSHA256(
    base64UrlEncode(header) + "." + base64UrlEncode(payload),
    RSA_PRIVATE_KEY
)
```

---

## Token Lifecycle

### State Diagram

```
                    +-------------+
                    |   CREATED   |
                    +------+------+
                           |
                    signing|operation
                           v
                    +------+------+
               +--->|    VALID    |<---+
               |    +------+------+    |
               |           |          |
        (expired)    (refresh)   (validate)
               |           |          |
               v           |          |
        +------+------+    |    +-----v-----+
        |   EXPIRED   |----+    |   VALID   |
        +-------------+         +-----------+
               |                      |
               | (revoke)             | (revoke)
               v                      v
        +-------------+         +-----------+
        |   REVOKED   |         |  REVOKED  |
        +-------------+         +-----------+
```

### Lifecycle Events

| Event | Trigger | Action |
|-------|---------|--------|
| Create | User enqueues | Generate queue token |
| Refresh | Heartbeat received | Extend expiry, re-sign |
| Upgrade | User admitted | Issue session token |
| Expire | TTL elapsed | Mark as expired |
| Revoke | Admin action / abuse | Add to revocation list |

---

## Token Generation

### Queue Token Generation

```go
type TokenService struct {
    privateKey    *rsa.PrivateKey
    publicKey     *rsa.PublicKey
    keyID         string
    tokenTTL      time.Duration
    sessionTTL    time.Duration
    ipSalt        string
}

type QueueTokenClaims struct {
    jwt.RegisteredClaims
    Type      string `json:"typ"`
    Priority  int    `json:"priority"`
    IPHash    string `json:"ip_hash"`
    UserAgent string `json:"ua_hash,omitempty"`
}

func (s *TokenService) GenerateQueueToken(ctx context.Context, position *Position) (string, error) {
    now := time.Now()
    expiresAt := now.Add(s.tokenTTL)
    
    claims := QueueTokenClaims{
        RegisteredClaims: jwt.RegisteredClaims{
            ID:        position.ID,
            Subject:   position.QueueID,
            IssuedAt:  jwt.NewNumericDate(now),
            ExpiresAt: jwt.NewNumericDate(expiresAt),
            NotBefore: jwt.NewNumericDate(now),
        },
        Type:     "queue",
        Priority: position.Priority,
        IPHash:   s.hashIP(position.IPAddress),
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
    token.Header["kid"] = s.keyID
    
    signed, err := token.SignedString(s.privateKey)
    if err != nil {
        return "", fmt.Errorf("signing token: %w", err)
    }
    
    return signed, nil
}

func (s *TokenService) hashIP(ip string) string {
    h := sha256.New()
    h.Write([]byte(s.ipSalt + ip))
    return hex.EncodeToString(h.Sum(nil))[:16]
}
```

### Session Token Generation

```go
func (s *TokenService) GenerateSessionToken(ctx context.Context, session *Session) (string, error) {
    now := time.Now()
    expiresAt := now.Add(s.sessionTTL)
    
    claims := SessionTokenClaims{
        RegisteredClaims: jwt.RegisteredClaims{
            ID:        session.ID,
            Subject:   session.QueueID,
            IssuedAt:  jwt.NewNumericDate(now),
            ExpiresAt: jwt.NewNumericDate(expiresAt),
            NotBefore: jwt.NewNumericDate(now),
        },
        Type:       "session",
        PositionID: session.PositionID,
        IPHash:     s.hashIP(session.IPAddress),
    }
    
    token := jwt.NewWithClaims(jwt.SigningMethodRS256, claims)
    token.Header["kid"] = s.keyID
    
    return token.SignedString(s.privateKey)
}
```

---

## Token Validation

### Validation Steps

```
1. Parse token without verification (extract header)
2. Check algorithm is RS256 (prevent algorithm confusion)
3. Look up public key by kid
4. Verify signature
5. Validate claims:
   - exp > now (not expired)
   - nbf <= now (not before)
   - typ matches expected type
   - jti not in revocation list
6. Validate IP binding (optional)
7. Return claims
```

### Implementation

```go
type ValidationResult struct {
    Valid     bool
    Claims    *QueueTokenClaims
    TokenType string
    PositionID string
    QueueID   string
    Err       error
}

func (s *TokenService) ValidateToken(ctx context.Context, tokenString string, expectedType string) (*ValidationResult, error) {
    // Parse token
    token, err := jwt.ParseWithClaims(tokenString, &QueueTokenClaims{}, func(token *jwt.Token) (interface{}, error) {
        // Verify algorithm
        if _, ok := token.Method.(*jwt.SigningMethodRSA); !ok {
            return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
        }
        
        // Get key ID
        kid, ok := token.Header["kid"].(string)
        if !ok {
            return nil, fmt.Errorf("missing key ID")
        }
        
        // Verify key ID matches
        if kid != s.keyID {
            return nil, fmt.Errorf("unknown key ID: %s", kid)
        }
        
        return s.publicKey, nil
    })
    
    if err != nil {
        return &ValidationResult{Valid: false, Err: err}, err
    }
    
    claims, ok := token.Claims.(*QueueTokenClaims)
    if !ok {
        return &ValidationResult{Valid: false, Err: ErrInvalidClaims}, ErrInvalidClaims
    }
    
    // Check token type
    if claims.Type != expectedType {
        return &ValidationResult{Valid: false, Err: ErrWrongTokenType}, ErrWrongTokenType
    }
    
    // Check revocation list
    revoked, err := s.isRevoked(ctx, claims.ID)
    if err != nil {
        return nil, fmt.Errorf("checking revocation: %w", err)
    }
    if revoked {
        return &ValidationResult{Valid: false, Err: ErrTokenRevoked}, ErrTokenRevoked
    }
    
    return &ValidationResult{
        Valid:      true,
        Claims:     claims,
        TokenType:  claims.Type,
        PositionID: claims.ID,
        QueueID:    claims.Subject,
    }, nil
}
```

---

## Token Refresh

### Refresh Strategy

Tokens are refreshed on heartbeat to maintain session continuity:

```
Timeline:
|----|----|----|----|----|----|
0    5    10   15   20   25   30 (minutes)

Token issued at 0, expires at 30
Heartbeat at 10 -> token refreshed, new expiry at 40
Heartbeat at 20 -> token refreshed, new expiry at 50
...
```

### Implementation

```go
func (s *TokenService) RefreshToken(ctx context.Context, oldToken string) (string, error) {
    // Validate old token (allow expired for refresh window)
    result, err := s.validateForRefresh(ctx, oldToken)
    if err != nil {
        return "", err
    }
    
    // Check refresh window (allow refresh within 5 min of expiry)
    now := time.Now()
    if result.Claims.ExpiresAt.Time.After(now.Add(5 * time.Minute)) {
        // Token not near expiry, return same token
        return oldToken, nil
    }
    
    // Generate new token with same claims but new expiry
    newClaims := *result.Claims
    newClaims.IssuedAt = jwt.NewNumericDate(now)
    newClaims.ExpiresAt = jwt.NewNumericDate(now.Add(s.tokenTTL))
    
    token := jwt.NewWithClaims(jwt.SigningMethodRS256, newClaims)
    token.Header["kid"] = s.keyID
    
    newToken, err := token.SignedString(s.privateKey)
    if err != nil {
        return "", fmt.Errorf("signing refreshed token: %w", err)
    }
    
    // Optionally: add old token to revocation list
    // s.revokeToken(ctx, result.Claims.ID)
    
    return newToken, nil
}
```

---

## Token Revocation

### Revocation List

Since JWTs are stateless, we need a revocation mechanism for:
- Admin-initiated bans
- Abuse detection
- Session termination

**Redis-based Revocation List:**

```
Key: revocation:{token_id}
Value: reason
TTL: remaining token TTL

Example:
SET revocation:550e8400-e29b-41d4-a716-446655440000 "abuse_detected" EX 1800
```

### Implementation

```go
func (s *TokenService) RevokeToken(ctx context.Context, tokenID string, reason string, ttl time.Duration) error {
    key := fmt.Sprintf("revocation:%s", tokenID)
    return s.redis.Set(ctx, key, reason, ttl).Err()
}

func (s *TokenService) isRevoked(ctx context.Context, tokenID string) (bool, error) {
    key := fmt.Sprintf("revocation:%s", tokenID)
    exists, err := s.redis.Exists(ctx, key).Result()
    if err != nil {
        return false, err
    }
    return exists > 0, nil
}

func (s *TokenService) RevokeByQueue(ctx context.Context, queueID string, reason string) error {
    // This requires tracking tokens by queue
    // Use a set: queue:{queue_id}:tokens -> set of token IDs
    
    tokenIDs, err := s.redis.SMembers(ctx, fmt.Sprintf("queue:%s:tokens", queueID)).Result()
    if err != nil {
        return err
    }
    
    for _, tokenID := range tokenIDs {
        s.RevokeToken(ctx, tokenID, reason, 24*time.Hour)
    }
    
    return nil
}
```

---

## Tamper-Proof Design

### Security Measures

| Threat | Mitigation |
|--------|------------|
| Token forgery | RSA-256 signature, private key never exposed |
| Algorithm confusion | Explicit algorithm check in validator |
| Token replay | Short TTL, revocation list |
| Token theft | IP binding, User-Agent binding |
| Key compromise | Key rotation support, multiple key IDs |

### IP Binding

```go
func (s *TokenService) ValidateIPBinding(ctx context.Context, claims *QueueTokenClaims, clientIP string) bool {
    expectedHash := s.hashIP(clientIP)
    return subtle.ConstantTimeCompare([]byte(claims.IPHash), []byte(expectedHash)) == 1
}
```

### Key Rotation

```go
type KeyManager struct {
    keys map[string]*rsa.PrivateKey
    activeKeyID string
}

func (km *KeyManager) RotateKey(newKey *rsa.PrivateKey, newKeyID string) {
    km.keys[newKeyID] = newKey
    km.activeKeyID = newKeyID
}

func (km *KeyManager) GetKey(keyID string) (*rsa.PrivateKey, error) {
    key, ok := km.keys[keyID]
    if !ok {
        return nil, ErrKeyNotFound
    }
    return key, nil
}
```

---

## Token Transmission

### Cookie-Based (Recommended)

```
Set-Cookie: waiting_room_token=<jwt>; 
    HttpOnly; 
    Secure; 
    SameSite=Strict; 
    Path=/;
    Max-Age=1800
```

**Advantages:**
- Automatic transmission
- Protected from JavaScript (XSS)
- Browser handles expiry

### Authorization Header (API)

```
Authorization: Bearer <jwt>
```

**Use Case:**
- API clients
- Mobile apps
- Server-to-server

---

## Token Storage

### Client-Side

| Storage | Pros | Cons |
|---------|------|------|
| HttpOnly Cookie | XSS protection | CSRF vulnerability |
| localStorage | Easy access | XSS vulnerable |
| sessionStorage | Tab-scoped | Lost on tab close |

**Recommendation:** HttpOnly cookie with CSRF token

### Server-Side (for revocation)

```
Redis Structure:
- revocation:{token_id} -> reason (TTL = token remaining TTL)
- queue:{queue_id}:tokens -> SET of token IDs
- session:{session_id}:token -> current token string
```
