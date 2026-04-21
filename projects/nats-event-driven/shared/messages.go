package shared

import (
	"encoding/json"
	"time"
)

// OrderCreatedEvent represents a new order placed in the system.
type OrderCreatedEvent struct {
	OrderID    string    `json:"order_id"`
	CustomerID string    `json:"customer_id"`
	Amount     float64   `json:"amount"`
	Currency   string    `json:"currency"`
	Timestamp  time.Time `json:"timestamp"`
	// Add more fields as needed for a real-world scenario
}

// ToJSON marshals the event to a JSON byte slice.
func (o *OrderCreatedEvent) ToJSON() ([]byte, error) {
	return json.Marshal(o)
}

// FromJSON unmarshals a JSON byte slice into an OrderCreatedEvent.
func (o *OrderCreatedEvent) FromJSON(data []byte) error {
	return json.Unmarshal(data, o)
}
