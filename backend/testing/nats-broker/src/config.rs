//! The server configuration: operator mode with the full account resolver.

use std::path::Path;

use anyhow::Result;
use nats_jwt_rs::{account::Account, operator::Operator};
use nkeys::KeyPair;

use crate::Ports;

/// Renders a configuration that trusts `operator` and preloads `system`, the only account the
/// server knows at start.
///
/// The full resolver accepts account JWTs at runtime (`$SYS.REQ.CLAIMS.UPDATE`) and deletes them
/// on request (`allow_delete`), which is what makes an account per caller cheap. Without a port
/// the server takes any free one; a websocket listener (without TLS) opens only when its port is
/// given. `store` holds the resolver's JWTs and the JetStream store.
pub(crate) fn render(
    operator: &KeyPair,
    system: &KeyPair,
    ports: Ports,
    store: &Path,
) -> Result<String> {
    let mut operator_claims = Operator::new_claims("nats-broker".into(), operator.public_key());
    operator_claims.payload_mut().system_account = Some(system.public_key());
    let operator_jwt = operator_claims.encode(operator)?;
    let system_key = system.public_key();
    let system_jwt = Account::new_claims("SYS".into(), system_key.clone()).encode(operator)?;
    let store = store.display();
    let port = ports.client.map_or(-1, i32::from);
    let websocket = ports.websocket.map_or_else(String::new, |port| {
        format!("websocket: {{ host: 127.0.0.1, port: {port}, no_tls: true }}\n")
    });
    Ok(format!(
        r#"host: 127.0.0.1
port: {port}
{websocket}operator: {operator_jwt}
system_account: {system_key}
resolver: {{ type: full, dir: "{store}/jwt", allow_delete: true }}
resolver_preload: {{ {system_key}: {system_jwt} }}
jetstream: {{ store_dir: "{store}/js", max_memory_store: 2G }}
"#
    ))
}
