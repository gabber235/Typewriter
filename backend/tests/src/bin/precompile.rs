//! Pre-compiles WASM components to .cwasm format using the same Engine config as wash-runtime.
//!
//! Usage: cargo run --bin precompile --release [-- <backend_path>]
//!
//! Discovers components by scanning for `.wash` directories, finds their WASM files,
//! and compiles them to .cwasm. Skips files that are already up-to-date.

use std::path::{Path, PathBuf};

use anyhow::{Context, Result};

fn main() -> Result<()> {
    let backend_path = std::env::args()
        .nth(1)
        .map(PathBuf::from)
        .unwrap_or_else(|| std::env::current_dir().expect("no cwd"));

    println!(
        "Pre-compiling WASM components in {}...\n",
        backend_path.display()
    );

    let engine = create_engine()?;
    let wasm_paths = discover_wasm_files(&backend_path)?;

    if wasm_paths.is_empty() {
        println!("No WASM files found. Run 'wash build' first to build the components.");
        return Ok(());
    }

    let mut compiled = 0;
    let mut skipped = 0;

    for wasm_path in wasm_paths {
        let cwasm_path = wasm_path.with_extension("cwasm");

        if is_up_to_date(&wasm_path, &cwasm_path) {
            let name = wasm_path.file_name().unwrap().to_string_lossy();
            println!("⏭️  {} (up-to-date)", name);
            skipped += 1;
            continue;
        }

        compile_component(&engine, &wasm_path, &cwasm_path)?;
        compiled += 1;
    }

    println!("\n✅ Done: {} compiled, {} skipped", compiled, skipped);
    Ok(())
}

fn create_engine() -> Result<wasmtime::Engine> {
    let mut config = wasmtime::Config::new();
    config.async_support(true);
    wasmtime::Engine::new(&config).context("failed to create engine")
}

fn discover_wasm_files(backend_path: &Path) -> Result<Vec<PathBuf>> {
    let pattern = format!("{}/**/.wash", backend_path.display());
    let mut wasm_paths = Vec::new();

    for entry in glob::glob(&pattern).context("Invalid glob pattern")? {
        let wash_dir = entry.context("Failed to read glob entry")?;
        let component_dir = wash_dir
            .parent()
            .context("Failed to get parent of .wash dir")?;

        if let Some(wasm_path) = find_wasm_path(component_dir) {
            wasm_paths.push(wasm_path);
        }
    }

    Ok(wasm_paths)
}

fn find_wasm_path(component_dir: &Path) -> Option<PathBuf> {
    let cargo_toml_path = component_dir.join("Cargo.toml");
    let cargo_toml = std::fs::read_to_string(&cargo_toml_path).ok()?;

    let crate_name = cargo_toml
        .lines()
        .find(|line| line.starts_with("name"))?
        .split('=')
        .nth(1)?
        .trim()
        .trim_matches('"')
        .to_string();

    let binary_name = crate_name.replace('-', "_");
    let target_dir = find_target_dir(component_dir)?;
    let wasm_path = target_dir
        .join("wasm32-wasip2/release")
        .join(format!("{}.wasm", binary_name));

    if wasm_path.exists() {
        Some(wasm_path)
    } else {
        None
    }
}

fn find_target_dir(component_path: &Path) -> Option<PathBuf> {
    let mut current = component_path.to_path_buf();

    while let Some(parent) = current.parent() {
        let cargo_toml = parent.join("Cargo.toml");
        if cargo_toml.exists() {
            if let Ok(content) = std::fs::read_to_string(&cargo_toml) {
                if content.contains("[workspace]") {
                    let workspace_target = parent.join("target");
                    if workspace_target.join("wasm32-wasip2").exists() {
                        return Some(workspace_target);
                    }
                }
            }
        }
        current = parent.to_path_buf();
    }

    Some(component_path.join("target"))
}

fn is_up_to_date(wasm: &Path, cwasm: &Path) -> bool {
    if !cwasm.exists() {
        return false;
    }

    let wasm_mtime = std::fs::metadata(wasm).ok().and_then(|m| m.modified().ok());
    let cwasm_mtime = std::fs::metadata(cwasm)
        .ok()
        .and_then(|m| m.modified().ok());

    matches!((wasm_mtime, cwasm_mtime), (Some(w), Some(c)) if c >= w)
}

fn compile_component(engine: &wasmtime::Engine, wasm: &Path, cwasm: &Path) -> Result<()> {
    let name = wasm.file_name().unwrap().to_string_lossy();
    print!("🔨 Compiling {}...", name);

    let wasm_bytes =
        std::fs::read(wasm).with_context(|| format!("failed to read {}", wasm.display()))?;

    let component = wasmtime::component::Component::new(engine, &wasm_bytes)
        .with_context(|| format!("failed to compile {}", wasm.display()))?;

    let serialized = component
        .serialize()
        .context("failed to serialize component")?;

    std::fs::write(cwasm, &serialized)
        .with_context(|| format!("failed to write {}", cwasm.display()))?;

    println!(" done ({} bytes)", serialized.len());
    Ok(())
}
