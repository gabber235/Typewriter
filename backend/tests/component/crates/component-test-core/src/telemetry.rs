use std::{
    collections::VecDeque,
    sync::{
        Arc, Mutex,
        atomic::{AtomicUsize, Ordering},
    },
    time::Duration,
};

use opentelemetry::{Context, Key, KeyValue};
use opentelemetry_sdk::{
    Resource,
    error::OTelSdkResult,
    trace::{Span, SpanData, SpanProcessor},
};
use wash_runtime::plugin::wasi_otel::WasiOtelSpanProcessorFactory;

const SPAN_LIMIT: usize = 512;

#[derive(Clone, Debug, Default)]
pub(crate) struct TelemetryCapture {
    state: Arc<CaptureState>,
}

#[derive(Debug, Default)]
struct CaptureState {
    spans: Mutex<VecDeque<CapturedSpan>>,
    omitted: AtomicUsize,
}

#[derive(Clone, Debug)]
struct CapturedSpan {
    resource: Resource,
    span: SpanData,
}

#[derive(Debug)]
struct CaptureProcessor {
    state: Arc<CaptureState>,
    resource: Resource,
}

impl WasiOtelSpanProcessorFactory for TelemetryCapture {
    fn create(&self, resource: &Resource) -> Box<dyn SpanProcessor> {
        Box::new(CaptureProcessor {
            state: Arc::clone(&self.state),
            resource: resource.clone(),
        })
    }
}

impl SpanProcessor for CaptureProcessor {
    fn on_start(&self, _span: &mut Span, _cx: &Context) {}

    fn on_end(&self, span: SpanData) {
        let Ok(mut spans) = self.state.spans.lock() else {
            return;
        };
        if spans.len() == SPAN_LIMIT {
            spans.pop_front();
            self.state.omitted.fetch_add(1, Ordering::Relaxed);
        }
        spans.push_back(CapturedSpan {
            resource: self.resource.clone(),
            span,
        });
    }

    fn force_flush(&self) -> OTelSdkResult {
        Ok(())
    }

    fn shutdown_with_timeout(&self, _timeout: Duration) -> OTelSdkResult {
        Ok(())
    }
}

impl TelemetryCapture {
    pub(crate) fn render(&self) -> Result<Vec<String>, &'static str> {
        let mut spans = self
            .state
            .spans
            .lock()
            .map_err(|_| "span capture lock poisoned")?
            .iter()
            .cloned()
            .collect::<Vec<_>>();
        spans.sort_by_key(|captured| captured.span.start_time);

        let mut lines = Vec::new();
        let omitted = self.state.omitted.load(Ordering::Relaxed);
        if omitted > 0 {
            lines.push(format!("omitted {omitted} older spans"));
        }
        for captured in spans {
            render_span(&captured, &mut lines);
        }
        Ok(lines)
    }
}

fn render_span(captured: &CapturedSpan, lines: &mut Vec<String>) {
    let span = &captured.span;
    let component = captured
        .resource
        .get(&Key::new("wasmcloud.component.name"))
        .map(|value| value.to_string())
        .unwrap_or_else(|| "unknown".into());
    let duration = span
        .end_time
        .duration_since(span.start_time)
        .unwrap_or_default();
    lines.push(format!(
        "span: component={component} name={} kind={:?} status={:?} duration={duration:?}",
        span.name, span.span_kind, span.status
    ));
    lines.push(format!(
        "  trace_id={} span_id={} parent_span_id={} parent_remote={}",
        span.span_context.trace_id(),
        span.span_context.span_id(),
        span.parent_span_id,
        span.parent_span_is_remote
    ));
    lines.push(format!(
        "  scope: name={} version={} schema_url={}",
        span.instrumentation_scope.name(),
        span.instrumentation_scope.version().unwrap_or("none"),
        span.instrumentation_scope.schema_url().unwrap_or("none")
    ));
    render_key_values(
        "  scope attribute",
        span.instrumentation_scope.attributes(),
        lines,
    );
    render_key_values("  attribute", span.attributes.iter(), lines);
    if span.dropped_attributes_count > 0 {
        lines.push(format!(
            "  dropped attributes: {}",
            span.dropped_attributes_count
        ));
    }
    for event in &span.events.events {
        let offset = event
            .timestamp
            .duration_since(span.start_time)
            .unwrap_or_default();
        lines.push(format!("  event: name={} offset={offset:?}", event.name));
        render_key_values("    attribute", event.attributes.iter(), lines);
        if event.dropped_attributes_count > 0 {
            lines.push(format!(
                "    dropped attributes: {}",
                event.dropped_attributes_count
            ));
        }
    }
    if span.events.dropped_count > 0 {
        lines.push(format!("  dropped events: {}", span.events.dropped_count));
    }
    for link in &span.links.links {
        lines.push(format!(
            "  link: trace_id={} span_id={} flags={:?}",
            link.span_context.trace_id(),
            link.span_context.span_id(),
            link.span_context.trace_flags()
        ));
        render_key_values("    attribute", link.attributes.iter(), lines);
        if link.dropped_attributes_count > 0 {
            lines.push(format!(
                "    dropped attributes: {}",
                link.dropped_attributes_count
            ));
        }
    }
    if span.links.dropped_count > 0 {
        lines.push(format!("  dropped links: {}", span.links.dropped_count));
    }
}

