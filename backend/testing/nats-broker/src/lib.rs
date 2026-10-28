//! One operator mode `nats-server` per test process that hands every caller its own account.
//!
//! An account isolates subjects, inboxes and JetStream streams exactly like a separate server, so
//! fixed names such as a stream called `TYPEWRITER_MEMBERSHIP` still work per caller, while a
//! caller pays for one account request instead of a server start and a JetStream initialization.
//! Users are minted as JWTs, so a user can carry any permission set, response permissions
//! included.

mod config;

use std::{path::PathBuf, process::Stdio, sync::OnceLock, time::Duration};

use anyhow::{Context, Result, bail, ensure};
use nats_jwt_rs::{
    Claim, Claims,
    account::{Account as AccountClaims, JetStreamLimits},
    types::{GenericFields, NO_LIMIT},
    user::User,
};
use nkeys::KeyPair;
use serde::{Deserialize, Serialize};
use tokio::{
    io::{AsyncBufReadExt, BufReader},
    process::{Child, Command},
    sync::OnceCell,
    task::JoinHandle,
};

pub use nats_jwt_rs::types::{Permission, Permissions, ResponsePermission};

/// How long the server may take to report that it is ready.
const STARTUP_TIMEOUT: Duration = Duration::from_secs(10);

static SHARED: OnceCell<Broker> = OnceCell::const_new();

/// The shared server's process and state directory, for the exit handler.
static SHARED_PROCESS: OnceLock<(libc::pid_t, PathBuf)> = OnceLock::new();

/// A running `nats-server` and the operator that signs its accounts.
pub struct Broker {
    endpoint: String,
    operator: KeyPair,
    system: async_nats::Client,
    server: NatsProcess,
}

impl Broker {
    /// The broker of this test process, started on first use and stopped when the process exits.
    ///
    /// Its connections live on the runtime that first calls this, so every caller must share
    /// that runtime, as the component test suite's single global runtime does.
    pub async fn shared() -> Result<&'static Broker> {
        SHARED
            .get_or_try_init(|| async {
                let broker = Broker::start().await?;
                broker.server.stop_at_exit()?;
                Ok(broker)
            })
            .await
    }

    /// A broker of its own on free ports, stopped on drop.
    pub async fn start() -> Result<Broker> {
        Self::start_with(
            KeyPair::new_operator(),
            KeyPair::new_account(),
            Ports::default(),
        )
        .await
    }

    /// A broker trusting `operator`, with `system` as its system account, stopped on drop. Keys
    /// a caller keeps across starts keep the credentials it minted valid.
    pub async fn start_with(operator: KeyPair, system: KeyPair, ports: Ports) -> Result<Broker> {
        let state = tempfile::tempdir()?;
        let config = config::render(&operator, &system, ports, state.path())?;
        let server = NatsProcess::start(&config, state).await?;
        let system = mint_user(&system, &Permissions::default())?
            .connect(&server.endpoint)
            .await
            .context("connecting the system account")?;
        Ok(Broker {
            endpoint: server.endpoint.clone(),
            operator,
            system,
            server,
        })
    }

    /// A new account with JetStream, pushed to the running server without a restart. The account
    /// reserves no JetStream storage, so only the server's total applies and the number of
    /// accounts is unbounded.
    pub async fn account(&self) -> Result<Account> {
        let key = KeyPair::new_account();
        self.install(account_claims("caller", &key))
            .await
            .context("creating an account")?;
        Ok(Account {
            key,
            endpoint: self.endpoint.clone(),
        })
    }

    /// Pushes an account the caller described (signing keys, auth callout, imports), signed by
    /// the operator, to the running server. Installing an account again replaces it.
    pub async fn install(&self, claims: Claims<AccountClaims>) -> Result<()> {
        self.claims_request("$SYS.REQ.CLAIMS.UPDATE", claims.encode(&self.operator)?)
            .await
    }

    /// The client URL.
    pub fn endpoint(&self) -> &str {
        &self.endpoint
    }

    /// Removes `account` and everything in it.
    pub async fn delete(&self, account: &Account) -> Result<()> {
        // The server accepts a delete request only when the operator signs it about itself.
        let request = Claims {
            aud: None,
            exp: None,
            iat: 0,
            id: None,
            iss: String::new(),
            jti: String::new(),
            name: None,
            nats: DeleteAccounts {
                accounts: vec![account.key.public_key()],
                generic_fields: GenericFields::default(),
            },
            nbf: None,
            sub: self.operator.public_key(),
        };
        self.claims_request("$SYS.REQ.CLAIMS.DELETE", request.encode(&self.operator)?)
            .await
            .context("deleting an account")
    }

    async fn claims_request(&self, subject: &'static str, jwt: String) -> Result<()> {
        let reply = self.system.request(subject, jwt.into()).await?;
        let response: ClaimsResponse = serde_json::from_slice(&reply.payload)
            .with_context(|| format!("{subject} answered with an unreadable response"))?;
        match response.error {
            Some(error) => bail!("{subject} was refused: {}", error.description),
            None => Ok(()),
        }
    }
}

