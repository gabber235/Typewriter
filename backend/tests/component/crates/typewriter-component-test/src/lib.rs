//! Typewriter-specific database and Skir extensions for component tests.

#![forbid(unsafe_code)]

mod database;
mod skir;

pub use database::{DatabaseHandle, SchemaPreset, TypewriterDatabase, TypewriterFixtureBuilderExt};
pub use skir::{SkirHttpExt, SkirHttpResponse, SkirMessagingExpectationExt, SkirMessagingExt};

pub mod prelude {
    pub use crate::{
        DatabaseHandle, SchemaPreset, SkirHttpExt, SkirMessagingExpectationExt, SkirMessagingExt,
        TypewriterFixtureBuilderExt,
    };
    pub use component_test::*;
}
