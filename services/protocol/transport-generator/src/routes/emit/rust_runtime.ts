/**
 * Route independent Rust declarations of the generated transport module: subject tokens, grant sets
 * and scope types, then the request and event dispatch runtime. They are written in rustfmt layout,
 * so formatting the generated module leaves them unchanged.
 */

/** Subject tokens, grant sets and the scope types every route scope names. */
export const RUST_SCOPES = String.raw`#[derive(Clone, Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct SubjectToken(String);
impl SubjectToken {
    pub fn as_str(&self) -> &str {
        &self.0
    }
}
impl TryFrom<&str> for SubjectToken {
    type Error = crate::otel_wasi::Error;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        if value.is_empty()
            || value
                .chars()
                .any(|character| character.is_whitespace() || ".*>{}".contains(character))
        {
            return Err(crate::otel_wasi::Error::new(
                "transport-invalid-token",
                "Invalid subject identity",
            ));
        }
        Ok(Self(value.to_owned()))
    }
}
impl std::fmt::Display for SubjectToken {
    fn fmt(&self, output: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        output.write_str(self.as_str())
    }
}
#[derive(Default)]
pub struct GrantSet {
    pub publish: std::collections::BTreeSet<String>,
    pub subscribe: std::collections::BTreeSet<String>,
}
#[derive(Clone, Debug)]
pub struct RealmScope {
    pub organization: SubjectToken,
    pub realm: SubjectToken,
}
#[derive(Clone, Debug)]
pub struct ServiceScope {
    pub service: SubjectToken,
}
#[derive(Clone, Debug)]
pub struct OrganizationActorScope {
    pub user: SubjectToken,
    pub organization: SubjectToken,
}
#[derive(Clone, Debug)]
pub struct OrganizationScope {
    pub organization: SubjectToken,
}
#[derive(Clone, Debug)]
pub struct UserScope {
    pub user: SubjectToken,
}
#[derive(Clone, Copy, Debug)]
pub struct InternalComponentScope;
impl TryFrom<&str> for ServiceScope {
    type Error = crate::otel_wasi::Error;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Ok(Self {
            service: SubjectToken::try_from(value)?,
        })
    }
}
impl TryFrom<&str> for OrganizationScope {
    type Error = crate::otel_wasi::Error;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Ok(Self {
            organization: SubjectToken::try_from(value)?,
        })
    }
}
impl TryFrom<&str> for UserScope {
    type Error = crate::otel_wasi::Error;
    fn try_from(value: &str) -> Result<Self, Self::Error> {
        Ok(Self {
            user: SubjectToken::try_from(value)?,
        })
    }
}`;