/// Fixed listener ports; a missing client port means any free port, a missing websocket port
/// means no websocket listener.
#[derive(Clone, Copy, Default)]
pub struct Ports {
    pub client: Option<u16>,
    pub websocket: Option<u16>,
}

/// Claims for an account named `name` with unlimited JetStream. The account reserves no
/// JetStream storage, so only the server's total applies.
pub fn account_claims(name: &str, key: &KeyPair) -> Claims<AccountClaims> {
    let mut claims = AccountClaims::new_claims(name.into(), key.public_key());
    claims
        .payload_mut()
        .limits
        .get_or_insert_default()
        .jetstream = Some(JetStreamLimits {
        memory_storage: Some(NO_LIMIT),
        disk_storage: Some(NO_LIMIT),
        streams: Some(NO_LIMIT),
        consumer: Some(NO_LIMIT),
        ..JetStreamLimits::default()
    });
    claims
}

/// One account on a broker. Clones refer to the same account.
#[derive(Clone)]
pub struct Account {
    key: KeyPair,
    endpoint: String,
}

impl Account {
    /// The client URL of the broker the account lives on.
    pub fn endpoint(&self) -> &str {
        &self.endpoint
    }

    /// A user holding exactly `permissions`; an empty allow list allows every subject.
    pub fn user(&self, permissions: &Permissions) -> Result<Credentials> {
        mint_user(&self.key, permissions)
    }

    /// A user that may publish and subscribe to every subject of the account.
    pub fn admin(&self) -> Result<Credentials> {
        self.user(&Permissions::default())
    }
}

/// A user JWT and the seed that proves it, the two values a NATS client signs in with.
#[derive(Clone)]
pub struct Credentials {
    jwt: String,
    seed: String,
}

impl Credentials {
    pub fn jwt(&self) -> &str {
        &self.jwt
    }

    pub fn seed(&self) -> &str {
        &self.seed
    }

    /// The `.creds` file text NATS clients read.
    pub fn to_creds_file(&self) -> String {
        format!(
            "-----BEGIN NATS USER JWT-----\n{}\n------END NATS USER JWT------\n\n\
             -----BEGIN USER NKEY SEED-----\n{}\n------END USER NKEY SEED------\n",
            self.jwt, self.seed
        )
    }

    /// Connects to the broker at `endpoint` as this user.
    pub async fn connect(&self, endpoint: &str) -> Result<async_nats::Client> {
        let key = KeyPair::from_seed(&self.seed)?;
        let options = async_nats::ConnectOptions::with_jwt(self.jwt.clone(), move |nonce| {
            let key = key.clone();
            async move { key.sign(&nonce).map_err(async_nats::AuthError::new) }
        });
        Ok(options.connect(endpoint).await?)
    }
}

fn mint_user(account: &KeyPair, permissions: &Permissions) -> Result<Credentials> {
    let key = KeyPair::new_user();
    let mut claims = User::new_claims("user".into(), key.public_key());
    claims.payload_mut().permissions.permissions = permissions.clone();
    Ok(Credentials {
        jwt: claims.encode(account)?,
        seed: key.seed()?,
    })
}

