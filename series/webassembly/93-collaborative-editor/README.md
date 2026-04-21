# 93 — Project: Collaborative Markdown Editor

> **Type:** Tutorial

## What you will build

A real-time collaborative Markdown editor: multiple users can edit the same document simultaneously, with live preview and cursor presence indicators.

## Core technical challenges

1. **Conflict-free merging** — two users editing simultaneously must produce sensible results.
2. **Operational Transformation (OT)** or **CRDTs** — data structures that merge concurrent edits.
3. **Presence** — showing other users' cursor positions.

## CRDT approach with diamond-types

```toml
[dependencies]
diamond-types = "0.3"      # CRDT text editing
wasm-bindgen = "0.2"
serde = { version = "1", features = ["derive"] }
serde_json = "1"
```

```rust
use diamond_types::list::ListOpLog;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct Document {
    inner: ListOpLog,
    agent: diamond_types::AgentId,
}

#[wasm_bindgen]
impl Document {
    #[wasm_bindgen(constructor)]
    pub fn new(username: &str) -> Self {
        let mut inner = ListOpLog::new();
        let agent = inner.get_or_create_agent_id(username);
        Document { inner, agent }
    }

    pub fn insert(&mut self, pos: usize, text: &str) {
        self.inner.add_insert_at(self.agent, pos, text.chars().collect());
    }

    pub fn delete(&mut self, pos: usize, len: usize) {
        self.inner.add_delete_without_content(self.agent, pos..pos+len);
    }

    pub fn content(&self) -> String {
        self.inner.checkout_tip().to_string()
    }

    pub fn export_changes(&self) -> Vec<u8> {
        self.inner.encode(Default::default()).to_vec()
    }

    pub fn merge_remote(&mut self, patch: &[u8]) {
        let remote_ops = ListOpLog::decode(patch).unwrap();
        self.inner.merge(&remote_ops);
    }
}
```

## WebSocket protocol for sync

```rust
// Message types
#[derive(Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum SyncMessage {
    Join { user_id: String, username: String },
    Patch { data: Vec<u8>, user_id: String },   // CRDT patch
    Cursor { user_id: String, pos: usize },       // Presence
    UserJoined { username: String },
    UserLeft { username: String },
}
```

Server broadcast handler:
```rust
async fn handle_socket(mut socket: WebSocket, state: Arc<AppState>, doc_id: String) {
    // 1. Send current document state to new user
    let current_data = state.docs.get(&doc_id).map(|d| d.export_changes());
    if let Some(data) = current_data {
        socket.send(Message::Binary(data)).await.ok();
    }

    loop {
        tokio::select! {
            Some(Ok(msg)) = socket.recv() => {
                match msg {
                    Message::Binary(patch) => {
                        // Merge patch into server doc
                        state.docs.entry(doc_id.clone())
                            .or_default()
                            .merge_remote(&patch);
                        // Broadcast to all other clients
                        state.tx.send((doc_id.clone(), patch)).ok();
                    }
                    _ => {}
                }
            }
            Ok((id, patch)) = state.rx.recv() => {
                if id == doc_id {
                    socket.send(Message::Binary(patch)).await.ok();
                }
            }
            else => break,
        }
    }
}
```

## Leptos editor component

```rust
#[component]
fn CollaborativeEditor(doc_id: String) -> impl IntoView {
    let (content, set_content) = create_signal(String::new());
    let (html_preview, set_html_preview) = create_signal(String::new());
    let doc = create_rw_signal(Document::new("user-1"));

    // Update preview on content change
    create_effect(move |_| {
        let md = content.get();
        let html = markdown_to_html(&md); // from lesson 47
        set_html_preview(html);
    });

    let on_input = move |ev: ev::InputEvent| {
        let value = event_target_value(&ev);
        set_content(value.clone());
        // Apply change to CRDT and sync
        // (simplification — real impl needs positional diff)
        doc.update(|d| {
            // compute diff between old and new content, apply operations
        });
    };

    view! {
        <div class="editor-layout">
            <div class="editor-pane">
                <h3>"Markdown"</h3>
                <textarea
                    value=content
                    on:input=on_input
                    class="editor-textarea"
                    spellcheck="false"
                />
            </div>
            <div class="preview-pane">
                <h3>"Preview"</h3>
                <div
                    class="markdown-preview"
                    inner_html=html_preview
                />
            </div>
        </div>
    }
}
```

## Project extensions

1. **Cursor presence** — show each user's name at their cursor position using the `SyncMessage::Cursor` message.
2. **Version history** — log every patch with timestamp; allow rolling back to any point.
3. **Export to PDF** — use `window.print()` on the preview pane.
4. **Offline editing** — queue patches when disconnected, sync on reconnect.
5. **Syntax highlighting** — integrate `highlight.js` in the preview.
6. **Multiple documents** — URL-based document routing (`/doc/:id`).
7. **Permissions** — owner, editor, viewer roles per document.
