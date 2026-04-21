module github.com/jawaracloud/nats-event-driven-demo/producer

go 1.23.0

require (
	github.com/google/uuid v1.6.0
	github.com/jawaracloud/nats-event-driven-demo/shared v0.0.0-00010101000000-000000000000
	github.com/nats-io/nats.go v1.48.0
)

require (
	github.com/klauspost/compress v1.18.0 // indirect
	github.com/nats-io/nkeys v0.4.11 // indirect
	github.com/nats-io/nuid v1.0.1 // indirect
	golang.org/x/crypto v0.37.0 // indirect
	golang.org/x/sys v0.32.0 // indirect
)

replace github.com/jawaracloud/nats-event-driven-demo/shared => ../shared
