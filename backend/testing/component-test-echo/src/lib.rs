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
    async fn handle(_request: Request) -> Result<Response, ErrorCode> {
        let headers = Fields::new();
        let (mut tx, rx) = bindings::wit_stream::new();
        let (trailers_tx, trailers_rx) = bindings::wit_future::new(|| todo!());
        spawn_local(async move {
            tx.write_all(b"ok".to_vec()).await;
            drop(tx);
            let _ = trailers_tx.write(Ok(None)).await;
        });
        let (response, _) = Response::new(headers, Some(rx), trailers_rx);
        response.set_status_code(200).map_err(|()| {
            ErrorCode::InternalError(Some("failed to set response status".to_string()))
        })?;
        Ok(response)
    }
}
