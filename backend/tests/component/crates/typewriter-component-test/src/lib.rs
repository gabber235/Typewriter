//! Typewriter's component test kit: the shared people and organization, database seeds, typed
//! Skir messaging and the NATS topology, on top of the generic `component-test` runtime.
//!
//! Test files hold only fixtures and cases; everything they share lives here. The prelude holds
//! what every case uses. Each domain module holds the requests, doubles, builders and
//! expectations of one area: [`access`], [`broker`], [`callout`], [`identity`],
//! [`organization`] and [`service`].

#![forbid(unsafe_code)]

pub mod access;
pub mod broker;
pub mod callout;
mod database;
pub mod identity;
pub mod organization;
mod record;
mod seed;
pub mod service;
mod skir;
pub mod topology;
mod users;

pub use database::{
    DatabaseHandle, SchemaPreset, SeedQuery, TypewriterDatabase, TypewriterFixtureBuilderExt,
};
pub use record::{database_record_key, skir_record_id};
pub use seed::{JoinCode, Seed, seed_join_code, seed_join_request, seed_organization};
pub use skir::{
    REQUEST_TIMEOUT, SkirHttpExt, SkirHttpResponse, SkirMessagingExpectationExt, TypewriterContext,
};
pub use topology::TopologyFixtureBuilderExt;
pub use users::{Organization, StackUser, acme, ada, globex, grace};

pub mod prelude {
    pub use crate::topology::{
        from_member, from_service, from_user, realm_event, realm_route, to_organization,
        to_service, to_user,
    };
    pub use crate::{
        DatabaseHandle, JoinCode, Organization, REQUEST_TIMEOUT, SchemaPreset, Seed, SkirHttpExt,
        SkirMessagingExpectationExt, StackUser, TopologyFixtureBuilderExt, TypewriterContext,
        TypewriterFixtureBuilderExt, acme, ada, database_record_key, globex, grace, seed_join_code,
        seed_join_request, seed_organization, skir_record_id,
    };
    pub use component_test::*;
}
