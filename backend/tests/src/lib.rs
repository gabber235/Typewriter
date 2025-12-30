//! Integration test framework for TypeWriter backend components.
//!
//! This crate provides a comprehensive test harness for integration testing
//! WASM components with real NATS and SurrealDB infrastructure via testcontainers.

pub mod builders;
pub mod harness;

// Generated protobuf types
#[allow(clippy::all)]
pub mod proto;

mod fixtures;

// Re-export main types for convenience
pub use builders::{
    JoinRequest, JoinRequestBuilder, MemberBuilder, Organization, OrganizationBuilder, Role,
    RoleBuilder, User, UserBuilder,
};
pub use fixtures::get_fixtures;
pub use harness::{ComponentRegistry, DeploymentResult, TestHost, TestInfra, TestNatsClient};
