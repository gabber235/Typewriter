use std::path::PathBuf;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let proto_root = PathBuf::from("../../proto");

    let proto_files: Vec<_> = glob::glob(&format!("{}/**/*.proto", proto_root.display()))?
        .filter_map(Result::ok)
        .collect();

    if proto_files.is_empty() {
        println!(
            "cargo:warning=No .proto files found in {}",
            proto_root.display()
        );
        return Ok(());
    }

    println!("cargo:rerun-if-changed={}", proto_root.display());
    for proto in &proto_files {
        println!("cargo:rerun-if-changed={}", proto.display());
    }

    let out_dir = PathBuf::from("src/proto");
    std::fs::create_dir_all(&out_dir)?;

    prost_build::Config::new()
        .out_dir(&out_dir)
        .compile_protos(&proto_files, &[&proto_root])?;

    println!(
        "Generated {} proto files to {:?}",
        proto_files.len(),
        out_dir
    );

    Ok(())
}
