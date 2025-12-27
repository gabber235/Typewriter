use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let proto_root = PathBuf::from("../../proto");

    // Find all .proto files
    let proto_files: Vec<_> = glob::glob(&format!("{}/**/*.proto", proto_root.display()))?
        .filter_map(Result::ok)
        .collect();

    if proto_files.is_empty() {
        println!("cargo:warning=No .proto files found in {}", proto_root.display());
        return Ok(());
    }

    // Set up rerun-if-changed for all proto files
    println!("cargo:rerun-if-changed={}", proto_root.display());
    for proto in &proto_files {
        println!("cargo:rerun-if-changed={}", proto.display());
    }

    // Create output directory
    let out_dir = PathBuf::from("src/proto");
    std::fs::create_dir_all(&out_dir)?;

    // Compile proto files
    prost_build::Config::new()
        .out_dir(&out_dir)
        .compile_protos(&proto_files, &[&proto_root])?;

    println!("cargo:warning=Generated {} proto files to {:?}", proto_files.len(), out_dir);

    Ok(())
}
