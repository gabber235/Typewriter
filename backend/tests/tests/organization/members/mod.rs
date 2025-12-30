//! Tests for organization/members component.
//!
//! This component handles member management within an organization:
//! - Listing members
//! - Updating member roles
//! - Removing members
//! - Managing join requests (list, approve, decline)
//! - Managing join codes (generate, list, revoke)

mod list;
mod update;
mod remove;
mod join_requests;
mod join_codes;
