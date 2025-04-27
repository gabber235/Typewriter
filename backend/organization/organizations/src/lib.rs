use serde::Deserialize;
use surrealdb_component::query;
use wasmcloud_component::http;

struct Component;

http::export!(Component);

#[derive(Debug, Deserialize)]
struct User {
    name: String,
}

impl http::Server for Component {
    fn handle(
        _request: http::IncomingRequest,
    ) -> http::Result<http::Response<impl http::OutgoingBody>> {
        let result = query("UPSERT users:test SET name = 'test';")
            .execute()
            .map_err(|e| http::ErrorCode::InternalError(Some(e.to_string())))?;

        for i in 0..result.len() {
            let data: Option<User> = result
                .take(i)
                .map_err(|e| http::ErrorCode::InternalError(Some(e.to_string())))?;
            println!("{:?}", data);
        }

        Ok(http::Response::new("Hello from Rust!\n"))
    }
}
