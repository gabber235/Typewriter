use std::{
    any::{Any, TypeId},
    collections::{HashMap, HashSet},
    marker::PhantomData,
    sync::Arc,
    time::Duration,
};

use anyhow::{Result, bail};
use async_trait::async_trait;
use wash_runtime::{
    host::allowed_hosts::AllowedHost,
    plugin::HostPlugin,
    types::{Volume, VolumeMount},
    wit::WitInterface,
};

use crate::{FixtureDeclaration, MessagingMock, http_mock::MockRegistry};

#[derive(Clone, Default)]
pub struct ComponentConfiguration {
    pub environment: HashMap<String, String>,
    pub secret_environment: HashSet<String>,
    pub config: HashMap<String, String>,
    pub allowed_hosts: Vec<AllowedHost>,
    pub volume_mounts: Vec<VolumeMount>,
    pub subscriptions: Vec<String>,
}

impl ComponentConfiguration {
    pub fn environment(mut self, name: impl Into<String>, value: impl Into<String>) -> Self {
        self.environment.insert(name.into(), value.into());
        self
    }
    pub fn secret_environment(mut self, name: impl Into<String>, value: impl Into<String>) -> Self {
        let name = name.into();
        self.secret_environment.insert(name.clone());
        self.environment.insert(name, value.into());
        self
    }
    pub fn config(mut self, name: impl Into<String>, value: impl Into<String>) -> Self {
        self.config.insert(name.into(), value.into());
        self
    }
    pub fn allowed_host(mut self, host: AllowedHost) -> Self {
        self.allowed_hosts.push(host);
        self
    }
    pub fn mount(mut self, mount: VolumeMount) -> Self {
        self.volume_mounts.push(mount);
        self
    }
    pub fn subscription(mut self, subject: impl Into<String>) -> Self {
        self.subscriptions.push(subject.into());
        self
    }
}

pub trait FixtureSpec: FixtureDeclaration + Sized {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self>;
}

pub struct FixtureBuilder<F> {
    pub(crate) components: HashMap<String, ComponentConfiguration>,
    pub(crate) volumes: Vec<Volume>,
    pub(crate) http_host: Option<String>,
    pub(crate) messaging: bool,
    pub(crate) messaging_mock: MessagingMock,
    pub(crate) plugins: Vec<Arc<dyn HostPlugin>>,
    pub(crate) interfaces: Vec<WitInterface>,
    pub(crate) extensions: Vec<Box<dyn ErasedExtension>>,
    pub(crate) http_mocks: MockRegistry,
    pub(crate) mock_handles: HashMap<TypeId, Arc<dyn Any + Send + Sync>>,
    pub(crate) configuration_errors: Vec<String>,
    pub(crate) start_timeout: Duration,
    pub(crate) body_timeout: Duration,
    pub(crate) drain_timeout: Duration,
    pub(crate) stop_timeout: Duration,
    marker: PhantomData<F>,
}

