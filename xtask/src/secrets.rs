//! `cargo xtask secrets`: the secrets the harness reads. `secretspec.toml` declares them with every
//! other Typewriter secret; the values come from the Typewriter 1Password vault or the root `.env`
//! and stay in this process. Nothing here prints, logs or exports a value: commands that need one
//! get it on stdin, in their environment or from a file only they can read.
//!
//! Each load is one batched vault read, so a command loads a profile once and passes the values
//! on, and only the code paths that use a secret load it.

use std::collections::BTreeMap;
use std::thread;

use anyhow::{Context as _, Result, bail};
use clap::Subcommand;
use secretspec::{ResolutionStatus, Secrets};
use serde::Deserialize;
use serde::de::IgnoredAny;

use crate::Context;

/// The project's secrets file, relative to the repository root.
const SPEC: &str = "secretspec.toml";

// The typed `SecretSpec`, `Profile` and `SecretSpecProfile`, generated from the spec at compile
// time. The macro finds `secretspec.toml` by walking up from the current directory at run time,
// which inside the repository is the root's.
secretspec_derive::declare_secrets!("../secretspec.toml");

/// The macro reads the spec while compiling; including it makes Cargo rebuild when it changes.
const _: &str = include_str!("../../secretspec.toml");

#[derive(Subcommand)]
pub enum SecretsCommand {
    /// Shows which profiles of secretspec.toml are satisfied and what each one misses, never a
    /// value. With a profile, fails unless that profile is satisfied.
    Check { profile: Option<String> },
}

pub fn command(ctx: &Context, command: SecretsCommand) -> Result<()> {
    match command {
        SecretsCommand::Check { profile } => check(ctx, profile.as_deref()),
    }
}

/// The full tier's secrets (`profiles.ci`).
pub struct Ci {
    pub infrastructure_deploy_key: String,
    pub connect_credentials: String,
    pub connect_token: String,
}

impl Ci {
    pub fn load() -> Result<Self> {
        let SecretSpecProfile::Ci {
            infrastructure_deploy_key,
            ci_connect_credentials,
            ci_connect_token,
        } = load(Profile::Ci, "create the CI cluster")?
        else {
            unreachable!("load_profile resolves the profile it is given");
        };
        Ok(Self {
            infrastructure_deploy_key,
            connect_credentials: ci_connect_credentials,
            connect_token: ci_connect_token,
        })
    }
}

/// The local cluster's registry password (`profiles.deploy`).
pub fn local_registry_password() -> Result<String> {
    let SecretSpecProfile::Deploy {
        local_registry_password,
    } = load(Profile::Deploy, "deploy the backend to the local cluster")?
    else {
        unreachable!("load_profile resolves the profile it is given");
    };
    Ok(local_registry_password)
}

/// Resolves every secret of `profile`; `reason` goes to SecretSpec's access log, and agents must
/// give one.
fn load(profile: Profile, reason: &str) -> Result<SecretSpecProfile> {
    let resolved = SecretSpec::builder()
        .with_profile(profile)
        .with_reason(reason)
        .load_profile()
        .with_context(|| {
            format!(
                "cannot resolve the {} secrets; `cargo xtask secrets check {}` says which are \
                 missing",
                profile.as_str(),
                profile.as_str()
            )
        })?;
    Ok(resolved.secrets)
}

/// How one profile would resolve, without its values.
struct Status {
    profile: String,
    missing: Vec<String>,
    unset_optional: Vec<String>,
}

impl Status {
    fn satisfied(&self) -> bool {
        self.missing.is_empty()
    }

    fn describe(&self) -> String {
        let mut parts = Vec::new();
        if self.satisfied() {
            parts.push("ok".to_owned());
        } else {
            parts.push(format!("missing {}", self.missing.join(", ")));
        }
        if !self.unset_optional.is_empty() {
            parts.push(format!("optional unset {}", self.unset_optional.join(", ")));
        }
        parts.join("; ")
    }
}

fn check(ctx: &Context, profile: Option<&str>) -> Result<()> {
    let statuses = match profile {
        Some(profile) => vec![status(ctx, profile)?],
        None => statuses(ctx)?,
    };
    for status in &statuses {
        println!("{:<12} {}", status.profile, status.describe());
    }
    if let Some(profile) = profile
        && !statuses.iter().all(Status::satisfied)
    {
        bail!(
            "the {profile} secrets are incomplete; add them to the Typewriter vault, or to .env \
             without 1Password (.env.example)"
        );
    }
    Ok(())
}

/// One line for the doctor: which profiles are satisfied. A profile only some machines use (the
/// full tier's, the releases') is no problem when it is not; only a spec that cannot be read is.
pub fn summary(ctx: &Context) -> Result<String> {
    let (satisfied, unsatisfied): (Vec<Status>, Vec<Status>) =
        statuses(ctx)?.into_iter().partition(Status::satisfied);
    let names = |statuses: &[Status]| {
        statuses
            .iter()
            .map(|status| status.profile.as_str())
            .collect::<Vec<_>>()
            .join(", ")
    };
    Ok(if unsatisfied.is_empty() {
        "ok".to_owned()
    } else {
        format!(
            "satisfied: {}; incomplete: {} (`cargo xtask secrets check` lists what each misses)",
            names(&satisfied),
            names(&unsatisfied)
        )
    })
}

/// Every profile's status, read concurrently: each is a round trip to the vault.
fn statuses(ctx: &Context) -> Result<Vec<Status>> {
    let profiles = profiles(ctx)?;
    thread::scope(|scope| {
        let reports = profiles
            .iter()
            .map(|profile| scope.spawn(|| status(ctx, profile)))
            .collect::<Vec<_>>();
        reports
            .into_iter()
            .map(|report| report.join().expect("a status report does not panic"))
            .collect()
    })
}

fn status(ctx: &Context, profile: &str) -> Result<Status> {
    Profile::try_from(profile).with_context(|| format!("{SPEC} has no profile {profile}"))?;
    let mut secrets = Secrets::load_from(&ctx.root.join(SPEC))
        .with_context(|| format!("cannot load {SPEC}"))?
        .with_reason("report which secrets each profile is missing");
    secrets.set_profile(profile);
    let report = secrets
        .report()
        .with_context(|| format!("cannot check the {profile} secrets"))?;
    let named = |wanted: ResolutionStatus| {
        report
            .secrets
            .iter()
            .filter(|secret| secret.status == wanted)
            .map(|secret| secret.name.clone())
            .collect()
    };
    Ok(Status {
        profile: profile.to_owned(),
        missing: named(ResolutionStatus::MissingRequired),
        unset_optional: named(ResolutionStatus::MissingOptional),
    })
}

/// The profile names, sorted.
fn profiles(ctx: &Context) -> Result<Vec<String>> {
    #[derive(Deserialize)]
    struct Spec {
        profiles: BTreeMap<String, IgnoredAny>,
    }
    let file = ctx.root.join(SPEC);
    let text = std::fs::read_to_string(&file)
        .with_context(|| format!("cannot read {}", file.display()))?;
    let spec: Spec = toml::from_str(&text).with_context(|| format!("{SPEC} is not valid"))?;
    Ok(spec.profiles.into_keys().collect())
}
