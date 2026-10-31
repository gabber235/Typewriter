mod support;

use support::component_manifests;

#[test]
fn application_components_use_the_database_boundary() {
    let manifests = component_manifests(&["access", "organization", "service"]);
    assert!(
        !manifests.is_empty(),
        "the application areas hold components"
    );

    for path in manifests {
        let manifest = std::fs::read_to_string(&path)
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
}