fn render_key_values<'a>(
    prefix: &str,
    values: impl IntoIterator<Item = &'a KeyValue>,
    lines: &mut Vec<String>,
) {
    lines.extend(
        values
            .into_iter()
            .map(|value| format!("{prefix}: {}={}", value.key, value.value)),
    );
}

#[cfg(test)]
mod tests {
    use std::{borrow::Cow, panic::AssertUnwindSafe, thread, time::SystemTime};

    use opentelemetry::trace::{
        Event, Link, SpanContext, SpanId, SpanKind, Status, TraceFlags, TraceId, TraceState,
    };
    use opentelemetry::{InstrumentationScope, KeyValue};
    use opentelemetry_sdk::trace::{SpanEvents, SpanLinks};

    use super::*;

    fn resource(component: &str) -> Resource {
        Resource::builder_empty()
            .with_attribute(KeyValue::new(
                "wasmcloud.component.name",
                component.to_string(),
            ))
            .build()
    }

    fn span(name: &'static str, start_offset: u64) -> SpanData {
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

    fn submit(capture: &TelemetryCapture, resource: Resource, span: SpanData) {
        let processor = capture.create(&resource);
        processor.on_end(span);
        processor.force_flush().unwrap();
        processor.shutdown().unwrap();
    }

    #[test]
    fn renders_complete_spans_in_chronological_order() {
        let capture = TelemetryCapture::default();
        submit(&capture, resource("billing"), span("later", 20));
        submit(&capture, resource("orders"), span("earlier", 10));

        let rendered = capture.render().unwrap().join("\n");

        assert!(rendered.find("name=earlier").unwrap() < rendered.find("name=later").unwrap());
        for expected in [
            "component=orders",
            "kind=Server",
            "status=Error",
            "duration=25ms",
            "trace_id=00000000000000000000000000001111",
            "parent_span_id=0000000000000010",
            "scope: name=guest-sdk version=1.2.3",
            "scope attribute: scope.key=scope-value",
            "attribute: request.id=secret-request",
            "dropped attributes: 1",
            "event: name=failure offset=10ms",
            "exception.slug=query-failed",
            "dropped events: 3",
            "link: trace_id=00000000000000000000000000002222",
            "link.type=retry",
            "dropped links: 5",
        ] {
            assert!(
                rendered.contains(expected),
                "missing `{expected}` in {rendered}"
            );
        }
    }

    #[test]
    fn keeps_latest_spans_and_reports_omitted_count() {
        let capture = TelemetryCapture::default();
        for index in 0..SPAN_LIMIT + 2 {
            submit(
                &capture,
                resource("component"),
                span(
                    Box::leak(format!("span-{index}").into_boxed_str()),
                    index as u64,
                ),
            );
        }

        let rendered = capture.render().unwrap().join("\n");

        assert!(rendered.contains("omitted 2 older spans"));
        assert!(!rendered.contains("name=span-0 "));
        assert!(rendered.contains("name=span-2 "));
        assert!(rendered.contains("name=span-513 "));
    }

    #[test]
    fn collectors_are_isolated_during_parallel_submission() {
        let first = TelemetryCapture::default();
        let second = TelemetryCapture::default();
        let first_task = {
            let capture = first.clone();
            thread::spawn(move || submit(&capture, resource("first"), span("first", 1)))
        };
        let second_task = {
            let capture = second.clone();
            thread::spawn(move || submit(&capture, resource("second"), span("second", 2)))
        };
        first_task.join().unwrap();
        second_task.join().unwrap();

        let first_rendered = first.render().unwrap().join("\n");
        let second_rendered = second.render().unwrap().join("\n");
        assert!(first_rendered.contains("component=first"));
        assert!(!first_rendered.contains("component=second"));
        assert!(second_rendered.contains("component=second"));
        assert!(!second_rendered.contains("component=first"));
    }

    #[test]
    fn poisoned_capture_returns_diagnostic_error() {
        let capture = TelemetryCapture::default();
        let state = Arc::clone(&capture.state);
        let _ = thread::spawn(move || {
            let _guard = state.spans.lock().unwrap();
            panic!("poison capture");
        })
        .join();

        assert_eq!(capture.render(), Err("span capture lock poisoned"));
        assert!(std::panic::catch_unwind(AssertUnwindSafe(|| capture.render())).is_ok());
    }
}
