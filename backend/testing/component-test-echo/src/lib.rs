//! Minimal HTTP component used by the component test suite.
//!
//! It exercises the host's HTTP response path by returning status 200, a body of `ok`, and
//! completed trailers without depending on application state or an external service.

mod bindings {
    use crate::Component;

    wit_bindgen::generate!({
        world: "component",
        path: "wit",
        generate_all,
    });
    export!(Component);
}

use bindings::exports::wasi::http::handler::Guest;
use bindings::wasi::http::types::{ErrorCode, Fields, Request, Response};
use wit_bindgen::spawn_local;

struct Component;

impl Guest for Component {
    /// Returns the deterministic smoke test response expected by the HTTP fixture.
    async fn handle(_request: Request) -> Result<Response, ErrorCode> {
        let headers = Fields::new();
        let (mut tx, rx) = bindings::wit_stream::new();
        // The WIT future is completed by the spawned task after the body stream closes.
        let (trailers_tx, trailers_rx) = bindings::wit_future::new(|| todo!());
        spawn_local(async move {
            tx.write_all(b"ok".to_vec()).await;
            drop(tx);
            #[expect(
                clippy::let_underscore_must_use,
                reason = "the client may already be gone; nothing awaits the trailers"
            )]
            let _ = trailers_tx.write(Ok(None)).await;
        });
        let (response, _) = Response::new(headers, Some(rx), trailers_rx);
        response.set_status_code(200).map_err(|()| {
            ErrorCode::InternalError(Some("failed to set response status".to_string()))
        })?;
        Ok(response)
    }
}
