//! Generates the Rust types of the `harness/v1` Skir contracts into `OUT_DIR`, so the harness
//! compiles from a fresh checkout without `cargo xtask generate` and without the whole Skir tree.
//!
//! Skir always reads `<root>/skir-src` and writes paths relative to `<root>`, so the harness
//! contracts are copied into a Skir root of their own under `OUT_DIR`. The sources are only read:
//! `cargo xtask generate` numbers them, and the copied files are already numbered.

use std::env;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};
use std::process::Command;

/// The generator, its version and its patch.
const GENERATOR_INPUTS: &[&str] = &[
    "package.json",
    "bun.lock",
    "services/protocol/skir-gen/dependency-patches",
];

fn main() {
    let repository = PathBuf::from(env::var_os("CARGO_MANIFEST_DIR").unwrap()).join("..");
    let contracts = repository.join("skir-src/harness");
    for input in GENERATOR_INPUTS {
        println!(
            "cargo:rerun-if-changed={}",
            repository.join(input).display()
        );
    }
    println!("cargo:rerun-if-changed={}", contracts.display());

    let root = PathBuf::from(env::var_os("OUT_DIR").unwrap()).join("skir");
    if root.exists() {
        fs::remove_dir_all(&root).unwrap();
    }
    copy_dir(&contracts, &root.join("skir-src/harness")).unwrap();
    fs::write(
        root.join("skir.yml"),
        "generators:\n  - mod: skir-rust-gen\n    outDir: ./skirout\n    config: {}\n",
    )
    .unwrap();

    // The generator is a pinned, patched npm package; scripts stay off as in `cargo xtask generate`.
    bun(
        &repository,
        &["install", "--frozen-lockfile", "--ignore-scripts"],
    );
    let root_arg = root.to_str().expect("OUT_DIR is UTF-8");
    bun(
        &repository,
        &[
            "x",
            "--bun",
            "--no-install",
            "skir",
            "gen",
            "--root",
            root_arg,
        ],
    );

    // Skir writes a module file per directory with `mod` items Cargo cannot resolve from OUT_DIR,
    // so the tree is declared as inline modules with each contract file included by path.
    let mut modules = String::new();
    declare(&root.join("skirout/base"), &mut modules).unwrap();
    fs::write(root.join("modules.rs"), modules).unwrap();
}

/// Runs bun from `BUN`, which the git hooks set since they run outside the shell, or from PATH.
fn bun(repository: &Path, args: &[&str]) {
    let bun = env::var_os("BUN").unwrap_or_else(|| "bun".into());
    let status = Command::new(bun)
        .args(args)
        .current_dir(repository)
        .status()
        .unwrap_or_else(|error| panic!("cannot run bun (enter `devenv shell`): {error}"));
    assert!(
        status.success(),
        "bun {} failed with {status}",
        args.join(" ")
    );
}

fn copy_dir(from: &Path, to: &Path) -> io::Result<()> {
    fs::create_dir_all(to)?;
    for entry in fs::read_dir(from)? {
        let entry = entry?;
        if entry.file_type()?.is_dir() {
            copy_dir(&entry.path(), &to.join(entry.file_name()))?;
        } else {
            fs::copy(entry.path(), to.join(entry.file_name()))?;
        }
    }
    Ok(())
}

/// Declares the modules under `dir`: a directory becomes an inline module, and a file without a
/// directory of the same name is a contract, included by its absolute path.
fn declare(dir: &Path, out: &mut String) -> io::Result<()> {
    let mut entries = fs::read_dir(dir)?
        .map(|entry| entry.map(|entry| entry.path()))
        .collect::<io::Result<Vec<_>>>()?;
    entries.sort();
    for path in entries {
        let name = path.file_stem().unwrap().to_str().unwrap();
        if path.is_dir() {
            out.push_str(&format!("pub mod {name} {{\n"));
            declare(&path, out)?;
            out.push_str("}\n");
        } else if !path.with_extension("").is_dir() {
            out.push_str(&format!(
                "#[path = {:?}]\npub mod {name};\n",
                path.display().to_string()
            ));
        }
    }
    Ok(())
}
