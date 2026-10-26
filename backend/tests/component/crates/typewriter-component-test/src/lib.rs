//! Typewriter's component test kit: the shared people and organization, database seeds, typed
//! Skir messaging and the NATS topology, on top of the generic `component-test` runtime.

#![forbid(unsafe_code)]

mod database;
mod record;
mod seed;
mod skir;
pub mod topology;
mod users;

pub use database::{
    DatabaseHandle, SchemaPreset, SeedQuery, TypewriterDatabase, TypewriterFixtureBuilderExt,
};
pub use record::{database_record_key, skir_record_id};
pub use seed::{JoinCode, Seed};
pub use skir::{
    REQUEST_TIMEOUT, SkirHttpExt, SkirHttpResponse, SkirMessagingExpectationExt, TypewriterContext,
};
pub use topology::TopologyFixtureBuilderExt;
pub use users::{Organization, StackUser, acme, ada, grace};

pub mod prelude {
    pub use crate::topology::{from_member, from_user, to_organization, to_user};
    pub use crate::{
        DatabaseHandle, JoinCode, Organization, REQUEST_TIMEOUT, SchemaPreset, Seed, SkirHttpExt,
        SkirMessagingExpectationExt, StackUser, TopologyFixtureBuilderExt, TypewriterContext,
        TypewriterFixtureBuilderExt, acme, ada, database_record_key, grace, skir_record_id,
    };
    pub use component_test::*;
}
