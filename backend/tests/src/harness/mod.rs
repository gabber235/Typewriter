//! Test harness infrastructure for running integration tests.
//!
//! This module provides the core infrastructure for integration testing:
//! - Container management (NATS, SurrealDB)
//! - Component discovery and building
//! - wash-runtime host management
//! - NATS client for test messaging

mod containers;
mod components;
mod host;
mod nats_client;

pub use containers::TestInfra;
pub use components::ComponentRegistry;
pub use host::{DeploymentResult, TestHost};
pub use nats_client::TestNatsClient;
