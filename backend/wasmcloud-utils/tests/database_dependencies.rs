use std::{fs, path::Path};

#[test]
fn application_components_use_the_database_boundary() {
    let backend = Path::new(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .expect("wasmcloud utils is inside the backend directory");

    for area in ["access", "organization", "service"] {
        inspect_manifests(&backend.join(area));
    }
}

fn inspect_manifests(directory: &Path) {
    for entry in fs::read_dir(directory).expect("application directory must be readable") {
        let path = entry.expect("directory entry must be readable").path();
        if path.is_dir() {
            inspect_manifests(&path);
        } else if path.file_name().is_some_and(|name| name == "Cargo.toml") {
            assert_database_boundary(&path);
        }
    }
}

fn assert_database_boundary(path: &Path) {
    let manifest = fs::read_to_string(path)
        .unwrap_or_else(|error| panic!("failed to read {}: {error}", path.display()));

    assert!(
        manifest.contains("wasmcloud-utils.workspace = true"),
        "{} must depend on wasmcloud-utils",
        path.display(),
    );
    assert!(
        !manifest.contains("surrealdb-component-sdk"),
        "{} must use the wasmcloud-utils database boundary",
        path.display(),
    );
}
