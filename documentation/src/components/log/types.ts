export type LogLevel = "info" | "warn" | "error" | "fatal" | "debug" | "trace";

/**
 * What a single physical line in a `log` fence turned out to be.
 * - `entry`: a real log entry, i.e. a line that carries a level.
 * - `exception`: a Java exception header (`java.lang.IllegalStateException: ...`).
 * - `caused-by`: a `Caused by:` or `Suppressed:` header inside a stack trace.
 * - `frame`: an `at com.example.Foo.bar(Foo.kt:12)` stack frame.
 * - `more`: a `... 12 more` stack trace elision.
 * - `continuation`: an unrecognised line that follows an entry and inherits its level.
 * - `plain`: an unrecognised line with no entry to inherit from.
 */
export type LogLineKind =
	| "entry"
	| "exception"
	| "caused-by"
	| "frame"
	| "more"
	| "continuation"
	| "plain";

export type LogSegmentKind =
	| "timestamp"
	| "thread"
	| "level"
	| "source"
	| "message"
	| "keyword"
	| "location"
	| "exception"
	| "highlight";

/** A half-open `[columnStart, columnEnd)` range of the line, in UTF-16 code units. */
export interface LogSegment {
	kind: LogSegmentKind;
	columnStart: number;
	columnEnd: number;
}

export interface ParsedLogLine {
	kind: LogLineKind;
	level: LogLevel | undefined;
	/** True when `level` came from an earlier line instead of this one. */
	inherited: boolean;
	segments: LogSegment[];
}

export interface LogBlockOptions {
	/** `collapse-traces` on the fence: hide stack frames past the first two. */
	collapseTraces: boolean;
	/** `highlight="Typewriter"` on the fence: emphasise every occurrence of this text. */
	highlight: string | undefined;
}

/** Number of stack frames left visible before a run is collapsed. */
export const VISIBLE_FRAMES = 2;
