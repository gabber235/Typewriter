//! Wraps an end to end run. On Linux the command runs on a virtual display that ffmpeg records,
//! and the recording is cut into one clip and one looping preview per case from the spans in the
//! `TestRun`. On macOS the command and its companions run unrecorded; the runner's screenshots
//! still work.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus, Stdio};
use std::thread::sleep;
use std::time::{Duration, Instant, SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result, bail};

use crate::process::{Group, Supervisor, Unsupervised};
use crate::results::{self, TestRun};
use crate::skirout::base::harness::v1::test_run::{Artifact, ArtifactKind, TestCase};
use crate::{CommandExt, Context};

/// The file the runner writes inside the evidence folder.
const RUN_FILE: &str = "test_run.json";
const SCREEN: (u32, u32) = (1280, 800);
/// GitHub's image proxy refuses files over about 5 MB; previews stay well below.
const PREVIEW_LIMIT: u64 = 3 * 1024 * 1024;

/// A command to record, with the programs it needs on the same display.
pub struct Recorded {
    pub command: Vec<String>,
    pub companions: Vec<Vec<String>>,
    /// False when only the display is needed, because the program records itself.
    pub video: bool,
    /// Where the command runs, relative to the repository root.
    pub cwd: String,
    pub env: Vec<(String, String)>,
    /// Variables the command must not inherit.
    pub env_remove: Vec<String>,
}

impl Recorded {
    /// `command`, run from the repository root and recorded.
    pub fn video(command: Vec<String>) -> Self {
        Self {
            command,
            companions: Vec::new(),
            video: true,
            cwd: ".".into(),
            env: Vec::new(),
            env_remove: Vec::new(),
        }
    }

    /// Runs `companion` next to the command, on the same display, for as long as it runs.
    pub fn with(mut self, companion: Vec<String>) -> Self {
        self.companions.push(companion);
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
    if !cfg!(target_os = "linux") {
        let _companions = recorded
            .companions
            .iter()
            .map(|companion| companion_spawn(ctx, supervisor, companion, None))
            .collect::<Result<Vec<_>>>()?;
        let status = supervisor.run(&mut command)?;
        return Ok((read_run(out, &command, status)?, status));
    }
    let display = Xvfb::start(supervisor)?;
    let _companions = recorded
        .companions
        .iter()
        .map(|companion| companion_spawn(ctx, supervisor, companion, Some(&display)))
        .collect::<Result<Vec<_>>>()?;
    let video = out.join("run.mp4");
    let ffmpeg = recorded
        .video
        .then(|| Ffmpeg::x11grab(supervisor, &display, &video))
        .transpose()?;
    let started = millis(SystemTime::now());
    command
        .env("DISPLAY", &display.name)
        .env("RECORDING_STARTED_AT", started.to_string());
    let status = supervisor.run(&mut command)?;
    if let Some(ffmpeg) = ffmpeg {
        ffmpeg.finish()?;
    }
    let mut test_run = read_run(out, &command, status)?;
    if recorded.video {
        for case in &mut test_run.cases {
            cut(out, &video, started, case)?;
        }
        results::write(&test_run, &out.join(RUN_FILE))?;
    }
    Ok((test_run, status))
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

/// One clip and one looping preview (640 px wide, 8 fps, under [`PREVIEW_LIMIT`]) for a case with
/// a span. Spans are Unix milliseconds, so the offset into the recording is the span minus
/// `started`. The preview sits next to the clip as `<name>.webp`.
fn cut(out: &Path, video: &Path, started: i64, case: &mut TestCase) -> Result<()> {
    let Some(span) = &case.span else {
        return Ok(());
    };
    let from = seconds(span.start_millis - started);
    let to = seconds(span.end_millis - started);
    let name = file_name(&case.id);
    let clip = PathBuf::from("clips").join(format!("{name}.mp4"));
    let preview = out.join("clips").join(format!("{name}.webp"));
    fs::create_dir_all(out.join("clips"))?;
    let input = ["-ss", &from, "-to", &to, "-i"];
    ffmpeg()
        .args(input)
        .arg(video)
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
            .args(["-vf", "fps=8,scale=640:-2", "-loop", "0", "-an"])
            .args(["-c:v", "libwebp", "-quality", quality])
            .arg(&preview)
            .run()?;
        if fs::metadata(&preview)?.len() <= PREVIEW_LIMIT {
            break;
        }
        fs::remove_file(&preview)?;
    }
    if !preview.exists() {
        eprintln!(
            "{}: preview too large for GitHub; only the clip is kept",
            case.id
        );
    }
    case.artifacts.push(Artifact {
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
    fn start(supervisor: &mut dyn Supervisor) -> Result<Self> {
        let number = (99..200)
            .find(|n| !Path::new(&format!("/tmp/.X11-unix/X{n}")).exists())
            .context("no free X display number")?;
        let name = format!(":{number}");
        let screen = format!("{}x{}x24", SCREEN.0, SCREEN.1);
        let group = supervisor.spawn(
            Command::new("Xvfb")
                .args([&name, "-screen", "0", &screen, "-nolisten", "tcp"])
                .stdout(Stdio::null()),
        )?;
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
struct Ffmpeg(Group);

impl Ffmpeg {
    fn x11grab(supervisor: &mut dyn Supervisor, display: &Xvfb, video: &Path) -> Result<Self> {
        let size = format!("{}x{}", SCREEN.0, SCREEN.1);
        let group = supervisor.spawn(
            ffmpeg()
                .args([
                    "-f",
                    "x11grab",
                    "-video_size",
                    &size,
                    "-framerate",
                    "15",
                    "-i",
                ])
                .arg(&display.name)
                .args([
                    "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p",
                ])
                .arg(video)
                .stdin(Stdio::null()),
        )?;
        Ok(Self(group))
    }

    /// Stops with SIGINT and waits, so ffmpeg writes the index and the file plays.
    fn finish(mut self) -> Result<()> {
        Command::new("kill")
            .args(["-INT", &self.0.id().to_string()])
            .run()?;
        let status = self.0.child().wait()?;
        // ffmpeg exits with 255 after SIGINT once the file is finalized.
        if !status.success() && status.code() != Some(255) {
            bail!("ffmpeg failed with {status}");
        }
        Ok(())
    }
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
fn file_name(id: &str) -> String {
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
