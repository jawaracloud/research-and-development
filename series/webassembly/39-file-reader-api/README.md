# 39 — Reading Files from the User's Filesystem

> **Type:** How-To + Tutorial

## Setup

```toml
[dependencies.web-sys]
version = "0.3"
features = [
  "Window", "Document", "Element",
  "HtmlInputElement", "FileList", "File",
  "FileReader", "ProgressEvent", "Event",
  "Blob", "BlobPropertyBag",
]
```

## Reading a text file

```rust
use wasm_bindgen::prelude::*;
use wasm_bindgen::JsCast;
use web_sys::{Event, FileReader, HtmlInputElement, ProgressEvent};

#[wasm_bindgen]
pub fn setup_file_reader() {
    let doc = web_sys::window().unwrap().document().unwrap();
    let input: HtmlInputElement = doc
        .get_element_by_id("file-input").unwrap()
        .dyn_into().unwrap();

    let handler = Closure::wrap(Box::new(move |event: Event| {
        let input: HtmlInputElement = event.target().unwrap().dyn_into().unwrap();
        let files = input.files().unwrap();

        if let Some(file) = files.item(0) {
            let file_name = file.name();
            let reader = FileReader::new().unwrap();

            // When the file is loaded
            let reader_clone = reader.clone();
            let load_handler = Closure::once(move |_event: ProgressEvent| {
                let result = reader_clone.result().unwrap();
                let text = result.as_string().unwrap();
                web_sys::console::log_1(
                    &format!("File '{}' ({} chars):\n{}", file_name, text.len(), &text[..100.min(text.len())]).into()
                );
            });

            reader.set_onload(Some(load_handler.as_ref().unchecked_ref()));
            reader.read_as_text(&file).unwrap();
            load_handler.forget();
        }
    }) as Box<dyn FnMut(Event)>);

    input.add_event_listener_with_callback("change", handler.as_ref().unchecked_ref())
        .unwrap();
    handler.forget();
}
```

## Reading as ArrayBuffer (binary files)

```rust
use web_sys::FileReader;

let reader = FileReader::new().unwrap();
let reader_clone = reader.clone();

let on_load = Closure::once(move |_: web_sys::ProgressEvent| {
    use js_sys::ArrayBuffer;
    use js_sys::Uint8Array;

    let result = reader_clone.result().unwrap();
    let buffer: ArrayBuffer = result.dyn_into().unwrap();
    let bytes = Uint8Array::new(&buffer);
    let vec: Vec<u8> = bytes.to_vec();
    web_sys::console::log_1(&format!("Binary file: {} bytes", vec.len()).into());
    // Process vec...
});

reader.set_onload(Some(on_load.as_ref().unchecked_ref()));
reader.read_as_array_buffer(&file).unwrap();
on_load.forget();
```

## Drag-and-drop file upload

```rust
use web_sys::{DragEvent, DataTransfer};

let drop_zone = doc.get_element_by_id("drop-zone").unwrap();

// Prevent default to allow drop
let dragover = Closure::wrap(Box::new(move |event: DragEvent| {
    event.prevent_default();
}) as Box<dyn FnMut(DragEvent)>);

drop_zone.add_event_listener_with_callback("dragover", dragover.as_ref().unchecked_ref())
    .unwrap();
dragover.forget();

// Handle drop
let drop = Closure::wrap(Box::new(move |event: DragEvent| {
    event.prevent_default();
    if let Some(transfer) = event.data_transfer() {
        if let Some(files) = transfer.files() {
            if let Some(file) = files.item(0) {
                web_sys::console::log_1(&format!("Dropped: {}", file.name()).into());
                // Read file...
            }
        }
    }
}) as Box<dyn FnMut(DragEvent)>);

drop_zone.add_event_listener_with_callback("drop", drop.as_ref().unchecked_ref())
    .unwrap();
drop.forget();
```

## HTML

```html
<input type="file" id="file-input" accept=".txt,.json,.csv" />
<div id="drop-zone" style="border: 2px dashed #ccc; padding: 40px;">
  Drop files here
</div>
```

## File metadata

```rust
let file: web_sys::File = files.item(0).unwrap();
let name = file.name();
let size = file.size();          // bytes as f64
let type_ = file.type_();        // MIME type e.g. "text/plain"
let last_modified = file.last_modified(); // ms timestamp
```
