//! The handler time each event cost in a run, read from the metrics the stack's collector kept:
//! every engine records each handler run in the histogram `typewriter.event.handler.duration`
//! (seconds, per `typewriter.event`), so the game run reports the average tick handler time on
//! real Paper.

use std::collections::BTreeMap;
use std::fs;
use std::io::Write;
use std::path::Path;

use anyhow::{Context as _, Result};
use serde_json::Value;

/// The histogram every engine records each handler run in.
const HANDLER_DURATION: &str = "typewriter.event.handler.duration";
/// The attribute naming the event a handler ran for.
const EVENT: &str = "typewriter.event";

/// What the handlers of one event cost over a run, across every engine.
#[derive(Debug, PartialEq)]
pub struct HandlerCost {
    pub event: String,
    pub runs: u64,
    /// The average time of one run, in seconds.
    pub average: f64,
}

/// The cost per event in the collector's metrics file at `path` (OTLP JSON export requests, one
/// per line), sorted by event; none when the collector received no metric.
///
/// A point is cumulative from its series' start, so each series (one engine's resource, one
/// event, one start) counts with its latest point only, and the series of every engine add up.
pub fn read(path: &Path) -> Result<Vec<HandlerCost>> {
    // A stack whose collector received no metric never created the file.
    let text = match fs::read_to_string(path) {
        Ok(text) => text,
        Err(error) if error.kind() == std::io::ErrorKind::NotFound => String::new(),
        Err(error) => {
            return Err(error).with_context(|| format!("cannot read {}", path.display()));
        }
    };
    // (resource, event, start) -> (time, count, sum) of the latest point.
    let mut latest: BTreeMap<(String, String, String), (u64, u64, f64)> = BTreeMap::new();
    for line in text.lines().filter(|line| !line.trim().is_empty()) {
        let request: Value = serde_json::from_str(line)
            .with_context(|| format!("{} is not OTLP JSON", path.display()))?;
        for resource in array(&request, "resourceMetrics") {
            let identity = resource
                .get("resource")
                .map(Value::to_string)
                .context("an OTLP metrics export without its resource")?;
            for scope in array(resource, "scopeMetrics") {
                for metric in array(scope, "metrics") {
                    if metric.get("name").and_then(Value::as_str) != Some(HANDLER_DURATION) {
                        continue;
                    }
                    let histogram = metric
                        .get("histogram")
                        .with_context(|| format!("{HANDLER_DURATION} is not a histogram"))?;
                    for point in array(histogram, "dataPoints") {
                        let Point {
                            event,
                            start,
                            time,
                            count,
                            sum,
                        } = Point::read(point)?;
                        let series = latest
                            .entry((identity.clone(), event, start))
                            .or_insert((time, count, sum));
                        if time >= series.0 {
                            *series = (time, count, sum);
                        }
                    }
                }
            }
        }
    }
    let mut totals: BTreeMap<String, (u64, f64)> = BTreeMap::new();
    for ((_, event, _), (_, count, sum)) in latest {
        let total = totals.entry(event).or_default();
        total.0 += count;
        total.1 += sum;
    }
    Ok(totals
        .into_iter()
        .filter(|(_, (runs, _))| *runs > 0)
        .map(|(event, (runs, sum))| HandlerCost {
            event,
            runs,
            average: sum / runs as f64,
        })
        .collect())
}

/// Writes one line per event: its average handler time and how many runs it averages.
pub fn report(costs: &[HandlerCost], out: &mut dyn Write) -> Result<()> {
    for cost in costs {
        writeln!(
            out,
            "game: handler time of {}: {} µs average over {} runs",
            cost.event,
            (cost.average * 1e7).round() / 10.0,
            cost.runs
        )?;
    }
    Ok(())
}

/// One cumulative point of the handler duration histogram.
struct Point {
    event: String,
    start: String,
    time: u64,
    count: u64,
    sum: f64,
}

impl Point {
    fn read(point: &Value) -> Result<Self> {
        let field = |key: &str| {
            point
                .get(key)
                .with_context(|| format!("a {HANDLER_DURATION} point without {key}"))
        };
        Ok(Self {
            event: event_of(point)
                .with_context(|| format!("a {HANDLER_DURATION} point without {EVENT}"))?,
            start: field("startTimeUnixNano")?.to_string(),
            time: number(field("timeUnixNano")?)?,
            count: number(field("count")?)?,
            sum: field("sum")?
                .as_f64()
                .with_context(|| format!("a {HANDLER_DURATION} sum that is no number"))?,
        })
    }
}

/// The members of the array at `key`, or none.
fn array<'a>(value: &'a Value, key: &str) -> impl Iterator<Item = &'a Value> {
    value
        .get(key)
        .and_then(Value::as_array)
        .into_iter()
        .flatten()
}

/// The event a point's attributes name.
fn event_of(point: &Value) -> Option<String> {
    array(point, "attributes")
        .find(|attribute| attribute.get("key").and_then(Value::as_str) == Some(EVENT))?
        .get("value")?
        .get("stringValue")?
        .as_str()
        .map(str::to_owned)
}

/// An OTLP JSON 64 bit integer, which the collector writes as a string.
fn number(value: &Value) -> Result<u64> {
    match value {
        Value::String(text) => text
            .parse()
            .with_context(|| format!("{text} is no OTLP integer")),
        other => other
            .as_u64()
            .with_context(|| format!("{other} is no OTLP integer")),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::otlp_handler_durations;

    #[test]
    fn each_engine_counts_with_its_last_cumulative_point_and_the_engines_add_up() {
        let dir = tempfile::tempdir().unwrap();
        let metrics = dir.path().join("metrics.jsonl");
        let lines = [
            otlp_handler_durations("paper-0", 1, 10, &[("Tick", 2, 0.000_02)]),
            otlp_handler_durations(
                "paper-0",
                1,
                20,
                &[("Tick", 4, 0.000_04), ("PlayerJoin", 1, 0.001)],
            ),
            otlp_handler_durations("paper-1", 5, 30, &[("Tick", 1, 0.000_01)]),
        ];
        std::fs::write(
            &metrics,
            lines.map(|line| line.to_string()).join("\n") + "\n",
        )
        .unwrap();

        let costs = read(&metrics).unwrap();

        assert_eq!(costs.len(), 2);
        assert_eq!(costs[0].event, "PlayerJoin");
        assert_eq!(costs[0].runs, 1);
        assert!((costs[0].average - 0.001).abs() < 1e-12);
        assert_eq!(costs[1].event, "Tick");
        assert_eq!(costs[1].runs, 5);
        assert!((costs[1].average - 0.000_01).abs() < 1e-12);
    }

    #[test]
    fn a_run_whose_collector_received_no_metric_costs_nothing() {
        let dir = tempfile::tempdir().unwrap();
        assert_eq!(read(&dir.path().join("metrics.jsonl")).unwrap(), []);
    }

    #[test]
    fn the_report_names_each_event_s_average_in_microseconds_and_its_runs() {
        let mut out = Vec::new();
        report(
            &[HandlerCost {
                event: "Tick".into(),
                runs: 120,
                average: 0.000_012_5,
            }],
            &mut out,
        )
        .unwrap();
        assert_eq!(
            String::from_utf8(out).unwrap(),
            "game: handler time of Tick: 12.5 µs average over 120 runs\n"
        );
    }
}
