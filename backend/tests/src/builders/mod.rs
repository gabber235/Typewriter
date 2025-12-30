//! Data builders for seeding test data in SurrealDB.
//!
//! These builders provide a convenient API for creating test fixtures
//! directly in the database without going through the NATS API.

mod join_request;
mod member;
mod organization;
mod role;
mod user;

pub use join_request::{JoinRequest, JoinRequestBuilder};
pub use member::MemberBuilder;
pub use organization::{Organization, OrganizationBuilder};
pub use role::{Role, RoleBuilder};
pub use user::{User, UserBuilder};
