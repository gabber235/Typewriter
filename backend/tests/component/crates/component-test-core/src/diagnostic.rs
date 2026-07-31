use std::{
    collections::VecDeque,
    fmt::Write as _,
    sync::Arc,
    time::{Duration, Instant},
};

const EVENT_LIMIT: usize = 256;
const LINE_LIMIT: usize = 2048;

pub(crate) type LiveSink = Arc<dyn Fn(&str) + Send + Sync>;

#[derive(Clone, Debug)]
pub(crate) struct PhaseTiming {
    pub name: &'static str,
    pub duration: Duration,
}

pub(crate) struct DiagnosticReport {
    fixture: String,
    test: String,
    case: String,
    started: Instant,
    phase_started: Instant,
    current_phase: &'static str,
    failed_phase: Option<&'static str>,
    phases: Vec<PhaseTiming>,
    events: VecDeque<String>,
    failures: Vec<String>,
    redactions: Vec<String>,
    live: bool,
    sink: LiveSink,
    artifacts: Vec<String>,
}

impl DiagnosticReport {
    pub(crate) fn new(
        fixture: &str,
        test: &str,
        case: Option<&str>,
        redactions: Vec<String>,
    ) -> Self {
        Self::with_sink(
            fixture,
            test,
            case,
            redactions,
            Arc::new(|line| eprintln!("{line}")),
        )
    }

    fn with_sink(
        fixture: &str,
        test: &str,
        case: Option<&str>,
        redactions: Vec<String>,
        sink: LiveSink,
    ) -> Self {
        let now = Instant::now();
        Self {
            fixture: fixture.into(),
            test: test.into(),
            case: case.unwrap_or("-").into(),
            started: now,
            phase_started: now,
            current_phase: "admitted",
            failed_phase: None,
            phases: Vec::new(),
            events: VecDeque::new(),
            failures: Vec::new(),
            redactions,
            live: std::env::var("COMPONENT_TEST_LIVE").as_deref() == Ok("1"),
            sink,
            artifacts: Vec::new(),
        }
    }

    pub(crate) fn phase(&mut self, name: &'static str) {
        let now = Instant::now();
        self.phases.push(PhaseTiming {
            name: self.current_phase,
            duration: now.duration_since(self.phase_started),
        });
        self.current_phase = name;
        self.phase_started = now;
    }

    pub(crate) fn artifact(&mut self, path: &std::path::Path, sha: &str) {
        self.artifacts.push(format!("{} {sha}", path.display()));
    }

    pub(crate) fn add_redactions(&mut self, values: impl IntoIterator<Item = String>) {
        self.redactions.extend(values);
    }

    pub(crate) fn fail(&mut self, message: impl Into<String>) {
        self.failed_phase.get_or_insert(self.current_phase);
        self.failures.push(self.redact(&message.into()));
    }

    pub(crate) fn event(&mut self, message: impl AsRef<str>) {
        let line = self.redact(message.as_ref());
        let line: String = line.chars().take(LINE_LIMIT).collect();
        if self.events.len() == EVENT_LIMIT {
            self.events.pop_front();
        }
        self.events.push_back(line.clone());
        if self.live {
            (self.sink)(&format!("[{} / {}] {line}", self.fixture, self.test));
        }
    }

    pub(crate) fn finish(mut self) -> String {
        self.phase("complete");
        let mut out = format!(
            "fixture: {}\ntest: {}\ncase: {}\ncurrent phase: {}\nfailed phase: {}\n",
            self.fixture,
            self.test,
            self.case,
            self.current_phase,
            self.failed_phase.unwrap_or("-")
        );
        out.push_str("phase timings:\n");
        for phase in &self.phases {
            let _ = writeln!(out, "  {}: {:?}", phase.name, phase.duration);
        }
        let _ = writeln!(out, "total: {:?}", self.started.elapsed());
        if !self.artifacts.is_empty() {
            out.push_str("artifacts:\n");
            for value in &self.artifacts {
                let _ = writeln!(out, "  {value}");
            }
        }
        if !self.failures.is_empty() {
            out.push_str("failures (primary first):\n");
            for value in &self.failures {
                let _ = writeln!(out, "  {value}");
            }
        }
        if !self.events.is_empty() {
            out.push_str("recent diagnostics:\n");
            for value in &self.events {
                let _ = writeln!(out, "  {value}");
            }
        }
        self.redact(&out)
    }

    fn redact(&self, value: &str) -> String {
        self.redactions
            .iter()
            .filter(|s| !s.is_empty())
            .fold(value.to_owned(), |text, secret| {
                text.replace(secret, "[REDACTED]")
            })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::sync::Mutex;

    #[test]
    fn ordering_eviction_live_and_redaction_are_deterministic() {
        let output = Arc::new(Mutex::new(Vec::<String>::new()));
        let captured = output.clone();
        let mut report = DiagnosticReport::with_sink(
            "fixture",
            "test",
            Some("case"),
            vec!["secret".into()],
            Arc::new(move |line| captured.lock().unwrap().push(line.into())),
        );
        report.live = true;
        report.phase("validated");
        for index in 0..=EVENT_LIMIT {
            report.event(format!("event {index} secret"));
        }
        report.fail("body secret");
        report.phase("cleaning extensions");
        report.fail("cleanup secret");
        let rendered = report.finish();
        assert!(rendered.find("admitted:").unwrap() < rendered.find("validated:").unwrap());
        assert!(!rendered.contains("event 0 "));
        assert!(!rendered.contains("secret"));
        assert!(
            rendered.find("body [REDACTED]").unwrap()
                < rendered.find("cleanup [REDACTED]").unwrap()
        );
        assert!(
            output
                .lock()
                .unwrap()
                .iter()
                .all(|line| line.starts_with("[fixture / test] ") && !line.contains("secret"))
        );
    }
}
