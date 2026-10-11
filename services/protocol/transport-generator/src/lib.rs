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
