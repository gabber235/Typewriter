// pub(crate) mod bindings {
//     use crate::SurrealDBTestComponent;
//     wit_bindgen::generate!({ generate_all });
//     export!(SurrealDBTestComponent);
// }

use anyhow::Result;
// use bindings::wasi::logging::logging::*;
// use bindings::exports::{
//     seamlezz::surrealdb_test::test::Guest,
//     wasi::http::incoming_handler::{IncomingRequest, ResponseOutparam},
// };
use surrealdb_component::query;
use tracing::instrument;
use wasmcloud_component::{
    export,
    http::{self, ErrorCode},
};

#[derive(Clone, Debug)]
struct SurrealDBTestComponent;

#[derive(Clone, Debug, serde::Serialize, serde::Deserialize)]
pub struct SurrealDBTestComponentData {
    pub text: String,
    pub number: i32,
}

// impl Guest for SurrealDBTestComponent {
//     fn call() -> String {
//         let result = query("UPSERT test:test SET text = $txt, number = $number")
//             .bind("txt", "Hello from SurrealDB testing component!")
//             .bind("number", 42)
//             .execute();
//
//         let result = match result {
//             Ok(v) => v,
//             Err(e) => return format!("Error: {:?}", e),
//         };
//
//         let mut print = String::new();
//         let data: Result<Option<SurrealDBTestComponentData>> = result.take(0);
//         match data {
//             Ok(Some(v)) => {
//                 print.push_str(&format!("Result: {:?}\n", v));
//             }
//             Ok(None) => {
//                 print.push_str("No result\n");
//             }
//             Err(e) => {
//                 print.push_str(&format!("Error: {:?}\n", e));
//             }
//         }
//         return print;
//     }
// }

export!(SurrealDBTestComponent);

impl http::Server for SurrealDBTestComponent {
    #[instrument(skip(_request), fields(component = "SurrealDBTestComponent"))]
    fn handle(
        _request: http::IncomingRequest,
    ) -> http::Result<http::Response<impl http::OutgoingBody>> {
        tracing::info!("Handling request in SurrealDBTestComponent");

        tracing::debug!("Executing SurrealDB query");
        let result = {
            let _span = tracing::info_span!("db_query", operation = "upsert", table = "test:test")
                .entered();
            query("UPSERT test:test SET text = $txt, number = $number")
                .bind("txt", "Hello from SurrealDB testing component!")
                .bind("number", 42)
                .execute()
                .map_err(|e| {
                    tracing::error!(error = ?e, "SurrealDB query execution failed");
                    ErrorCode::InternalError(Some(format!("{:?}", e)))
                })?
        };
        tracing::debug!("SurrealDB query executed successfully");

        let mut print = String::new();

        tracing::debug!("Processing query result");
        let data: Result<Option<SurrealDBTestComponentData>> = {
            let _span = tracing::info_span!("process_result", result_idx = 0).entered();
            result.take(0)
        };

        match &data {
            Ok(Some(v)) => {
                tracing::info!(data = ?v, "Successfully retrieved data");
                print.push_str(&format!("Result: {:?}\n", v));
            }
            Ok(None) => {
                tracing::info!("Query succeeded but returned no data");
                print.push_str("No result\n");
            }
            Err(e) => {
                tracing::error!(error = ?e, "Error processing query result");
                print.push_str(&format!("Error: {:?}\n", e));
            }
        }

        tracing::info!("Building HTTP response");
        Ok(http::Response::builder()
            .status(200)
            .header("Content-Type", "text/plain")
            .body(print)
            .map_err(|e| {
                tracing::error!(error = ?e, "Failed to build HTTP response");
                ErrorCode::InternalError(Some(format!("{:?}", e)))
            })?)
    }
}
