//! Data builders for seeding test data in SurrealDB.
//!
//! These builders provide a convenient API for creating test fixtures
//! directly in the database without going through the NATS API.

mod user;
mod organization;
mod role;
mod member;

pub use user::UserBuilder;
pub use organization::OrganizationBuilder;
pub use role::RoleBuilder;
pub use member::MemberBuilder;
