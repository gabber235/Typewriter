//! Compiles the transport manifest against canonical Skir symbols and language binding metadata.
//! The manifest owns logical subjects, scopes, grants, and delivery policy. Skir exporters own target
//! names and serializers, so emitters consume resolved bindings rather than reconstructing names.
//! Generated clients and backend dispatch share this input, but connection and handler lifetimes
//! remain with their consuming runtimes.

pub mod dart;
pub mod grants;
pub mod kotlin;
pub mod manifest;
pub mod resolve;
pub mod resolved;
pub mod rust;
pub mod rust_dispatch;
pub mod subject;
pub mod symbols;

#[derive(serde::Serialize)]
pub struct OutputFile {
    pub path: String,
    pub code: String,
}
