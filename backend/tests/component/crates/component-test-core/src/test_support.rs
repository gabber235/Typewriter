//! Shared builders for the runtime's unit tests: fixture declarations, diagnostic reports that
//! capture their live lines, mock requests, host messages, and spans to submit to a telemetry
//! capture.

use std::{
    borrow::Cow,
    sync::{Arc, Mutex},
    time::{Duration, SystemTime},
};

use bytes::Bytes;
use component_test_model::{ComponentBuild, FixtureDescriptor};
use http::{HeaderMap, Method};
use opentelemetry::trace::{
    Event, Link, SpanContext, SpanId, SpanKind, Status, TraceFlags, TraceId, TraceState,
};
use opentelemetry::{InstrumentationScope, KeyValue};
use opentelemetry_sdk::Resource;
use opentelemetry_sdk::trace::{SpanData, SpanEvents, SpanLinks};
use wash_runtime::plugin::wasi_otel::WasiOtelSpanProcessorFactory;

use crate::FixtureDeclaration;
use crate::MockRequest;
use crate::diagnostic::DiagnosticReport;
use crate::nats::HostMessage;
use crate::telemetry::TelemetryCapture;

/// A fixture of one component without dependencies.
pub(crate) struct Fixture;

impl FixtureDeclaration for Fixture {
    const DESCRIPTOR: FixtureDescriptor = FixtureDescriptor {
        id: "fixture",
        primary: ComponentBuild::primary("component", "component"),
        dependencies: &[],
    };
}

/// A fixture whose HTTP component depends on a messaging component.
pub(crate) struct MessagingFixture;

impl FixtureDeclaration for MessagingFixture {
    const DESCRIPTOR: FixtureDescriptor = FixtureDescriptor {
        id: "messaging-fixture",
        primary: ComponentBuild::primary("http-component", "http_component"),
        dependencies: &[ComponentBuild::dependency(
            "messaging-component",
            "messaging_component",
        )],
    };
}

/// A marker naming an outgoing HTTP endpoint.
pub(crate) struct Endpoint;

/// The lines a report printed live.
pub(crate) type Lines = Arc<Mutex<Vec<String>>>;

/// A report for case `case` of `fixture::test` that redacts `secret`, with the lines it prints.
pub(crate) fn diagnostic_report(live: bool) -> (DiagnosticReport, Lines) {
    let output = Lines::default();
    let captured = output.clone();
    let mut report = DiagnosticReport::with_sink(
        "fixture",
        "test",
        Some("case"),
        vec!["secret".into()],
        Arc::new(move |line| captured.lock().unwrap().push(line.into())),
    );
    report.live = live;
    (report, output)
}

/// A `POST http://mock.test/items?a=1` request carrying `body`.
pub(crate) fn mock_request(body: impl Into<Bytes>) -> MockRequest {
    MockRequest {
        method: Method::POST,
        uri: "http://mock.test/items?a=1".parse().unwrap(),
        headers: HeaderMap::new(),
        body: body.into(),
    }
}

/// A message on `subject` without a reply subject.
pub(crate) fn host_message(subject: &str, body: &[u8]) -> HostMessage {
    HostMessage {
        subject: subject.into(),
        reply_to: None,
        body: body.into(),
    }
}

/// The resource a component named `component` reports its spans under.
pub(crate) fn component_resource(component: &str) -> Resource {
    Resource::builder_empty()
        .with_attribute(KeyValue::new(
            "wasmcloud.component.name",
            component.to_string(),
        ))
        .build()
}

/// A failed server span starting `start_offset` seconds after the epoch, with every field set,
/// including an event, a link and dropped counts.
pub(crate) fn failed_span(name: &'static str, start_offset: u64) -> SpanData {
    let start_time = SystemTime::UNIX_EPOCH + Duration::from_secs(start_offset);
    let event_context = SpanContext::new(
        TraceId::from(0x2222),
        SpanId::from(0x22),
        TraceFlags::SAMPLED,
        true,
        TraceState::default(),
    );
    let mut events = SpanEvents::default();
    events.events.push(Event::new(
        "failure",
        start_time + Duration::from_millis(10),
        vec![KeyValue::new("exception.slug", "query-failed")],
        2,
    ));
    events.dropped_count = 3;
    let mut links = SpanLinks::default();
    links.links.push(Link::new(
        event_context,
        vec![KeyValue::new("link.type", "retry")],
        4,
    ));
    links.dropped_count = 5;
    SpanData {
        span_context: SpanContext::new(
            TraceId::from(0x1111),
            SpanId::from(start_offset + 1),
            TraceFlags::SAMPLED,
            false,
            TraceState::default(),
        ),
        parent_span_id: SpanId::from(0x10),
        parent_span_is_remote: true,
        span_kind: SpanKind::Server,
        name: Cow::Borrowed(name),
        start_time,
        end_time: start_time + Duration::from_millis(25),
        attributes: vec![KeyValue::new("request.id", "secret-request")],
        dropped_attributes_count: 1,
        events,
        links,
        status: Status::error("database failed"),
        instrumentation_scope: InstrumentationScope::builder("guest-sdk")
            .with_version("1.2.3")
            .with_schema_url("https://example.test/schema")
            .with_attributes([KeyValue::new("scope.key", "scope-value")])
            .build(),
    }
}

/// Ends `span` under `resource` through a processor of `capture`, then flushes and shuts it down.
pub(crate) fn submit_span(capture: &TelemetryCapture, resource: Resource, span: SpanData) {
    let processor = capture.create(&resource);
    processor.on_end(span);
    processor.force_flush().unwrap();
    processor.shutdown().unwrap();
}
