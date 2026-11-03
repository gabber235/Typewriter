//! Wraps an end to end run. On Linux the command runs on a virtual display that ffmpeg records,
//! and the recording is cut into one clip and one looping preview per case from the spans in the
//! `TestRun`. On macOS the command and its companions run unrecorded; the runner's screenshots
//! still work.

use std::fs::{self, File};
use std::io::{self, BufRead as _, BufReader, PipeReader, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus, Stdio};
use std::sync::mpsc::{self, Receiver};
use std::sync::{Arc, Mutex};
use std::thread::{self, sleep};
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result, bail};

use crate::e2e::failures::rfc3339;
use crate::process::{Group, Supervisor, Unsupervised};
use crate::results::{self, TestRun};
use crate::skirout::base::harness::v1::test_run::{Artifact, ArtifactKind, Attempt};
use crate::{CommandExt, Context};

/// The file the runner writes inside the evidence folder.
const RUN_FILE: &str = "test_run.json";
/// The virtual display: the panel's own window size (panel/linux/runner/my_application.cc), so a
/// recording holds only the panel.
pub(crate) const SCREEN: (u32, u32) = (1280, 720);
/// What a program's window draws beside the page it shows, when the page cannot fill the window.
/// The display grows by this much and the recording keeps only the page.
#[derive(Clone, Copy, Default)]
pub struct WindowMargins {
    pub right: u32,
    pub top: u32,
}

/// GitHub's image proxy refuses files over about 5 MB; previews stay well below.
const PREVIEW_LIMIT: u64 = 3 * 1024 * 1024;
/// How long the output log waits for the pipes to drain after the command exited.
const TEE_DRAIN: Duration = Duration::from_secs(10);

/// A command to record, with the programs it needs on the same display.
pub struct Recorded {
    pub command: Vec<String>,
    pub companions: Vec<Vec<String>>,
    /// False when only the display is needed, because the program records itself.
    pub video: bool,
    pub margins: WindowMargins,
    /// Where the command runs, relative to the repository root.
    pub cwd: String,
    pub env: Vec<(String, String)>,
    /// Variables the command must not inherit.
    pub env_remove: Vec<String>,
    /// Where the command's output is kept too, each line stamped with its arrival time.
    pub log: Option<PathBuf>,
}

impl Recorded {
    /// `command`, run from the repository root and recorded.
    pub fn video(command: Vec<String>) -> Self {
        Self {
            command,
            companions: Vec::new(),
            video: true,
            margins: WindowMargins::default(),
            cwd: ".".into(),
            env: Vec::new(),
            env_remove: Vec::new(),
            log: None,
        }
    }

    /// Runs `companion` next to the command, on the same display, for as long as it runs.
    pub fn with(mut self, companion: Vec<String>) -> Self {
        self.companions.push(companion);
        self
    }

    /// Records only the page inside a window that draws `margins` beside it.
    pub fn with_margins(mut self, margins: WindowMargins) -> Self {
        self.margins = margins;
        self
    }

    /// Runs the command from `cwd`, relative to the repository root.
    pub fn in_dir(mut self, cwd: &str) -> Self {
        self.cwd = cwd.into();
        self
    }

    pub fn env(mut self, key: &str, value: impl Into<String>) -> Self {
        self.env.push((key.into(), value.into()));
        self
    }

    pub fn env_remove(mut self, key: &str) -> Self {
        self.env_remove.push(key.into());
        self
    }

    /// Prints the command's output as before and appends each line to `log`, stamped with its
    /// arrival time in the format failure folders cut logs by.
    pub fn log_to(mut self, log: PathBuf) -> Self {
        self.log = Some(log);
        self
    }
}

/// Runs `recorded` and returns the `TestRun` it wrote to `out`. Clips are added to the cases'
/// artifacts as paths relative to `out`, and the run file is rewritten with them. A failing
/// command still yields its clips; the error is returned afterwards.
pub fn record(ctx: &Context, out: &Path, recorded: Recorded) -> Result<TestRun> {
    let command = recorded.command.join(" ");
    let (run, status) = record_with(ctx, out, recorded, &mut Unsupervised::with_interrupts())?;
    if !status.success() {
        bail!("{command} failed with {status}");
    }
    Ok(run)
}

