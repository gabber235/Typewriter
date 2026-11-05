//! Fixtures for unit testing the schema manifest.

/// Whether `file` is one of the schema files the test manifests name.
pub(crate) fn known_file(file: &str) -> bool {
    matches!(file, "kernel.surql" | "application.surql")
}