impl<F: FixtureDeclaration> FixtureBuilder<F> {
    pub fn new() -> Self {
        let mut components = HashMap::new();
        components.insert(
            F::DESCRIPTOR.primary.package.to_string(),
            ComponentConfiguration::default(),
        );
        Self {
            components,
            volumes: Vec::new(),
            http_host: None,
            messaging: false,
            messaging_mock: MessagingMock::new(Vec::new()),
            plugins: Vec::new(),
            interfaces: Vec::new(),
            extensions: Vec::new(),
            http_mocks: MockRegistry::default(),
            mock_handles: HashMap::new(),
            configuration_errors: Vec::new(),
            start_timeout: Duration::from_secs(30),
            body_timeout: Duration::from_secs(30),
            drain_timeout: Duration::from_secs(10),
            stop_timeout: Duration::from_secs(10),
            marker: PhantomData,
        }
    }
    pub fn primary(
        mut self,
        configure: impl FnOnce(ComponentConfiguration) -> ComponentConfiguration,
    ) -> Self {
        let name = F::DESCRIPTOR.primary.package;
        let current = self.components.remove(name).unwrap_or_default();
        self.components.insert(name.to_string(), configure(current));
        self
    }
    pub fn dependency(
        mut self,
        package: impl Into<String>,
        configure: impl FnOnce(ComponentConfiguration) -> ComponentConfiguration,
    ) -> Self {
        let package = package.into();
        let current = self.components.remove(&package).unwrap_or_default();
        self.components.insert(package, configure(current));
        self
    }
    pub fn volume(mut self, volume: Volume) -> Self {
        self.volumes.push(volume);
        self
    }
    pub fn http(mut self, host: impl Into<String>) -> Self {
        self.http_host = Some(host.into());
        self
    }
    pub fn outgoing_http<M: Send + Sync + 'static>(self, base_url: impl AsRef<str>) -> Self {
        let primary = F::DESCRIPTOR.primary.package.to_string();
        self.outgoing_http_for::<M>(primary, base_url)
    }
    pub fn outgoing_http_for<M: Send + Sync + 'static>(
        mut self,
        component: impl AsRef<str>,
        base_url: impl AsRef<str>,
    ) -> Self {
        let parsed = base_url.as_ref().parse::<http::Uri>();
        let authority = parsed
            .as_ref()
            .ok()
            .and_then(http::Uri::authority)
            .map(ToString::to_string);
        let scheme = parsed
            .as_ref()
            .ok()
            .and_then(http::Uri::scheme_str)
            .filter(|scheme| matches!(*scheme, "http" | "https"));
        let (Some(authority), Some(scheme)) = (authority, scheme) else {
            self.configuration_errors.push(format!(
                "outgoing HTTP base URL `{}` must use http or https and include an authority",
                base_url.as_ref()
            ));
            return self;
        };
        match self.http_mocks.insert::<M>(authority.clone()) {
            Ok(mock) => {
                self.mock_handles.insert(TypeId::of::<M>(), Arc::new(mock));
            }
            Err(error) => {
                self.configuration_errors.push(error.to_string());
                return self;
            }
        }
        let allowed = format!("{scheme}://{authority}").parse();
        match (self.components.get_mut(component.as_ref()), allowed) {
            (Some(configuration), Ok(host)) => configuration.allowed_hosts.push(host),
            (None, _) => self.configuration_errors.push(format!(
                "outgoing HTTP mock references unknown component `{}`",
                component.as_ref()
            )),
            (_, Err(error)) => self.configuration_errors.push(format!(
                "invalid outgoing HTTP authority `{authority}`: {error}"
            )),
        }
        self
    }
    pub fn messaging(mut self) -> Self {
        self.messaging = true;
        self
    }
    pub fn messaging_with(mut self, configure: impl FnOnce(&MessagingMock)) -> Self {
        self.messaging = true;
        configure(&self.messaging_mock);
        self
    }
    pub fn messaging_subscription(self, subject: impl Into<String>) -> Self {
        self.messaging()
            .primary(|component| component.subscription(subject))
    }
    pub fn interface(mut self, interface: WitInterface) -> Self {
        self.interfaces.push(interface);
        self
    }
    pub fn otel(mut self) -> Self {
        self.interfaces
            .push(WitInterface::from("wasi:otel/tracing@0.2.0-rc.2"));
        self
    }
    pub fn timeouts(mut self, start_body: Duration, drain_stop: Duration) -> Self {
        self.start_timeout = start_body;
        self.body_timeout = start_body;
        self.drain_timeout = drain_stop;
        self.stop_timeout = drain_stop;
        self
    }
    pub fn plugin(mut self, plugin: Arc<dyn HostPlugin>) -> Self {
        self.plugins.push(plugin);
        self
    }
    pub fn extension<E: FixtureExtension>(mut self, extension: E) -> Self {
        self.extensions.push(Box::new(ExtensionAdapter(extension)));
        self
    }
    pub fn validate(&self) -> Result<()> {
        if !self.configuration_errors.is_empty() {
            bail!(self.configuration_errors.join("; "));
        }
        let allowed = F::DESCRIPTOR
            .components()
            .map(|component| component.package)
            .collect::<HashSet<_>>();
        for package in self.components.keys() {
            if !allowed.contains(package.as_str()) {
                bail!("configuration references undeclared dependency package `{package}`");
            }
        }
        if self.components.len() != allowed.len() {
            bail!("every descriptor component must be configured exactly once");
        }
        if let Some(host) = &self.http_host
            && !valid_dns(host)
        {
            bail!("HTTP host `{host}` is not DNS-valid");
        }
        let volumes = self
            .volumes
            .iter()
            .map(|volume| volume.name.as_str())
            .collect::<HashSet<_>>();
        if volumes.len() != self.volumes.len() {
            bail!("duplicate volume name");
        }
        for (package, component) in &self.components {
            let subscriptions = component.subscriptions.iter().collect::<HashSet<_>>();
            if subscriptions.len() != component.subscriptions.len() {
                bail!("duplicate messaging subscription on `{package}`");
            }
            if self.messaging && component.subscriptions.is_empty() {
                bail!("messaging component `{package}` requires at least one subscription");
            }
            for mount in &component.volume_mounts {
                if !volumes.contains(mount.name.as_str()) {
                    bail!(
                        "component `{package}` references unknown volume `{}`",
                        mount.name
                    );
                }
            }
        }
        Ok(())
    }
}
impl<F: FixtureDeclaration> Default for FixtureBuilder<F> {
    fn default() -> Self {
        Self::new()
    }
}
fn valid_dns(value: &str) -> bool {
    !value.is_empty()
        && value.len() <= 253
        && value.split('.').all(|part| {
            !part.is_empty()
                && part.len() <= 63
                && !part.starts_with('-')
                && !part.ends_with('-')
                && part
                    .bytes()
                    .all(|byte| byte.is_ascii_alphanumeric() || byte == b'-')
        })
}
#[derive(Default)]
pub struct ProvisionContext {
    pub(crate) handles: HashMap<TypeId, Arc<dyn Any + Send + Sync>>,
    pub(crate) plugins: Vec<Arc<dyn HostPlugin>>,
    pub(crate) interfaces: Vec<WitInterface>,
    pub(crate) components: HashMap<String, ComponentConfiguration>,
    pub(crate) diagnostics: Vec<String>,
    pub(crate) redactions: Vec<String>,
}
impl ProvisionContext {
    pub fn insert<T: Send + Sync + 'static>(&mut self, value: T) -> Arc<T> {
        let value = Arc::new(value);
        self.handles.insert(TypeId::of::<T>(), value.clone());
        value
    }
    pub fn plugin(&mut self, plugin: Arc<dyn HostPlugin>) {
        self.plugins.push(plugin);
    }
    pub fn interface(&mut self, interface: WitInterface) {
        self.interfaces.push(interface);
    }
    pub fn component(&mut self, name: impl Into<String>, configuration: ComponentConfiguration) {
        self.components.insert(name.into(), configuration);
    }
    pub fn diagnostic(&mut self, message: impl Into<String>) {
        self.diagnostics.push(message.into());
    }
    pub fn redact(&mut self, value: impl Into<String>) {
        self.redactions.push(value.into());
    }
}

