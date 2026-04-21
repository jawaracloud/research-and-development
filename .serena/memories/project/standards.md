# Standards & Conventions

- **Core DNA**: Fearless experimentation. R&D and trial & error without fear of making mistakes. We learn and succeed through failure.
- **Docs**: Diátaxis framework. Every project requires a `README.md` with a case study/ROI. Lessons need focused READMEs.
- **Go**: Use `gofmt`/`goimports`, explicit error handling (`fmt.Errorf`), standard layout (`cmd/`, `internal/`, `pkg/`).
- **Rust**: Use `cargo fmt` and `cargo clippy`.
- **Bash**: Use `set -eo pipefail`. Rely on native tools (jq, curl, awk, sed).
- **Automation**: Provide Docker Compose or K8s manifests for reproducibility.