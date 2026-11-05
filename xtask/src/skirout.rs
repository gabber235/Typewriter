//! Generated Rust types of the `harness/v1` Skir contracts, the results every runner writes.
//! build.rs generates them into `OUT_DIR` on every build whose contracts changed.
#[allow(dead_code, clippy::all)]
pub mod base {
    include!(concat!(env!("OUT_DIR"), "/skir/modules.rs"));
}
