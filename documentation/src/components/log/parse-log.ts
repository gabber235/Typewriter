import type { LogLevel, LogSegment, ParsedLogLine } from "./types";

const LEVEL_NAMES = new Map<string, LogLevel>([
	["INFO", "info"],
	["NOTICE", "info"],
	["LIFECYCLE", "info"],
	["WARN", "warn"],
	["WARNING", "warn"],
	["ERROR", "error"],
	["SEVERE", "error"],
	["CRITICAL", "error"],
	["FATAL", "fatal"],
	["EMERGENCY", "fatal"],
	["DEBUG", "debug"],
	["CONFIG", "debug"],
	["FINE", "debug"],
	["TRACE", "trace"],
	["FINER", "trace"],
	["FINEST", "trace"],
	["VERBOSE", "trace"],
]);

const TIMESTAMP =
	/^(?:\d{4}-\d{2}-\d{2}[T ])?\d{1,2}:\d{2}:\d{2}(?:[.,]\d{1,9})?/;
const MORE = /^\s*\.{3}\s*\d+\s+more\s*$/;
const CAUSED_BY = /^\s*(?:Caused by:|Suppressed:)/;
const FRAME = /^\s*at\s+\S/;
const EXCEPTION_HEADER =
	/^\s*(?:Exception in thread\b|(?:[A-Za-z_$][\w$]*\.)+[A-Z][\w$]*(?:Exception|Error|Throwable)[\w$]*)/;
const EXCEPTION_TYPE =
	/(?:[A-Za-z_$][\w$]*\.)+[A-Z][\w$]*(?:Exception|Error|Throwable)[\w$]*/;
const FRAME_LOCATION = /\([^()]*\)\s*$/;
const SOURCE_PREFIX = /^\[[^[\]]+\]/;
const WORD_CHAR = /[\w$]/;

interface Bracket {
	start: number;
	end: number;
}

interface BracketResult {
	segments: LogSegment[];
	level: LogLevel | undefined;
}

function skipSpaces(text: string, from: number): number {
	let index = from;
	while (text[index] === " ") index += 1;
	return index;
}

/**
 * Reads the `[...]` groups that make up a log entry's prefix, stopping at the
 * `:` that separates the prefix from the message. Everything after that (such
 * as a `[PluginName]` tag) belongs to the message, not the prefix.
 */
function readPrefixBrackets(text: string): {
	brackets: Bracket[];
	prefixEnd: number;
} {
	const brackets: Bracket[] = [];
	let index = 0;
	while (text[index] === "[") {
		const close = text.indexOf("]", index + 1);
		if (close === -1) break;
		brackets.push({ start: index, end: close + 1 });
		index = skipSpaces(text, close + 1);
		if (text[index] === ":") {
			index += 1;
			break;
		}
	}
	return { brackets, prefixEnd: skipSpaces(text, index) };
}

function levelSegment(
	text: string,
	searchStart: number,
	token: string,
): LogSegment {
	const start = text.indexOf(token, searchStart);
	return { kind: "level", columnStart: start, columnEnd: start + token.length };
}

function segmentBracket(text: string, bracket: Bracket): BracketResult {
	const innerStart = bracket.start + 1;
	const inner = text.slice(innerStart, bracket.end - 1);

	const time = TIMESTAMP.exec(inner);
	if (time) {
		const stamp: LogSegment = {
			kind: "timestamp",
			columnStart: innerStart,
			columnEnd: innerStart + time[0].length,
		};
		const token = inner.slice(time[0].length).trim();
		const level = LEVEL_NAMES.get(token.toUpperCase());
		if (!level) return { segments: [stamp], level: undefined };
		return {
			segments: [stamp, levelSegment(text, stamp.columnEnd, token)],
			level,
		};
	}

	const slash = inner.lastIndexOf("/");
	const tail = slash === -1 ? "" : inner.slice(slash + 1).trim();
	const threadLevel = LEVEL_NAMES.get(tail.toUpperCase());
	if (threadLevel) {
		const thread: LogSegment = {
			kind: "thread",
			columnStart: innerStart,
			columnEnd: innerStart + slash,
		};
		return {
			segments: [thread, levelSegment(text, innerStart + slash, tail)],
			level: threadLevel,
		};
	}

	const bare = inner.trim();
	const bareLevel = LEVEL_NAMES.get(bare.toUpperCase());
	if (bareLevel) {
		return {
			segments: [levelSegment(text, innerStart, bare)],
			level: bareLevel,
		};
	}

	const source: LogSegment = {
		kind: "source",
		columnStart: bracket.start,
		columnEnd: bracket.end,
	};
	return { segments: [source], level: undefined };
}

function segmentMessage(text: string, start: number): LogSegment[] {
	const segments: LogSegment[] = [];
	let index = start;
	const source = SOURCE_PREFIX.exec(text.slice(index));
	if (source) {
		segments.push({
			kind: "source",
			columnStart: index,
			columnEnd: index + source[0].length,
		});
		index = skipSpaces(text, index + source[0].length);
	}
	if (index < text.length) {
		segments.push({
			kind: "message",
			columnStart: index,
			columnEnd: text.length,
		});
	}
	return segments;
}

