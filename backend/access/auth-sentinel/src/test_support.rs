//! Fixtures for unit testing the sentinel endpoint.

/// A subscriber that records every field of every span and event, to check what tracing exposes.
#[derive(Clone, Default)]
pub(crate) struct CapturedTracing {
    pub(crate) fields: std::sync::Arc<std::sync::Mutex<Vec<(String, String)>>>,
    next_id: std::sync::Arc<std::sync::atomic::AtomicU64>,
}

struct FieldVisitor<'a>(&'a mut Vec<(String, String)>);

impl tracing::field::Visit for FieldVisitor<'_> {
    fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug) {
        self.0.push((field.name().to_owned(), format!("{value:?}")));
    }
}

impl tracing::Subscriber for CapturedTracing {
    fn enabled(&self, _: &tracing::Metadata<'_>) -> bool {
        true
    }

    fn new_span(&self, attrs: &tracing::span::Attributes<'_>) -> tracing::span::Id {
        attrs.record(&mut FieldVisitor(&mut self.fields.lock().unwrap()));
        let id = self
            .next_id
            .fetch_add(1, std::sync::atomic::Ordering::Relaxed)
            + 1;
        tracing::span::Id::from_u64(id)
    }

    fn record(&self, _: &tracing::span::Id, values: &tracing::span::Record<'_>) {
        values.record(&mut FieldVisitor(&mut self.fields.lock().unwrap()));
    }

    fn record_follows_from(&self, _: &tracing::span::Id, _: &tracing::span::Id) {}

    fn event(&self, event: &tracing::Event<'_>) {
        event.record(&mut FieldVisitor(&mut self.fields.lock().unwrap()));
    }

    fn enter(&self, _: &tracing::span::Id) {}
    fn exit(&self, _: &tracing::span::Id) {}
}
