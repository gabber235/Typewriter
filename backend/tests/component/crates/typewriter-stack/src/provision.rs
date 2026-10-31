//! Creates the stack's organization as its owner through the real organization route, and records
//! it for `bind` and for xtask, which publishes it as `STACK_ORGANIZATION`.

use std::time::{Duration, Instant};

use anyhow::{Context as _, Result, bail};
use serde::{Deserialize, Serialize};
use typewriter_component_test::StackUser;
use wasmcloud_utils::skir::base::kernel::v1::record_id::{RecordId, RecordIdKey};
use wasmcloud_utils::skir::base::organization::v1::organization::{
    CreateOrganizationRequest, CreateOrganizationResponse,
};
use wasmcloud_utils::transport_routes::UserOrganizationCreateRoute;

use crate::session::{Session, StackEndpoints, record_token};

#[derive(clap::Args)]
pub struct ProvisionArgs {
    #[command(flatten)]
    endpoints: StackEndpoints,
}

/// What `provision` created.
#[derive(Serialize, Deserialize)]
pub struct Provisioned {
    /// The organization's record key, its subject token.
    pub organization: String,
    pub organization_name: String,
    pub owner: String,
}

impl Provisioned {
    pub fn read(endpoints: &StackEndpoints) -> Result<Self> {
        let file = StackEndpoints::provisioned_file(&endpoints.state);
        serde_json::from_str(
            &std::fs::read_to_string(&file)
                .with_context(|| format!("cannot read {}; did `provision` run?", file.display()))?,
        )
        .with_context(|| format!("{} is unreadable", file.display()))
    }

    pub fn organization_record(&self) -> RecordId {
        RecordId {
            table: "organization".into(),
            key: RecordIdKey::String(self.organization.clone()),
            ..Default::default()
        }
    }
}

/// How long the owner's sign in may be refused before provisioning fails.
const SIGN_IN_PATIENCE: Duration = Duration::from_secs(300);

pub async fn run(args: ProvisionArgs) -> Result<()> {
    let endpoints = args.endpoints;
    let owner = endpoints.owner()?;
    let name = owner.organizations[0].clone();
    let session = sign_in_once_known(&endpoints, &owner).await?;
    let subject = format!("cloud.to.user.{}.organization.create", session.user());
    let response = session
        .request::<UserOrganizationCreateRoute>(
            subject,
            &CreateOrganizationRequest {
                name: name.clone(),
                ..Default::default()
            },
        )
        .await
        .context("CreateOrganization")?;
    let CreateOrganizationResponse::Success(success) = response else {
        bail!("CreateOrganization failed: {response:?}");
    };
    let provisioned = Provisioned {
        organization: record_token(&success.organization.organization_id)?
            .as_str()
            .to_owned(),
        organization_name: name,
        owner: owner.username,
    };
    let file = StackEndpoints::provisioned_file(&endpoints.state);
    std::fs::write(&file, serde_json::to_string_pretty(&provisioned)?)
        .with_context(|| format!("cannot write {}", file.display()))?;
    tracing::info!(
        organization = provisioned.organization,
        owner = provisioned.owner,
        "provisioned"
    );
    Ok(())
}

/// Signs the owner in, trying again while the identity provider refuses: a fresh CI cluster's
/// Authentik applies the blueprint that creates the test users a while after their passwords
/// exist. The last refusal is the error once [`SIGN_IN_PATIENCE`] has passed.
async fn sign_in_once_known(endpoints: &StackEndpoints, owner: &StackUser) -> Result<Session> {
    let deadline = Instant::now() + SIGN_IN_PATIENCE;
    loop {
        match Session::sign_in(endpoints, owner, None).await {
            Ok(session) => return Ok(session),
            Err(error) if Instant::now() < deadline => {
                tracing::info!(
                    owner = owner.username,
                    "sign in refused, trying again: {error:#}"
                );
                tokio::time::sleep(Duration::from_secs(5)).await;
            }
            Err(error) => return Err(error),
        }
    }
}
