//! Generated protobuf types for API requests and responses.
//!
//! This module contains types generated from the proto/ directory.
//! The build.rs script generates .rs files here from .proto files.

pub mod typewriter {
    pub mod models {
        pub mod v1 {
            include!("typewriter.models.v1.rs");
        }
    }

    pub mod api {
        pub mod v1 {
            include!("typewriter.api.v1.rs");
        }
    }
}
