# 92 — Project: Real-Time Chat App (WebSockets + Leptos)

> **Type:** Tutorial

## Architecture

```
Browser (Leptos CSR)           Server (Axum)
┌─────────────────────┐        ┌────────────────────┐
│                     │  WS    │                    │
│  ChatRoom component │◄──────►│  WS Handler        │
│  Message list       │        │  Broadcast channel │
│  Input form         │        │  SQLite message log│
│                     │        │                    │
└─────────────────────┘        └────────────────────┘
```

## Server: WebSocket broadcast handler

```rust
// src/server/ws.rs
use axum::extract::ws::{Message, WebSocket, WebSocketUpgrade};
use tokio::sync::broadcast;

pub struct AppState {
    pub tx: broadcast::Sender<String>,
    pub pool: SqlitePool,
}

pub async fn ws_handler(
    ws: WebSocketUpgrade,
    axum::extract::State(state): axum::extract::State<Arc<AppState>>,
) -> impl IntoResponse {
    ws.on_upgrade(|socket| handle_socket(socket, state))
}

async fn handle_socket(mut socket: WebSocket, state: Arc<AppState>) {
    let mut rx = state.tx.subscribe();

    loop {
        tokio::select! {
            // Receive from client
            Some(Ok(msg)) = socket.recv() => {
                if let Message::Text(text) = msg {
                    let chat_msg = format!("user: {}", text);
                    // Broadcast to all clients
                    let _ = state.tx.send(chat_msg.clone());
                    // Persist to DB
                    sqlx::query("INSERT INTO messages (content) VALUES (?)")
                        .bind(&chat_msg)
                        .execute(&state.pool)
                        .await.ok();
                }
            }
            // Broadcast to this client
            Ok(msg) = rx.recv() => {
                if socket.send(Message::Text(msg)).await.is_err() {
                    break;
                }
            }
            else => break,
        }
    }
}
```

## Leptos: Chat component

```rust
use gloo_net::websocket::{futures::WebSocket, Message};
use futures::{SinkExt, StreamExt};
use leptos::*;

#[component]
pub fn ChatRoom() -> impl IntoView {
    let (messages, set_messages) = create_signal(Vec::<String>::new());
    let (input, set_input) = create_signal(String::new());
    let (ws_write, set_ws_write) = create_signal(None::<futures::channel::mpsc::UnboundedSender<String>>);

    // Connect to WebSocket on mount
    create_effect(move |_| {
        let set_messages = set_messages.clone();
        spawn_local(async move {
            let ws = WebSocket::open("ws://localhost:3000/ws").unwrap();
            let (mut write, mut read) = ws.split();

            // Channel for sending from component
            let (tx, mut rx) = futures::channel::mpsc::unbounded::<String>();
            set_ws_write(Some(tx));

            // Spawn send task
            spawn_local(async move {
                while let Some(msg) = rx.next().await {
                    write.send(Message::Text(msg)).await.ok();
                }
            });

            // Receive messages
            while let Some(Ok(msg)) = read.next().await {
                if let Message::Text(text) = msg {
                    set_messages.update(|v| v.push(text));
                }
            }
        });
    });

    let on_send = move |_| {
        let msg = input.get();
        if msg.is_empty() { return; }
        if let Some(tx) = ws_write.get() {
            tx.unbounded_send(msg).ok();
            set_input(String::new());
        }
    };

    view! {
        <div class="chat-room">
            <div class="messages">
                <For
                    each=move || messages.get().into_iter().enumerate().collect::<Vec<_>>()
                    key=|(i, _)| *i
                    children=|(_, msg)| view! {
                        <div class="message">{msg}</div>
                    }
                />
            </div>
            <div class="input-area">
                <input
                    type="text"
                    value=input
                    on:input=move |ev| set_input(event_target_value(&ev))
                    on:keydown=move |ev| {
                        if ev.key() == "Enter" { on_send(ev.into()); }
                    }
                    placeholder="Type a message..."
                />
                <button on:click=on_send>"Send"</button>
            </div>
        </div>
    }
}
```

## Message structure (with JSON)

```rust
use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Clone)]
pub struct ChatMessage {
    pub id: String,
    pub username: String,
    pub content: String,
    pub timestamp: u64,
}

// Serialize for transmission
let msg_json = serde_json::to_string(&chat_msg).unwrap();
let _ = state.tx.send(msg_json);
```

## Database schema

```sql
CREATE TABLE IF NOT EXISTS messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id TEXT NOT NULL DEFAULT 'general',
    username TEXT NOT NULL,
    content TEXT NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

## Features to extend

1. **User authentication** — show username next to messages.
2. **Multiple rooms** — URL-based room selection (`/chat/general`, `/chat/dev`).
3. **Online user list** — track connected clients.
4. **Message history** — load last 50 messages on connect.
5. **Typing indicators** — broadcast `"user is typing..."` events.
6. **Read receipts** — track which users have seen each message.
7. **Rate limiting** — `tower-governor` on the WS upgrade endpoint.
8. **End-to-end encryption** — encrypt messages client-side before sending.
