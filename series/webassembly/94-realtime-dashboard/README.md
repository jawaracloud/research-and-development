# 94 — Project: Real-Time Dashboard with Live Data

> **Type:** Tutorial

## What you will build

A metrics dashboard that displays live system data (CPU, memory, requests/sec) using WebSockets, animated charts via Canvas, and a responsive card-based layout in Leptos.

## Architecture

```
Server (Axum)                    Browser (Leptos Wasm)
┌────────────────────┐           ┌──────────────────────────┐
│ Metrics collector  │   WS      │ Dashboard layout          │
│ (every 1s)         │──────────►│ ┌─────┐ ┌─────┐ ┌─────┐│
│                    │           │ │ CPU │ │ RAM │ │ Net ││
│ History buffer     │           │ └─────┘ └─────┘ └─────┘│
│ (last 60 samples)  │           │ ┌───────────────────────┐│
│                    │           │ │  Live line chart       ││
└────────────────────┘           │ └───────────────────────┘│
                                 └──────────────────────────┘
```

## Server: metrics collection

```rust
use serde::{Deserialize, Serialize};
use std::collections::VecDeque;
use tokio::time::{interval, Duration};

#[derive(Serialize, Deserialize, Clone)]
pub struct MetricsSnapshot {
    pub timestamp: u64,
    pub cpu_percent: f32,
    pub memory_mb: u32,
    pub requests_per_sec: u32,
}

pub async fn collect_metrics(tx: broadcast::Sender<String>) {
    let mut ticker = interval(Duration::from_secs(1));
    let mut history: VecDeque<MetricsSnapshot> = VecDeque::with_capacity(60);

    loop {
        ticker.tick().await;

        // In a real app: read from /proc/stat, sysinfo crate, etc.
        let snapshot = MetricsSnapshot {
            timestamp: std::time::SystemTime::now()
                .duration_since(std::time::UNIX_EPOCH)
                .unwrap().as_secs(),
            cpu_percent: rand_f32() * 100.0,
            memory_mb: 512 + (rand_f32() * 512.0) as u32,
            requests_per_sec: (rand_f32() * 1000.0) as u32,
        };

        history.push_back(snapshot.clone());
        if history.len() > 60 { history.pop_front(); }

        let json = serde_json::to_string(&snapshot).unwrap();
        tx.send(json).ok();
    }
}
```

## Leptos: live gauge component

```rust
#[component]
fn GaugeCard(
    label: String,
    value: ReadSignal<f32>,
    max: f32,
    unit: String,
    color: String,
) -> impl IntoView {
    let percent = create_memo(move |_| (value.get() / max * 100.0).min(100.0));

    view! {
        <div class="gauge-card">
            <div class="gauge-label">{label}</div>
            <div class="gauge-value">
                {move || format!("{:.1}{}", value.get(), unit.clone())}
            </div>
            <div class="gauge-bar">
                <div
                    class="gauge-fill"
                    style:width=move || format!("{}%", percent.get())
                    style:background=color.clone()
                />
            </div>
        </div>
    }
}
```

## Canvas line chart

```rust
#[component]
fn LineChart(history: ReadSignal<Vec<f32>>, max: f32, color: String) -> impl IntoView {
    let canvas_ref: NodeRef<leptos::html::Canvas> = create_node_ref();

    create_effect(move |_| {
        let data = history.get();
        if let Some(canvas) = canvas_ref.get() {
            let ctx = canvas.get_context("2d").unwrap().unwrap()
                .dyn_into::<web_sys::CanvasRenderingContext2d>().unwrap();

            let w = canvas.width() as f64;
            let h = canvas.height() as f64;

            ctx.clear_rect(0.0, 0.0, w, h);

            if data.len() < 2 { return; }

            let step = w / (data.len() - 1) as f64;

            ctx.begin_path();
            for (i, &val) in data.iter().enumerate() {
                let x = i as f64 * step;
                let y = h - (val / max) as f64 * h;
                if i == 0 { ctx.move_to(x, y); } else { ctx.line_to(x, y); }
            }
            ctx.set_stroke_style(&color.clone().into());
            ctx.set_line_width(2.0);
            ctx.stroke();
        }
    });

    view! {
        <canvas
            node_ref=canvas_ref
            width="400"
            height="120"
            class="line-chart"
        />
    }
}
```

## Main dashboard layout

```rust
#[component]
fn Dashboard() -> impl IntoView {
    let (cpu, set_cpu) = create_signal(0.0f32);
    let (memory, set_memory) = create_signal(0u32);
    let (rps, set_rps) = create_signal(0u32);
    let (cpu_history, set_cpu_history) = create_signal(Vec::<f32>::new());

    // WebSocket connection
    create_effect(move |_| {
        spawn_local(async move {
            use gloo_net::websocket::{futures::WebSocket, Message};
            let ws = WebSocket::open("ws://localhost:3000/metrics").unwrap();
            let mut read = ws.split().1;

            while let Some(Ok(Message::Text(json))) = futures::StreamExt::next(&mut read).await {
                if let Ok(snap) = serde_json::from_str::<MetricsSnapshot>(&json) {
                    set_cpu(snap.cpu_percent);
                    set_memory(snap.memory_mb);
                    set_rps(snap.requests_per_sec);
                    set_cpu_history.update(|v| {
                        v.push(snap.cpu_percent);
                        if v.len() > 60 { v.remove(0); }
                    });
                }
            }
        });
    });

    view! {
        <div class="dashboard">
            <h1>"System Dashboard"</h1>
            <div class="gauge-row">
                <GaugeCard label="CPU" value=cpu max=100.0 unit="%" color="#cba6f7".into() />
                <GaugeCard label="Memory" value=Signal::derive(move || memory.get() as f32)
                    max=2048.0 unit=" MB" color="#89b4fa".into() />
                <GaugeCard label="RPS" value=Signal::derive(move || rps.get() as f32)
                    max=1000.0 unit="req/s" color="#a6e3a1".into() />
            </div>
            <div class="chart-section">
                <h2>"CPU History (60s)"</h2>
                <LineChart history=cpu_history max=100.0 color="#cba6f7".into() />
            </div>
        </div>
    }
}
```