/// [`record`], with `supervisor` starting the command and every helper process, for example a
/// stack that registers them. Returns the command's exit status with its `TestRun`; only a
/// command that wrote no run file is an error.
pub fn record_with(
    ctx: &Context,
    out: &Path,
    recorded: Recorded,
    supervisor: &mut dyn Supervisor,
) -> Result<(TestRun, ExitStatus)> {
    fs::create_dir_all(out).with_context(|| format!("cannot create {}", out.display()))?;
    let [program, args @ ..] = recorded.command.as_slice() else {
        bail!("nothing to record");
    };
    let mut command = ctx.tool(&recorded.cwd, program, &[]);
    command.args(args).envs(recorded.env.iter().cloned());
    for key in &recorded.env_remove {
        command.env_remove(key);
    }
    let tee = recorded
        .log
        .as_deref()
        .map(|log| Tee::attach(&mut command, log))
        .transpose()?;
    if !cfg!(target_os = "linux") {
        let _companions = recorded
            .companions
            .iter()
            .map(|companion| companion_spawn(ctx, supervisor, companion, None))
            .collect::<Result<Vec<_>>>()?;
        let status = supervisor.run(&mut command)?;
        if let Some(tee) = tee {
            tee.finish(&mut command);
        }
        return Ok((read_run(out, &command, status)?, status));
    }
    let display = Xvfb::start(supervisor, recorded.margins)?;
    let _companions = recorded
        .companions
        .iter()
        .map(|companion| companion_spawn(ctx, supervisor, companion, Some(&display)))
        .collect::<Result<Vec<_>>>()?;
    let video = out.join("run.mp4");
    let ffmpeg = recorded
        .video
        .then(|| Ffmpeg::x11grab(supervisor, &display, recorded.margins, &video))
        .transpose()?;
    command.env("DISPLAY", &display.name);
    let status = supervisor.run(&mut command)?;
    if let Some(tee) = tee {
        tee.finish(&mut command);
    }
    // The suite's run is written only when every drive returns, so a failed recorder must not
    // end the drive: its cases are kept and only the clips are missing.
    let started = match ffmpeg.map(Ffmpeg::finish).transpose() {
        Ok(started) => started,
        Err(error) => {
            eprintln!("xtask: the recording failed, so the run has no clips: {error:#}");
            None
        }
    };
    let mut test_run = read_run(out, &command, status)?;
    if let Some(started) = started {
        for case in &mut test_run.cases {
            for attempt in &mut case.attempts {
                // A clip that cannot be cut loses that clip, never the run's results.
                if let Err(error) = cut(out, &video, started, &case.id, attempt) {
                    eprintln!("xtask: no clip for {}: {error:#}", case.id);
                }
            }
        }
        results::write(&test_run, &out.join(RUN_FILE))?;
    }
    Ok((test_run, status))
}

/// A command's stdout and stderr, each printed to its own stream as it arrives and appended,
/// line by line with an arrival stamp, to one log file.
struct Tee {
    done: Receiver<()>,
    streams: usize,
}

impl Tee {
    /// Pipes `command`'s output through a reader thread per stream into `log`.
    fn attach(command: &mut Command, log: &Path) -> Result<Self> {
        let file = File::create(log).with_context(|| format!("cannot create {}", log.display()))?;
        let file = Arc::new(Mutex::new(file));
        let (sender, done) = mpsc::channel();
        let (stdout, stdout_writer) = io::pipe()?;
        let (stderr, stderr_writer) = io::pipe()?;
        command.stdout(stdout_writer).stderr(stderr_writer);
        let streams: [(PipeReader, Box<dyn Write + Send>); 2] = [
            (stdout, Box::new(io::stdout())),
            (stderr, Box::new(io::stderr())),
        ];
        for (reader, mut echo) in streams {
            let (file, sender) = (Arc::clone(&file), sender.clone());
            thread::spawn(move || {
                let mut reader = BufReader::new(reader);
                let mut line = Vec::new();
                while reader
                    .read_until(b'\n', &mut line)
                    .is_ok_and(|read| read > 0)
                {
                    let _ = echo.write_all(&line).and_then(|()| echo.flush());
                    let stamp = rfc3339(millis(SystemTime::now()));
                    let text = String::from_utf8_lossy(&line);
                    if let Ok(mut file) = file.lock() {
                        let _ = writeln!(file, "{stamp} {}", text.trim_end_matches(['\r', '\n']));
                    }
                    line.clear();
                }
                let _ = sender.send(());
            });
        }
        Ok(Self { done, streams: 2 })
    }

