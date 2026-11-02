//! The JUnit XML a step's test tasks wrote, read as one `TestRun` with a case per test, so a
//! failed Gradle test is named in the evidence like any other case instead of hiding behind its
//! step's "There were failing tests".

use std::fs;
use std::path::{Path, PathBuf};
use std::time::SystemTime;

use anyhow::{Context as _, Result};

use crate::results::{Attempt, AttemptPolicy, Failure, Outcome, TestCase, TestRun};
use crate::skirout::base::harness::v1::test_run::Runner;

/// Every test of the `TEST-*.xml` reports below `root` written at or after `since`, so a test
/// task Gradle found up to date does not repeat an earlier run. Skipped tests are left out: the
/// contract has no outcome for a test that did not run.
pub fn run(
    root: &Path,
    since: SystemTime,
    commit: &str,
    started_at_millis: i64,
) -> Result<TestRun> {
    let mut cases = Vec::new();
    for report in reports(root, since)? {
        let text = fs::read_to_string(&report)
            .with_context(|| format!("cannot read {}", report.display()))?;
        cases.extend(
            parse(&text).with_context(|| format!("{} is not JUnit XML", report.display()))?,
        );
    }
    cases.sort_by(|a, b| a.id.cmp(&b.id));
    Ok(TestRun {
        runner: Runner::Junit,
        commit: commit.to_owned(),
        started_at_millis,
        attempt_policy: AttemptPolicy::Exactly(1),
        cases,
        _unrecognized: None,
    })
}

/// The reports below `root`, skipping the folders no test task writes into.
fn reports(root: &Path, since: SystemTime) -> Result<Vec<PathBuf>> {
    let mut found = Vec::new();
    let mut pending = vec![root.to_owned()];
    while let Some(dir) = pending.pop() {
        let Ok(entries) = fs::read_dir(&dir) else {
            continue;
        };
        for entry in entries {
            let entry = entry?;
            let path = entry.path();
            let name = entry.file_name();
            let name = name.to_string_lossy();
            if entry.file_type()?.is_dir() {
                if !matches!(name.as_ref(), ".git" | ".gradle" | "node_modules" | "src") {
                    pending.push(path);
                }
            } else if name.starts_with("TEST-")
                && name.ends_with(".xml")
                && path
                    .components()
                    .any(|part| part.as_os_str() == "test-results")
                && entry.metadata()?.modified()? >= since
            {
                found.push(path);
            }
        }
    }
    Ok(found)
}

/// The cases of one report: `<classname> > <name>` each, failed with the failure's message and
/// the first frame of the project's own code when the report names one.
fn parse(text: &str) -> Result<Vec<TestCase>> {
    let document = roxmltree::Document::parse(text)?;
    let mut cases = Vec::new();
    for testcase in document
        .descendants()
        .filter(|node| node.has_tag_name("testcase"))
    {
        if testcase
            .children()
            .any(|child| child.has_tag_name("skipped"))
        {
            continue;
        }
        let failure = testcase
            .children()
            .find(|child| child.has_tag_name("failure") || child.has_tag_name("error"));
        let outcome = match failure {
            None => Outcome::Passed,
            Some(failure) => {
                // A failure may carry only its message attribute and no trace.
                let trace = failure.text();
                Outcome::Failed(Box::new(Failure {
                    message: failure
                        .attribute("message")
                        .map(str::to_owned)
                        .or_else(|| {
                            trace
                                .and_then(|trace| trace.lines().next())
                                .map(str::to_owned)
                        })
                        .unwrap_or_else(|| "failed without a message".to_owned()),
                    first_broken: trace
                        .into_iter()
                        .flat_map(str::lines)
                        .map(str::trim)
                        .find(|line| line.starts_with("at com.typewritermc."))
                        .map(|line| line.trim_start_matches("at ").to_owned()),
                    ..Failure::default()
                }))
            }
        };
        let seconds: f64 = testcase
            .attribute("time")
            .and_then(|time| time.parse().ok())
            .unwrap_or(0.0);
        cases.push(TestCase {
            id: format!(
                "{} > {}",
                testcase.attribute("classname").unwrap_or_default(),
                testcase.attribute("name").unwrap_or_default()
            ),
            attempts: vec![Attempt {
                outcome,
                duration_millis: (seconds * 1000.0).round() as i64,
                ..Attempt::default()
            }],
            ..TestCase::default()
        });
    }
    Ok(cases)
}

#[cfg(test)]
mod tests {
    use std::time::Duration;

    use super::*;
    use crate::test_support::TempRoot;

    const REPORT: &str = r#"<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="suite_com.typewritermc.realm.RealmTest" tests="3" skipped="1" failures="1">
  <testcase name="a commit is saved" classname="suite_com.typewritermc.realm.RealmTest" time="0.25"/>
  <testcase name="a cycle is refused" classname="suite_com.typewritermc.realm.RealmTest" time="1.5">
    <failure message="expected relation_cycle but was nothing" type="java.lang.AssertionError">java.lang.AssertionError: expected relation_cycle but was nothing
	at io.kotest.matchers.ShouldKt.shouldBe(Should.kt:12)
	at com.typewritermc.realm.RealmTest.cycle(RealmTest.kt:40)
</failure>
  </testcase>
  <testcase name="a later feature" classname="suite_com.typewritermc.realm.RealmTest" time="0">
    <skipped/>
  </testcase>
</testsuite>"#;

    #[test]
    fn a_failed_test_is_named_with_its_message_and_first_own_frame() {
        let root = TempRoot::new();
        root.write("realm/build/test-results/test/TEST-RealmTest.xml", REPORT);

        let run = run(&root.path(""), SystemTime::UNIX_EPOCH, "abc", 0).unwrap();

        let ids: Vec<&str> = run.cases.iter().map(|case| case.id.as_str()).collect();
        assert_eq!(
            ids,
            [
                "suite_com.typewritermc.realm.RealmTest > a commit is saved",
                "suite_com.typewritermc.realm.RealmTest > a cycle is refused",
            ]
        );
        assert_eq!(run.cases[0].attempts[0].outcome, Outcome::Passed);
        let Outcome::Failed(failure) = &run.cases[1].attempts[0].outcome else {
            panic!("the refused cycle test should have failed");
        };
        assert_eq!(failure.message, "expected relation_cycle but was nothing");
        assert_eq!(
            failure.first_broken.as_deref(),
            Some("com.typewritermc.realm.RealmTest.cycle(RealmTest.kt:40)")
        );
        assert_eq!(run.cases[1].attempts[0].duration_millis, 1500);
    }

    #[test]
    fn reports_from_before_the_step_are_not_its_tests() {
        let root = TempRoot::new();
        root.write("realm/build/test-results/test/TEST-RealmTest.xml", REPORT);

        let later = SystemTime::now() + Duration::from_secs(60);
        assert!(
            run(&root.path(""), later, "abc", 0)
                .unwrap()
                .cases
                .is_empty()
        );
    }
}
