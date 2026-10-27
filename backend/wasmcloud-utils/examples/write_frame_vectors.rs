//! Writes the shared frame vectors to the path given as the only argument.
//!
//! `cargo xtask generate` runs this to produce `skir-src/transport/v1/fixtures/frames.json`.

use std::path::PathBuf;

fn main() -> std::io::Result<()> {
    let path: PathBuf = std::env::args_os()
        .nth(1)
        .expect("usage: write_frame_vectors <frames.json>")
        .into();
    if let Some(parent) = path.parent() {
        std::fs::create_dir_all(parent)?;
    }
    let mut json = serde_json::to_string_pretty(&wasmcloud_utils::transport::frame_vectors())
        .map_err(std::io::Error::other)?;
    json.push('\n');
    std::fs::write(path, json)
}
