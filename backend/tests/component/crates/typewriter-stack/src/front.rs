//! A browser facing front for one of the stack's HTTP services, as the CI cluster's Traefik
//! routes are for its services: it answers CORS, so the web panel may call the service from its
//! own origin, and forwards every other request under its own User-Agent.
//!
//! The stack puts one in front of its public HTTP routes, whose cluster ingress answers CORS too,
//! and one in front of toxiproxy's API, which answers 403 to any request whose User-Agent starts
//! with `Mozilla/` and sends no CORS headers. So the web panel reaches both the way it does on the
//! CI cluster.

use std::net::Ipv4Addr;
use std::sync::Arc;

use anyhow::Result;
use axum::body::Bytes;
use axum::extract::State;
use axum::http::{HeaderMap, HeaderName, Method, StatusCode, Uri, header};
use axum::response::{IntoResponse, Response};
use tokio::net::TcpListener;
use tower_http::cors::CorsLayer;

#[derive(clap::Args)]
pub struct FrontArgs {
    /// Where the front listens.
    #[arg(long)]
    listen: u16,
    /// The service behind it.
    #[arg(long)]
    upstream: u16,
}

/// The User-Agent the service sees; anything but a browser's `Mozilla/`.
const USER_AGENT: &str = "typewriter-stack-front";

/// Headers that describe one connection or one body encoding, which the front's own connections
/// set for themselves.
const HOP_BY_HOP: [HeaderName; 6] = [
    header::CONNECTION,
    header::CONTENT_LENGTH,
    header::HOST,
    header::TRANSFER_ENCODING,
    header::UPGRADE,
    header::USER_AGENT,
];

struct Front {
    upstream: String,
    client: reqwest::Client,
}

pub async fn run(args: FrontArgs) -> Result<()> {
    let front = Arc::new(Front {
        upstream: format!("http://127.0.0.1:{}", args.upstream),
        client: reqwest::Client::builder().user_agent(USER_AGENT).build()?,
    });
    let router = axum::Router::new()
        .fallback(forward)
        .with_state(front)
        .layer(CorsLayer::permissive());
    let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, args.listen)).await?;
    axum::serve(listener, router)
        .with_graceful_shutdown(crate::shutdown_signal())
        .await?;
    Ok(())
}

/// Sends the request on to the service and returns its answer.
async fn forward(
    State(front): State<Arc<Front>>,
    method: Method,
    uri: Uri,
    headers: HeaderMap,
    body: Bytes,
) -> Response {
    let path = uri.path_and_query().map_or("/", |path| path.as_str());
    let answer = front
        .client
        .request(method, format!("{}{path}", front.upstream))
        .headers(end_to_end(headers))
        .body(body)
        .send()
        .await;
    let answer = match answer {
        Ok(answer) => answer,
        Err(error) => return unreachable_upstream(&error),
    };
    let status = answer.status();
    let headers = end_to_end(answer.headers().clone());
    match answer.bytes().await {
        Ok(body) => (status, headers, body).into_response(),
        Err(error) => unreachable_upstream(&error),
    }
}

/// `headers` without the ones that belong to a single connection.
fn end_to_end(mut headers: HeaderMap) -> HeaderMap {
    for name in &HOP_BY_HOP {
        headers.remove(name);
    }
    headers
}

fn unreachable_upstream(error: &reqwest::Error) -> Response {
    (StatusCode::BAD_GATEWAY, format!("the stack front: {error}")).into_response()
}
