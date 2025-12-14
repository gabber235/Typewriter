use std::collections::HashMap;

use anyhow::Result;
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

export!(SurrealDBTestComponent);

impl http::Server for SurrealDBTestComponent {
    #[instrument(skip(request), fields(component = "SurrealDBTestComponent"))]
    fn handle(
        request: http::IncomingRequest,
    ) -> http::Result<http::Response<impl http::OutgoingBody>> {
        tracing::info!("Handling request in SurrealDBTestComponent");

        let q = request.uri().query().unwrap_or_default();
        let params = querystring::querify(q)
            .iter()
            .map(|(k, v)| (k.to_string(), v.to_string()))
            .collect::<HashMap<String, String>>();

        let text = params
            .get("text")
            .unwrap_or(&"Hello from SurrealDB testing component!".to_string())
            .to_string();

        let number = params
            .get("number")
            .unwrap_or(&"69".to_string())
            .parse::<i32>()
            .unwrap_or(69);

        tracing::debug!("Executing SurrealDB query");
        let result = {
            let _span = tracing::info_span!("db_query", operation = "upsert", table = "test:test")
                .entered();
            query("UPSERT test:test SET text = $txt, number = $number")
                .bind("txt", text)
                .bind("number", number)
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
        http::Response::builder()
            .status(200)
            .header("Content-Type", "text/plain")
            .body(print)
            .map_err(|e| {
                tracing::error!(error = ?e, "Failed to build HTTP response");
                ErrorCode::InternalError(Some(format!("{:?}", e)))
            })
    }
}
