#[path = "src/schema_manifest.rs"]
mod schema_manifest;

use std::{env, fs, path::PathBuf};

fn main() {
    if let Err(error) = generate() {
        panic!("generating embedded database schema: {error}");
    }
}

fn generate() -> Result<(), String> {
    let crate_root = PathBuf::from(env::var_os("CARGO_MANIFEST_DIR").ok_or_else(|| {
        "CARGO_MANIFEST_DIR is unavailable while generating database schema".to_owned()
    })?);
    let database_root = crate_root.join("../../../../database");
    let manifest_path = database_root.join("capabilities.toml");
    let contents = fs::read_to_string(&manifest_path)
        .map_err(|error| format!("reading {}: {error}", manifest_path.display()))?;
    let manifest = schema_manifest::Manifest::parse(&contents, |file| {
        database_root.join("schema").join(file).is_file()
    })?;
    let embedded_files = manifest.preset_files("full")?;
    if manifest.declared_files().len() != embedded_files.len() {
        return Err("declared and tested schema file sets differ".into());
    }

    println!("cargo:rerun-if-changed={}", manifest_path.display());
    let mut generated = String::from("const EMBEDDED_SCHEMA_FILES: &[SchemaFile] = &[\n");
    for file in embedded_files {
        let path = database_root.join("schema").join(file);
        println!("cargo:rerun-if-changed={}", path.display());
        generated.push_str(&format!(
            "    SchemaFile {{ name: {file:?}, sql: include_str!({path:?}) }},\n",
            path = path.to_string_lossy()
        ));
    }
    generated.push_str("];\n");

    let output = PathBuf::from(
        env::var_os("OUT_DIR")
            .ok_or_else(|| "OUT_DIR is unavailable while generating database schema".to_owned())?,
    )
    .join("schema_files.rs");
    fs::write(&output, generated)
        .map_err(|error| format!("writing {}: {error}", output.display()))?;
    Ok(())
}
