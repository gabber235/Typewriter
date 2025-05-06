use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize, Deserialize)]
pub struct IssuerConfig {
    pub id: String,
    pub issuer_url: String,
    pub jwks_url: String,
    pub nats_account_key: String,
}
