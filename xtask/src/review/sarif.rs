//! The findings as one SARIF log for GitHub code scanning, which shows each result as an
//! annotation on the changed line of the pull request and drops it once fixed. Every result
//! carries the fix hint, the same text an agent reads locally.

use serde_json::{Value, json};

use super::change::Change;
use super::detectors::DETECTORS;
use super::report::{ChangeReport, Severity};

const SCHEMA: &str = "https://json.schemastore.org/sarif-2.1.0.json";

/// One run for the gating detectors, limited to lines the change added or rewrote. Code scanning
/// shows a reader only what they must fix; flags stay in the reviewer's report.
pub fn to_sarif(report: &ChangeReport, change: &Change) -> Value {
    let rules: Vec<Value> = DETECTORS
        .iter()
        .filter(|detector| detector.gate)
        .map(|detector| json!({ "id": detector.name, "name": detector.name }))
        .collect();
    let results: Vec<Value> = report
        .findings
        .iter()
        .filter(|finding| {
            finding.severity == Severity::Gate && change.touches(&finding.file, finding.line)
        })
        .map(|finding| {
            json!({
                "ruleId": finding.detector,
                "level": "error",
                "message": { "text": format!("{}\nFix: {}", finding.message, finding.fix) },
                "locations": [{
                    "physicalLocation": {
                        "artifactLocation": { "uri": finding.file.to_string_lossy() },
                        "region": { "startLine": finding.line },
                    },
                }],
                "properties": { "fix": finding.fix },
            })
        })
        .collect();
    json!({
        "$schema": SCHEMA,
        "version": "2.1.0",
        "runs": [{
            "tool": { "driver": { "name": "typewriter-detectors", "rules": rules } },
            "results": results,
        }],
    })
}
