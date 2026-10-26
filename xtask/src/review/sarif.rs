//! The findings as one SARIF log for GitHub code scanning, which shows each result as an
//! annotation on the changed line of the pull request and drops it once fixed. Every result
//! carries the fix hint, the same text an agent reads locally.

use serde_json::{Value, json};

use super::change::Change;
use super::detectors::DETECTORS;
use super::report::{ChangeReport, Severity};

const SCHEMA: &str = "https://json.schemastore.org/sarif-2.1.0.json";

/// One run for the xtask detectors, limited to lines the change added or rewrote.
pub fn to_sarif(report: &ChangeReport, change: &Change) -> Value {
    let rules: Vec<Value> = DETECTORS
        .iter()
        .map(|detector| detector.name)
        .chain(report.deep.is_some().then_some("deep"))
        .map(|name| json!({ "id": name, "name": name }))
        .collect();
    let results: Vec<Value> = report
        .findings
        .iter()
        .filter(|finding| change.touches(&finding.file, finding.line))
        .map(|finding| {
            json!({
                "ruleId": finding.detector,
                "level": match finding.severity {
                    Severity::Gate => "error",
                    Severity::Flag => "warning",
                },
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