function segmentExceptionType(text: string, from: number): LogSegment[] {
	const match = EXCEPTION_TYPE.exec(text.slice(from));
	if (!match) return [];
	const start = from + match.index;
	return [
		{
			kind: "exception",
			columnStart: start,
			columnEnd: start + match[0].length,
		},
	];
}

function segmentFrame(text: string): LogSegment[] {
	const segments: LogSegment[] = [];
	const at = text.indexOf("at ");
	if (at !== -1) {
		segments.push({ kind: "keyword", columnStart: at, columnEnd: at + 2 });
	}
	const location = FRAME_LOCATION.exec(text);
	if (location) {
		const trimmed = location[0].trimEnd();
		segments.push({
			kind: "location",
			columnStart: location.index,
			columnEnd: location.index + trimmed.length,
		});
	}
	return segments;
}

function segmentCausedBy(text: string): LogSegment[] {
	const match = CAUSED_BY.exec(text);
	if (!match) return [];
	const keyword: LogSegment = {
		kind: "keyword",
		columnStart: match.index + match[0].length - match[0].trimStart().length,
		columnEnd: match.index + match[0].length,
	};
	return [keyword, ...segmentExceptionType(text, keyword.columnEnd)];
}

function parseEntry(text: string): ParsedLogLine | undefined {
	if (text[0] !== "[") return undefined;
	const { brackets, prefixEnd } = readPrefixBrackets(text);
	if (brackets.length === 0) return undefined;

	const segments: LogSegment[] = [];
	let level: LogLevel | undefined;
	for (const bracket of brackets) {
		const result = segmentBracket(text, bracket);
		segments.push(...result.segments);
		level = level ?? result.level;
	}
	if (!level) return undefined;

	segments.push(...segmentMessage(text, prefixEnd));
	return { kind: "entry", level, inherited: false, segments };
}

/**
 * Classifies a single log line. `previousLevel` is the level of the most recent
 * entry, which continuation and stack trace lines inherit.
 */
export function parseLogLine(
	text: string,
	previousLevel: LogLevel | undefined,
): ParsedLogLine {
	const entry = parseEntry(text);
	if (entry) return entry;

	const inherited = { level: previousLevel, inherited: true } as const;
	if (MORE.test(text)) return { kind: "more", segments: [], ...inherited };
	if (CAUSED_BY.test(text)) {
		return { kind: "caused-by", segments: segmentCausedBy(text), ...inherited };
	}
	if (FRAME.test(text)) {
		return { kind: "frame", segments: segmentFrame(text), ...inherited };
	}
	if (EXCEPTION_HEADER.test(text)) {
		return {
			kind: "exception",
			segments: segmentExceptionType(text, 0),
			...inherited,
		};
	}
	if (previousLevel) {
		return { kind: "continuation", segments: [], ...inherited };
	}
	return { kind: "plain", level: undefined, inherited: false, segments: [] };
}

function isNestable(
	range: LogSegment,
	segments: readonly LogSegment[],
): boolean {
	return segments.every(
		(segment) =>
			range.columnEnd <= segment.columnStart ||
			range.columnStart >= segment.columnEnd ||
			(range.columnStart >= segment.columnStart &&
				range.columnEnd <= segment.columnEnd),
	);
}

function isWordBounded(text: string, start: number, end: number): boolean {
	const before = text[start - 1];
	const after = text[end];
	if (before !== undefined && WORD_CHAR.test(before)) return false;
	return after === undefined || !WORD_CHAR.test(after);
}

function withHighlights(
	parsed: ParsedLogLine,
	text: string,
	term: string,
): ParsedLogLine {
	const haystack = text.toLowerCase();
	const needle = term.toLowerCase();
	const matches: LogSegment[] = [];
	let index = haystack.indexOf(needle);
	while (index !== -1) {
		const range: LogSegment = {
			kind: "highlight",
			columnStart: index,
			columnEnd: index + needle.length,
		};
		const bounded = isWordBounded(text, range.columnStart, range.columnEnd);
		if (bounded && isNestable(range, parsed.segments)) matches.push(range);
		index = haystack.indexOf(needle, index + needle.length);
	}
	if (matches.length === 0) return parsed;
	return { ...parsed, segments: [...parsed.segments, ...matches] };
}

/** Parses a whole `log` block, threading the inherited level through the lines. */
export function parseLogLines(
	lines: readonly string[],
	highlight?: string,
): ParsedLogLine[] {
	const term = highlight?.trim();
	let previousLevel: LogLevel | undefined;
	return lines.map((text) => {
		const parsed = parseLogLine(text, previousLevel);
		if (parsed.kind === "entry") previousLevel = parsed.level;
		if (!term) return parsed;
		return withHighlights(parsed, text, term);
	});
}
