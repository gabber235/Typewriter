//! Typewriter-specific database and Skir extensions for component tests.

#![forbid(unsafe_code)]

mod database;
mod record;
mod skir;

pub use database::{DatabaseHandle, SchemaPreset, TypewriterDatabase, TypewriterFixtureBuilderExt};
pub use record::{database_record_key, skir_record_id};
pub use skir::{SkirHttpExt, SkirHttpResponse, SkirMessagingExpectationExt, SkirMessagingExt};

pub mod prelude {
    pub use crate::{
        DatabaseHandle, SchemaPreset, SkirHttpExt, SkirMessagingExpectationExt, SkirMessagingExt,
        TypewriterFixtureBuilderExt, database_record_key, skir_record_id,
    };
    pub use component_test::*;
}