    /// Waits for the output the exited `command` left in its pipes. The command holds its end of
    /// the pipes until its output is redirected again; a process it left behind that still holds
    /// them is not waited for longer than [`TEE_DRAIN`].
    fn finish(self, command: &mut Command) {
        command.stdout(Stdio::null()).stderr(Stdio::null());
        let deadline = Instant::now() + TEE_DRAIN;
        for _ in 0..self.streams {
            let left = deadline.saturating_duration_since(Instant::now());
            if self.done.recv_timeout(left).is_err() {
                eprintln!("evidence: the command's output log may miss its last lines");
                return;
            }
        }
    }
}

/// The run file, or an error when the command failed before writing one.
fn read_run(out: &Path, command: &Command, status: ExitStatus) -> Result<TestRun> {
    let path = out.join(RUN_FILE);
    if !status.success() && !path.exists() {
        bail!(
            "{} failed with {status} and wrote no {}",
            crate::display(command),
            path.display()
        );
    }
    results::read(&path)
}

/// One captioned clip and one looping preview (640 px wide, 8 fps, under [`PREVIEW_LIMIT`]) for a
/// case with a span. Spans are Unix milliseconds, so the offset into the recording is the span minus
/// `started`. The preview sits next to the clip as `<name>.webp`.
fn cut(out: &Path, video: &Path, started: i64, id: &str, attempt: &mut Attempt) -> Result<()> {
    let Some(span) = &attempt.span else {
        return Ok(());
    };
    // A case that failed before it did anything has no moment to show.
    if span.end_millis <= span.start_millis {
        return Ok(());
    }
    let from = seconds(span.start_millis - started);
    let to = seconds(span.end_millis - started);
    let name = file_name(id);
    let clip = PathBuf::from("clips").join(format!("{name}.mp4"));
    let preview = out.join("clips").join(format!("{name}.webp"));
    fs::create_dir_all(out.join("clips"))?;
    let scratch = out.join("captions").join(&name);
    fs::create_dir_all(&scratch)?;
    let captions = super::captions::filter(&scratch, id, span, attempt)?;
    let input = ["-ss", &from, "-to", &to, "-i"];
    ffmpeg()
        .args(input)
        .arg(video)
        .args(["-vf", &captions])
        .args([
            "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p",
        ])
        .arg(out.join(&clip))
        .run()?;
    // Lower the quality until the preview fits; a case too long to fit keeps only its clip.
    for quality in ["60", "35", "15"] {
        ffmpeg()
            .args(input)
            .arg(video)
            .args(["-vf", &format!("{captions},fps=8,scale=640:-2")])
            .args(["-loop", "0", "-an"])
            .args(["-c:v", "libwebp", "-quality", quality])
            .arg(&preview)
            .run()?;
        if fs::metadata(&preview)?.len() <= PREVIEW_LIMIT {
            break;
        }
        fs::remove_file(&preview)?;
    }
    fs::remove_dir_all(&scratch)?;
    if !preview.exists() {
        eprintln!(
            "{}: preview too large for GitHub; only the clip is kept",
            id
        );
    }
    attempt.artifacts.push(Artifact {
        kind: ArtifactKind::Clip,
        path: clip.to_string_lossy().into_owned(),
        _unrecognized: None,
    });
    Ok(())
}

/// A virtual X display, stopped on drop.
struct Xvfb {
    _group: Group,
    name: String,
}

impl Xvfb {
    /// Starts on the first free display number from :99 and waits for its socket.
    fn start(supervisor: &mut dyn Supervisor, margins: WindowMargins) -> Result<Self> {
        let number = (99..200)
            .find(|n| !Path::new(&format!("/tmp/.X11-unix/X{n}")).exists())
            .context("no free X display number")?;
        let name = format!(":{number}");
        let screen = format!("{}x{}x24", SCREEN.0 + margins.right, SCREEN.1 + margins.top);
        let group = supervisor
            .spawn(
                Command::new("Xvfb")
                    .args([
                        &name,
                        "-screen",
                        "0",
                        &screen,
                        "+extension",
                        "GLX",
                        "-nolisten",
                        "tcp",
                    ])
                    .stdout(Stdio::null()),
            )
            .context("Xvfb, the recorder and the browser come from `devenv --profile e2e shell`")?;
        let display = Self {
            _group: group,
            name,
        };
        let socket = PathBuf::from(format!("/tmp/.X11-unix/X{number}"));
        let deadline = Instant::now() + Duration::from_secs(10);
        while !socket.exists() {
            if Instant::now() > deadline {
                bail!("Xvfb did not open display {}", display.name);
            }
            sleep(Duration::from_millis(100));
        }
        Ok(display)
    }
}