#[async_trait]
pub trait FixtureExtension: Send + 'static {
    type Handle: Send + Sync + 'static;
    async fn provision(&mut self, context: &mut ProvisionContext) -> Result<Self::Handle>;
    async fn before_start(&mut self) -> Result<()> {
        Ok(())
    }
    async fn verify(&mut self) -> Result<()> {
        Ok(())
    }
    async fn cleanup(&mut self) -> Result<()> {
        Ok(())
    }
}
#[async_trait]
pub(crate) trait ErasedExtension: Send {
    async fn provision(&mut self, context: &mut ProvisionContext) -> Result<()>;
    async fn before_start(&mut self) -> Result<()>;
    async fn verify(&mut self) -> Result<()>;
    async fn cleanup(&mut self) -> Result<()>;
}
struct ExtensionAdapter<E>(E);
#[async_trait]
impl<E: FixtureExtension> ErasedExtension for ExtensionAdapter<E> {
    async fn provision(&mut self, context: &mut ProvisionContext) -> Result<()> {
        let handle = self.0.provision(context).await?;
        context.insert(handle);
        Ok(())
    }
    async fn before_start(&mut self) -> Result<()> {
        self.0.before_start().await
    }
    async fn verify(&mut self) -> Result<()> {
        self.0.verify().await
    }
    async fn cleanup(&mut self) -> Result<()> {
        self.0.cleanup().await
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use component_test_model::{ComponentBuild, FixtureDescriptor};

    struct Fixture;
    impl FixtureDeclaration for Fixture {
        const DESCRIPTOR: FixtureDescriptor = FixtureDescriptor {
            id: "fixture",
            primary: ComponentBuild::primary("component", "component"),
            dependencies: &[],
            affected_paths: &[],
        };
    }
    struct Endpoint;

    #[test]
    fn outgoing_http_preserves_https_policy() {
        let builder =
            FixtureBuilder::<Fixture>::new().outgoing_http::<Endpoint>("https://authentik.test");
        assert!(builder.configuration_errors.is_empty());
        let hosts = &builder.components["component"].allowed_hosts;
        assert_eq!(hosts, &["https://authentik.test".parse().unwrap()]);
    }
}