/** Route traits, response delivery, event delivery and the dispatch helpers and macros. */
export const RUST_DISPATCH = String.raw`pub trait RequestRoute {
    type Scope;
    type Request: 'static;
    type Response: 'static;
    type Delivery: RequestResponseDelivery<Self::Response>;
    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response>;
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error>;
}
pub trait OutboundRequestRoute: RequestRoute {
    fn subject(scope: &Self::Scope) -> String;
}
pub trait RequestResponseDelivery<Response> {
    fn reply_result(
        msg: crate::wasmcloud::messaging::types::NatsMessage,
        result: Result<Response, crate::otel_wasi::Error>,
        serializer: crate::skir_client::Serializer<Response>,
    ) -> impl std::future::Future<Output = Result<(), crate::otel_wasi::Error>>;
}
pub struct DomainResponseDelivery;
impl<Response: crate::SkirResponse> RequestResponseDelivery<Response> for DomainResponseDelivery {
    async fn reply_result(
        msg: crate::wasmcloud::messaging::types::NatsMessage,
        result: Result<Response, crate::otel_wasi::Error>,
        _serializer: crate::skir_client::Serializer<Response>,
    ) -> Result<(), crate::otel_wasi::Error> {
        crate::wasmcloud::messaging::reply_handler_result(msg, result).await
    }
}
pub struct PlainResponseDelivery;
impl<Response: 'static> RequestResponseDelivery<Response> for PlainResponseDelivery {
    async fn reply_result(
        msg: crate::wasmcloud::messaging::types::NatsMessage,
        result: Result<Response, crate::otel_wasi::Error>,
        serializer: crate::skir_client::Serializer<Response>,
    ) -> Result<(), crate::otel_wasi::Error> {
        let response = result?;
        let body = serializer.to_bytes(&response);
        crate::wasmcloud::messaging::reply(msg, body).await
    }
}
pub trait EventRoute {
    type Scope;
    type Event: 'static;
    fn serializer() -> crate::skir_client::Serializer<Self::Event>;
    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error>;
}
pub trait OutboundEventRoute {
    type Scope;
    type Event: 'static;
    fn serializer() -> crate::skir_client::Serializer<Self::Event>;
    fn subject(scope: &Self::Scope) -> String;
}
pub trait PersistentEventRoute: OutboundEventRoute {
    fn stream() -> &'static str;
}
pub trait TransientEventRoute: OutboundEventRoute {}
pub struct EventDelivery<Route: OutboundEventRoute> {
    subject: String,
    route: std::marker::PhantomData<Route>,
}
impl<Route: OutboundEventRoute> EventDelivery<Route> {
    fn new(scope: &Route::Scope) -> Self {
        Self {
            subject: Route::subject(scope),
            route: std::marker::PhantomData,
        }
    }
    pub fn subject(&self) -> &str {
        &self.subject
    }
}
impl<Route: TransientEventRoute> EventDelivery<Route> {
    pub async fn publish(&self, event: Route::Event) -> Result<(), crate::otel_wasi::Error> {
        crate::wasmcloud::messaging::publish(
            self.subject.clone(),
            Route::serializer().to_bytes(&event),
        )
        .await
    }
}
impl<Route: PersistentEventRoute> EventDelivery<Route> {
    pub async fn persist(&self, event: Route::Event) -> Result<(), crate::otel_wasi::Error> {
        let acknowledgement = crate::wasmcloud::messaging::persist(
            self.subject.clone(),
            Route::serializer().to_bytes(&event),
        )
        .await?;
        if acknowledgement.stream_name != Route::stream() {
            return Err(crate::otel_wasi::Error::new(
                "transport-event-wrong-stream",
                format!(
                    "expected {}, got {}",
                    Route::stream(),
                    acknowledgement.stream_name
                ),
            ));
        }
        Ok(())
    }
}
pub async fn dispatch_request<Route, Handler, Work>(
    msg: crate::wasmcloud::messaging::types::NatsMessage,
    handler: Handler,
) -> Option<Result<(), crate::otel_wasi::Error>>
where
    Route: RequestRoute,
    Handler: FnOnce(
        crate::wasmcloud::messaging::types::NatsMessage,
        Route::Scope,
        Route::Request,
    ) -> Work,
    Work: std::future::Future<Output = Result<Route::Response, crate::otel_wasi::Error>>,
{
    let scope = match Route::scope(&msg.subject) {
        Ok(None) => return None,
        Ok(Some(scope)) => Ok(scope),
        Err(error) => Err(error),
    };
    let result = async {
        let scope = scope?;
        let request = Route::method()
            .request_serializer
            .from_bytes(&msg.body, crate::skir_client::UnrecognizedValues::Drop)
            .map_err(|error| crate::otel_wasi::Error::new("transport-decode", error.to_string()))?;
        handler(msg.clone(), scope, request).await
    }
    .await;
    Some(
        Route::Delivery::reply_result(msg, result, Route::method().response_serializer.clone())
            .await,
    )
}
pub async fn request_route<Route: OutboundRequestRoute>(
    scope: &Route::Scope,
    request: &Route::Request,
) -> Result<Route::Response, crate::otel_wasi::Error> {
    let response = crate::wasmcloud::messaging::request(
        Route::subject(scope),
        Route::method().request_serializer.to_bytes(request),
    )
    .await?;
    Route::method()
        .response_serializer
        .from_bytes(&response.body, crate::skir_client::UnrecognizedValues::Drop)
        .map_err(|error| crate::otel_wasi::Error::new("transport-decode", error.to_string()))
}
pub fn unmatched_route(
    msg: &crate::wasmcloud::messaging::types::NatsMessage,
    slug: &'static str,
) -> crate::otel_wasi::Error {
    crate::otel_wasi::Error::new(slug, format!("Unknown subject: {}", msg.subject))
}
pub async fn dispatch_event<Route, Handler, Work>(
    msg: crate::wasmcloud::messaging::types::NatsMessage,
    handler: Handler,
) -> Option<Result<(), crate::otel_wasi::Error>>
where
    Route: EventRoute,
    Handler:
        FnOnce(crate::wasmcloud::messaging::types::NatsMessage, Route::Scope, Route::Event) -> Work,
    Work: std::future::Future<Output = Result<(), crate::otel_wasi::Error>>,
{
    let scope = match Route::scope(&msg.subject) {
        Ok(None) => return None,
        Ok(Some(scope)) => Ok(scope),
        Err(error) => Err(error),
    };
    Some(
        async {
            let scope = scope?;
            let event = Route::serializer()
                .from_bytes(&msg.body, crate::skir_client::UnrecognizedValues::Drop)
                .map_err(|error| {
                    crate::otel_wasi::Error::new("transport-decode", error.to_string())
                })?;
            handler(msg, scope, event).await
        }
        .await,
    )
}
#[macro_export]
macro_rules! dispatch_route {
    ($msg:expr, $route:ty, $handler:path) => {
        if let Some(result) =
            $crate::transport_routes::dispatch_request::<$route, _, _>($msg.clone(), $handler).await
        {
            return result;
        }
    };
}
#[macro_export]
macro_rules! dispatch_event_route {
    ($msg:expr, $route:ty, $handler:path) => {
        if let Some(result) =
            $crate::transport_routes::dispatch_event::<$route, _, _>($msg.clone(), $handler).await
        {
            return result;
        }
    };
}`;
