//! The captions of a recording. A scenario reports what it did and where it tapped; they are drawn
//! afterwards in a strip below the recorded screen, so the app on video is exactly the app under
//! test, and a reader sees who acts, what is being done and how it ended.

use std::fmt::Write as _;
use std::fs;
use std::path::Path;

use anyhow::{Context as _, Result};

use super::SCREEN;
use crate::skirout::base::harness::v1::test_run::{Attempt, Outcome, Span};

/// The strip below the screen, with one line for the scenario and one for the step.
const STRIP: u32 = 72;
const FONT_SIZE: u32 = 24;
/// As many characters as a line of [`FONT_SIZE`] holds across [`SCREEN`].
const LINE: usize = 84;
/// How long the last frame stays, with the result on it.
const RESULT_SECONDS: f64 = 2.5;
const TAP_SECONDS: f64 = 0.6;
const TAP_BOX: i32 = 36;
const STRIP_COLOR: &str = "0x111827";
const TEXT_COLOR: &str = "white";
const STEP_COLOR: &str = "0xfacc15";
const PROVEN_COLOR: &str = "0x4ade80";
const BROKEN_COLOR: &str = "0xf87171";

/// A line of the strip while `from <= t < to`, in seconds into the clip.
#[derive(Debug, PartialEq)]
struct Shown {
    from: f64,
    to: f64,
    text: String,
}

/// The ffmpeg filter that holds the last frame and draws the strip, its text files in `scratch`.
pub(super) fn filter(scratch: &Path, id: &str, span: &Span, attempt: &Attempt) -> Result<String> {
    let font = std::env::var("EVIDENCE_FONT").context(
        "EVIDENCE_FONT names the captions' font; it comes from `devenv --profile e2e shell`",
    )?;
    let length = seconds(span.end_millis - span.start_millis);
    let (width, height) = SCREEN;
    let mut filter = format!(
        "tpad=stop_mode=clone:stop_duration={RESULT_SECONDS},pad={width}:{}:0:0:color={STRIP_COLOR}",
        height + STRIP
    );
    let mut text = |name: String, line: &str, color: &str, row: u32, when: Option<(f64, f64)>| {
        let path = scratch.join(name);
        fs::write(&path, line).with_context(|| format!("cannot write {}", path.display()))?;
        let enable = when.map_or_else(String::new, |(from, to)| {
            format!(":enable='between(t,{from:.2},{to:.2})'")
        });
        let _ = write!(
            filter,
            ",drawtext=fontfile='{font}':expansion=none:textfile='{}':x=16:y={}:fontsize={FONT_SIZE}:fontcolor={color}{enable}",
            path.display(),
            height + 6 + row * (FONT_SIZE + 10),
        );
        anyhow::Ok(())
    };
    text("title".to_owned(), &clamp(id), TEXT_COLOR, 0, None)?;
    for (index, shown) in steps(attempt, span, length).iter().enumerate() {
        text(
            format!("step{index}"),
            &shown.text,
            STEP_COLOR,
            1,
            Some((shown.from, shown.to)),
        )?;
    }
    let (result, color) = result(&attempt.outcome);
    text(
        "result".to_owned(),
        &result,
        color,
        1,
        Some((length, length + RESULT_SECONDS + 1.0)),
    )?;
    for (x, y, from) in taps(attempt, span, length) {
        let _ = write!(
            filter,
            ",drawbox=x={x}:y={y}:w={TAP_BOX}:h={TAP_BOX}:color={STEP_COLOR}:t=4:enable='between(t,{from:.2},{:.2})'",
            from + TAP_SECONDS
        );
    }
    Ok(filter)
}

