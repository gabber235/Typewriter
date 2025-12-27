//! Integration test framework for TypeWriter backend components.
//!
//! This crate provides a comprehensive test harness for integration testing
//! WASM components with real NATS and SurrealDB infrastructure via testcontainers.

pub mod harness;
pub mod builders;

// Generated protobuf types
#[allow(clippy::all)]
pub mod proto;

mod fixtures;

// Re-export main types for convenience
pub use harness::{TestInfra, TestHost, ComponentRegistry, TestNatsClient};
pub use builders::{UserBuilder, OrganizationBuilder, RoleBuilder, MemberBuilder};
pub use fixtures::get_fixtures;