/// Starts `line`, a program the command needs running next to it, on `display` when there is
/// one. It is stopped when the returned group drops.
fn companion_spawn(
    ctx: &Context,
    supervisor: &mut dyn Supervisor,
    line: &[String],
    display: Option<&Xvfb>,
) -> Result<Group> {
    let [program, args @ ..] = line else {
        bail!("empty companion command");
    };
    let mut command = ctx.tool(".", program, &[]);
    command.args(args);
    if let Some(display) = display {
        command.env("DISPLAY", &display.name);
    }
    supervisor.spawn(&mut command)
}

/// ffmpeg recording a display.
struct Ffmpeg {
    group: Group,
    log: PathBuf,
}

impl Ffmpeg {
    fn x11grab(
        supervisor: &mut dyn Supervisor,
        display: &Xvfb,
        margins: WindowMargins,
        video: &Path,
    ) -> Result<Self> {
        let size = format!("{}x{}", SCREEN.0, SCREEN.1);
        let log = video.with_extension("log");
        let stderr = File::create(&log)?;
        let group = supervisor.spawn(
            ffmpeg()
                // The input line of this log holds the first frame's time.
                .args(["-loglevel", "info"])
                .args([
                    "-f",
                    "x11grab",
                    // Nothing moves the pointer, so it would only sit in the frame's center.
                    "-draw_mouse",
                    "0",
                    "-video_size",
                    &size,
                    "-framerate",
                    "15",
                    "-i",
                ])
                .arg(format!("{}+0,{}", display.name, margins.top))
                .args([
                    "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p",
                ])
                .arg(video)
                .stdin(Stdio::null())
                .stderr(stderr),
        )?;
        Ok(Self { group, log })
    }

    /// Stops with SIGINT and waits, so ffmpeg writes the index and the file plays. Returns the
    /// first frame's time in Unix milliseconds, which is some time after ffmpeg started.
    fn finish(mut self) -> Result<i64> {
        Command::new("kill")
            .args(["-INT", &self.group.id().to_string()])
            .run()?;
        let status = self.group.child().wait()?;
        // ffmpeg exits with 255 after SIGINT once the file is finalized.
        if !status.success() && status.code() != Some(255) {
            bail!("ffmpeg failed with {status}");
        }
        first_frame(&fs::read_to_string(&self.log)?)
    }
}

/// The first frame's time in Unix milliseconds, from the `start:` of ffmpeg's input line.
fn first_frame(log: &str) -> Result<i64> {
    let start = log
        .split_once(", start: ")
        .and_then(|(_, rest)| rest.split(',').next())
        .context("ffmpeg's log names no start time")?;
    let seconds: f64 = start
        .trim()
        .parse()
        .with_context(|| format!("ffmpeg's start time {start:?}"))?;
    Ok((seconds * 1000.0).round() as i64)
}

fn ffmpeg() -> Command {
    let mut command = Command::new("ffmpeg");
    command.args(["-y", "-loglevel", "error"]);
    command
}

fn millis(time: SystemTime) -> i64 {
    time.duration_since(UNIX_EPOCH)
        .map_or(0, |since| since.as_millis() as i64)
}

/// Milliseconds as ffmpeg's seconds, never before the recording started.
fn seconds(millis: i64) -> String {
    format!("{:.3}", millis.max(0) as f64 / 1000.0)
}

/// A case id as a file name that works in a URL.
pub(crate) fn file_name(id: &str) -> String {
    id.chars()
        .map(|c| {
            if c.is_ascii_alphanumeric() || matches!(c, '.' | '-' | '_') {
                c
            } else {
                '_'
            }
        })
        .collect()
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::skirout::base::harness::v1::test_run::Span;

    #[test]
    fn the_first_frame_time_comes_from_ffmpegs_input_line() {
        let log = "Input #0, x11grab, from ':9':\n  Duration: N/A, start: 1793657724.941246, bitrate: 30720 kb/s\n";

        assert_eq!(first_frame(log).unwrap(), 1793657724941);
    }

    #[test]
    fn a_case_that_took_no_time_has_no_clip() {
        let out = tempfile::tempdir().unwrap();
        let mut attempt = Attempt {
            span: Some(Span {
                start_millis: 5,
                end_millis: 5,
                ..Span::default()
            }),
            ..Attempt::default()
        };

        cut(
            out.path(),
            &out.path().join("none.mp4"),
            0,
            "a",
            &mut attempt,
        )
        .unwrap();

        assert!(attempt.artifacts.is_empty());
    }

    #[test]
    fn a_log_without_a_start_time_fails_instead_of_guessing() {
        assert!(first_frame("ffmpeg version 8\n").is_err());
    }
}