/// Each step, from when it started until the next one starts or the recorded part ends, as "who,
/// how far, what". Steps outside the recorded part are not shown, but still count.
fn steps(attempt: &Attempt, span: &Span, length: f64) -> Vec<Shown> {
    let total = attempt.steps.len();
    let start = |at: i64| seconds(at - span.start_millis).max(0.0);
    attempt
        .steps
        .iter()
        .enumerate()
        .map(|(index, step)| Shown {
            from: start(step.at_millis),
            to: attempt
                .steps
                .get(index + 1)
                .map_or(length, |next| start(next.at_millis)),
            text: clamp(&format!(
                "{}   step {} of {total}   {}",
                step.actor.as_deref().unwrap_or("nobody signed in"),
                index + 1,
                step.says,
            )),
        })
        .filter(|shown| shown.from < length)
        .collect()
}

/// The top left corner and start of each tap's marker, the marker kept on the screen.
fn taps(attempt: &Attempt, span: &Span, length: f64) -> Vec<(i32, i32, f64)> {
    let inside = |value: i32, size: u32| (value - TAP_BOX / 2).clamp(0, size as i32 - TAP_BOX);
    attempt
        .taps
        .iter()
        .map(|tap| {
            (
                inside(tap.x, SCREEN.0),
                inside(tap.y, SCREEN.1),
                seconds(tap.at_millis - span.start_millis),
            )
        })
        .filter(|(_, _, from)| (0.0..length).contains(from))
        .collect()
}

fn result(outcome: &Outcome) -> (String, &'static str) {
    match outcome {
        Outcome::Passed => ("PROVEN".to_owned(), PROVEN_COLOR),
        Outcome::Failed(failure) => {
            let message = failure
                .message
                .split_once('\n')
                .map_or(failure.message.as_str(), |(first, _)| first);
            (clamp(&format!("BROKEN   {message}")), BROKEN_COLOR)
        }
        Outcome::Unknown(_) => ("NO RESULT".to_owned(), BROKEN_COLOR),
    }
}

/// `text` shortened to one line of the strip.
fn clamp(text: &str) -> String {
    if text.chars().count() <= LINE {
        return text.to_owned();
    }
    let kept: String = text.chars().take(LINE - 3).collect();
    format!("{kept}...")
}

fn seconds(millis: i64) -> f64 {
    millis as f64 / 1000.0
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::skirout::base::harness::v1::test_run::Tap;
    use crate::test_support::{failed, passed_attempt, scenario_step};

    #[test]
    fn a_step_stays_on_screen_until_the_next_one_and_names_who_acts() {
        let mut attempt = passed_attempt((1_000, 11_000));
        attempt.steps = vec![
            scenario_step(2_000, None, "open the panel elsewhere"),
            scenario_step(5_000, Some("alan"), "press \"Join\""),
        ];
        let span = attempt.span.clone().unwrap();
        assert_eq!(
            steps(&attempt, &span, 10.0),
            [
                Shown {
                    from: 1.0,
                    to: 4.0,
                    text: "nobody signed in   step 1 of 2   open the panel elsewhere".to_owned(),
                },
                Shown {
                    from: 4.0,
                    to: 10.0,
                    text: "alan   step 2 of 2   press \"Join\"".to_owned(),
                },
            ]
        );
    }

    #[test]
    fn a_tap_marker_is_centred_on_the_tap_and_stays_on_the_screen() {
        let mut attempt = passed_attempt((0, 10_000));
        attempt.taps = vec![
            Tap {
                at_millis: 1_000,
                x: 640,
                y: 360,
                _unrecognized: None,
            },
            Tap {
                at_millis: 2_000,
                x: 0,
                y: 9_999,
                _unrecognized: None,
            },
        ];
        let span = attempt.span.clone().unwrap();
        assert_eq!(
            taps(&attempt, &span, 10.0),
            [(622, 342, 1.0), (0, 684, 2.0)]
        );
    }

    #[test]
    fn the_result_says_what_broke_on_one_line() {
        let (text, _) = result(&failed("the realm never appeared\nat line 4"));
        assert_eq!(text, "BROKEN   the realm never appeared");
    }

    #[test]
    fn a_long_line_is_cut_to_fit_the_strip() {
        let long = "x".repeat(LINE + 20);
        assert_eq!(clamp(&long).chars().count(), LINE);
    }
}
