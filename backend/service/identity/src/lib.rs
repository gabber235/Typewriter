mod bindings {
    use crate::Component;
    wit_bindgen::generate!({ world: "component", path: "wit", generate_all });
    export!(Component);
}

mod authentik;
mod http;
mod identity;
mod names;
mod repository;

use bindings::exports::wasi::http::handler::Guest;
use bindings::wasi::http::types::{ErrorCode, Request, Response};

struct Component;

impl Guest for Component {
    #[otel_wasi::wasi_instrument(
        service = "service-identity",
        export,
        attributes(
            "http.route" = "/service/identity/issue",
            "http.method" = "POST",
        )
    )]
    async fn handle(request: Request) -> Result<Response, otel_wasi::Error<ErrorCode>> {
        http::handle(request).await
    }
}
