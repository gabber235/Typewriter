pub fn propagation_headers() -> Vec<(String, Vec<u8>)> {
    let Some(context) = otel_wasi::current_propagation_context() else {
        return Vec::new();
    };

    let mut headers = vec![("traceparent".to_string(), context.traceparent.into_bytes())];
    if let Some(tracestate) = context.tracestate {
        headers.push(("tracestate".to_string(), tracestate.into_bytes()));
    }
    headers
}
