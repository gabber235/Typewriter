mod bindings {
    wit_bindgen::generate!({
        generate_all,
        with: {
            "wasi:http/types@0.2.2": wasmcloud_component::wasi::http::types,
            "wasi:http/outgoing-handler@0.2.2": wasmcloud_component::wasi::http::outgoing_handler,
            "wasi:io/error@0.2.2": wasmcloud_component::wasi::io::error,
            "wasi:io/poll@0.2.2": wasmcloud_component::wasi::io::poll,
            "wasi:io/streams@0.2.2": wasmcloud_component::wasi::io::streams,
            // Generate bindings for our custom interfaces
            "seamlezz:surrealdb/call@0.1.0": generate,
            "wasi:logging/logging@0.1.0-draft": generate,
        }
    });
}

mod authentik;
mod handlers;

mod typewriter {
    pub mod models {
        pub mod v1 {
            include!("generated/typewriter.models.v1.rs");
        }
    }
    pub mod api {
        pub mod v1 {
            include!("generated/typewriter.api.v1.rs");
        }
    }
}

use std::io::Read;
use wasmcloud_component::{
    debug, error,
    http::{self, Method},
    info, trace,
};
use wasmcloud_utils::error_response_bytes;

use crate::typewriter::api::v1::IssueServiceIdentityResponse;

struct ServiceIdentity;

type ResponseBody = Vec<u8>;

impl http::Server for ServiceIdentity {
    #[allow(refining_impl_trait)]
    fn handle(request: http::IncomingRequest) -> http::Result<http::Response<ResponseBody>> {
        debug!("Received request on path: {:?}", request.uri().path());

        let path = request
            .uri()
            .path_and_query()
            .map(|p| p.as_str())
            .unwrap_or("/");
        let method = request.method();

        // TODO: Once path based routing is implemented, remove this.
        match (method, path) {
            (&Method::POST, "/service/identity/issue") => handle_issue_identity(request),
            _ => {
                trace!("Not found: {} {}", method, path);
                Ok(http::Response::builder()
                    .status(404)
                    .header("content-type", "application/json")
                    .body(format!(r#"{{"error":"Not found: {} {}"}}"#, method, path).into_bytes())
                    .unwrap())
            }
        }
    }
}

fn handle_issue_identity(
    request: http::IncomingRequest,
) -> http::Result<http::Response<ResponseBody>> {
    trace!("Processing identity issue request");

    let (_parts, mut body) = request.into_parts();
    let mut body_data = Vec::new();
    if let Err(e) = body.read_to_end(&mut body_data) {
        error!("Failed to read request body: {}", e);
        let error_response = error_response_bytes!(
            IssueServiceIdentityResponse,
            issue_service_identity_response,
            400,
            &format!("Failed to read request body: {}", e)
        );
        return Ok(http::Response::builder()
            .status(400)
            .header("content-type", "application/x-protobuf")
            .body(error_response)
            .unwrap());
    }

    match handlers::handle_register(&body_data) {
        Ok(response_bytes) => {
            info!("Successfully issued service identity");
            Ok(http::Response::builder()
                .status(200)
                .header("content-type", "application/x-protobuf")
                .body(response_bytes)
                .unwrap())
        }
        Err(e) => {
            error!("Handler error: {}", e);
            let error_code = match e {
                handlers::HandlerError::InvalidServiceTypes(_) => 400,
                handlers::HandlerError::AuthentikError(_) => 503,
                handlers::HandlerError::DatabaseError(_) => 500,
                handlers::HandlerError::DecodeError(_) => 400,
                handlers::HandlerError::EncodeError(_) => 500,
            };
            let error_response = error_response_bytes!(
                IssueServiceIdentityResponse,
                issue_service_identity_response,
                error_code as u32,
                e.to_string()
            );
            Ok(http::Response::builder()
                .status(error_code)
                .header("content-type", "application/x-protobuf")
                .body(error_response)
                .unwrap())
        }
    }
}

http::export!(ServiceIdentity);