/// The payload of a `$SYS.REQ.CLAIMS.DELETE` request.
#[derive(Clone, Serialize, Deserialize)]
struct DeleteAccounts {
    accounts: Vec<String>,
    #[serde(flatten)]
    generic_fields: GenericFields,
}

impl Claim for DeleteAccounts {
    fn validate() {}
}

/// The server's answer to a claims request; only a refusal carries information.
#[derive(Deserialize)]
struct ClaimsResponse {
    error: Option<ClaimsError>,
}

#[derive(Deserialize)]
struct ClaimsError {
    #[serde(default)]
    description: String,
}

/// The server process, killed on drop.
struct NatsProcess {
    endpoint: String,
    child: Child,
    stderr: JoinHandle<()>,
    state: tempfile::TempDir,
}

impl NatsProcess {
    async fn start(config: &str, state: tempfile::TempDir) -> Result<Self> {
        let path = state.path().join("nats.conf");
        std::fs::write(&path, config)
            .with_context(|| format!("cannot write {}", path.display()))?;
        let binary = std::env::var_os("NATS_SERVER_BIN").unwrap_or_else(|| "nats-server".into());
        let mut child = Command::new(binary)
            .arg("--config")
            .arg(&path)
            .stdout(Stdio::null())
            .stderr(Stdio::piped())
            .kill_on_drop(true)
            .spawn()
            .context("starting nats-server; enter the devenv shell or set NATS_SERVER_BIN")?;
        let mut lines = BufReader::new(
            child
                .stderr
                .take()
                .context("nats-server stderr unavailable")?,
        )
        .lines();
        let endpoint = tokio::time::timeout(STARTUP_TIMEOUT, async {
            let mut endpoint = None;
            let mut output = Vec::new();
            while let Some(line) = lines.next_line().await? {
                if let Some((_, address)) = line.split_once("Listening for client connections on ")
                {
                    endpoint = Some(format!("nats://{}", address.trim()));
                }
                if line.contains("Server is ready") {
                    return endpoint.context("nats-server was ready without a client address");
                }
                output.push(line);
            }
            bail!(
                "nats-server exited before it was ready: {}",
                output.join(" | ")
            )
        })
        .await
        .context("nats-server did not become ready in time")??;
        // Drains the pipe, so the server never blocks on a full stderr.
        let stderr =
            tokio::spawn(async move { while let Ok(Some(_)) = lines.next_line().await {} });
        Ok(Self {
            endpoint,
            child,
            stderr,
            state,
        })
    }

    /// Kills the server and removes its state when the process exits. A static broker is never
    /// dropped, so `kill_on_drop` alone would leave the server running after the tests.
    fn stop_at_exit(&self) -> Result<()> {
        let pid = self.child.id().context("nats-server exited")?;
        let pid = libc::pid_t::try_from(pid)?;
        ensure!(
            SHARED_PROCESS
                .set((pid, self.state.path().to_owned()))
                .is_ok(),
            "the shared broker started twice"
        );
        // SAFETY: `stop_shared` takes no arguments, never unwinds and only reads a static.
        let registered = unsafe { libc::atexit(stop_shared) };
        ensure!(registered == 0, "cannot register the nats-server shutdown");
        Ok(())
    }
}

impl Drop for NatsProcess {
    fn drop(&mut self) {
        self.stderr.abort();
    }
}

extern "C" fn stop_shared() {
    if let Some((pid, state)) = SHARED_PROCESS.get() {
        // SAFETY: sending a signal has no memory effects; the pid is the server this process
        // started and still holds as a child, so it cannot have been reused.
        unsafe { libc::kill(*pid, libc::SIGKILL) };
        #[expect(
            clippy::let_underscore_must_use,
            reason = "best effort cleanup at process exit; nobody is left to report to"
        )]
        let _ = std::fs::remove_dir_all(state);
    }
}
