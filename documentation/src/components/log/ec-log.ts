import {
	type AnnotationRenderOptions,
	AttachedPluginData,
	definePlugin,
	ExpressiveCodeAnnotation,
	type ExpressiveCodeBlock,
	type ExpressiveCodeLine,
	type GutterElement,
	isInlineStyleAnnotation,
} from "astro-expressive-code";
import {
	addClassName,
	type Element,
	type ElementContent,
	h,
	type Parents,
	select,
	setInlineStyle,
} from "astro-expressive-code/hast";
import { parseLogLines } from "./parse-log";
import { logBaseStyles } from "./styles";
import {
	type LogBlockOptions,
	type LogSegment,
	type LogSegmentKind,
	type ParsedLogLine,
	VISIBLE_FRAMES,
} from "./types";

type AddGutterElement = (element: GutterElement) => void;

interface LogData {
	enabled: boolean;
	options: LogBlockOptions;
	lines: ParsedLogLine[];
}

const SEGMENT_CLASSES: Record<LogSegmentKind, string> = {
	timestamp: "log-ts",
	thread: "log-thread",
	level: "log-lvl",
	source: "log-src",
	message: "log-msg",
	keyword: "log-key",
	location: "log-loc",
	exception: "log-exc",
	highlight: "log-hl",
};

const TINTED_LEVELS = new Set(["warn", "error", "fatal"]);

const logData = new AttachedPluginData<LogData>(() => ({
	enabled: false,
	options: { collapseTraces: false, highlight: undefined },
	lines: [],
}));

class LogSegmentAnnotation extends ExpressiveCodeAnnotation {
	name = "Log segment";

	constructor(
		private readonly className: string,
		columnStart: number,
		columnEnd: number,
		later: boolean,
	) {
		super({
			inlineRange: { columnStart, columnEnd },
			renderPhase: later ? "later" : "normal",
		});
	}

	render({ nodesToTransform }: AnnotationRenderOptions): Parents[] {
		return nodesToTransform.map((node) => {
			const wrapper = h("span", node);
			addClassName(wrapper, this.className);
			return wrapper;
		});
	}
}

function readOptions(codeBlock: ExpressiveCodeBlock): LogBlockOptions {
	const meta = codeBlock.metaOptions;
	return {
		collapseTraces: meta.getBoolean("collapse-traces") === true,
		highlight: meta.getString("highlight"),
	};
}

function isTinted(parsed: ParsedLogLine): boolean {
	if (parsed.kind !== "entry") return false;
	return parsed.level !== undefined && TINTED_LEVELS.has(parsed.level);
}

function findPre(node: Element): Element | undefined {
	if (node.tagName === "pre") return node;
	return select("pre", node) ?? undefined;
}

function enableLogBlock(codeBlock: ExpressiveCodeBlock): void {
	if (codeBlock.language !== "log") return;
	logData.getOrCreateFor(codeBlock).enabled = true;
	// Logs are not source code: keep Shiki out and colour them ourselves.
	codeBlock.language = "plaintext";
}

function addLineNumbers(addGutterElement: AddGutterElement): void {
	// The numbers are chrome, not log content: a screen reader reading the
	// block would otherwise prefix every line with its index.
	addGutterElement({
		renderPhase: "earlier",
		renderLine: ({ lineIndex }) =>
			h("div.log-ln", { "aria-hidden": "true" }, String(lineIndex + 1)),
		renderPlaceholder: () => h("div.log-ln", { "aria-hidden": "true" }),
	});
}

function dropShikiStyles(line: ExpressiveCodeLine): void {
	for (const annotation of line.getAnnotations()) {
		if (!isInlineStyleAnnotation(annotation)) continue;
		line.deleteAnnotation(annotation);
	}
}

function annotateSegment(line: ExpressiveCodeLine, segment: LogSegment): void {
	if (segment.columnEnd <= segment.columnStart) return;
	line.addAnnotation(
		new LogSegmentAnnotation(
			SEGMENT_CLASSES[segment.kind],
			segment.columnStart,
			segment.columnEnd,
			segment.kind === "highlight",
		),
	);
}

function annotateLines(
	lines: readonly ExpressiveCodeLine[],
	parsedLines: readonly ParsedLogLine[],
): void {
	lines.forEach((line, lineIndex) => {
		dropShikiStyles(line);
		const parsed = parsedLines[lineIndex];
		if (!parsed) return;
		for (const segment of parsed.segments) annotateSegment(line, segment);
	});
}

function annotateLogBlock(
	codeBlock: ExpressiveCodeBlock,
	addGutterElement: AddGutterElement,
): void {
	const data = logData.getOrCreateFor(codeBlock);
	if (!data.enabled) return;

	data.options = readOptions(codeBlock);
	const lines = codeBlock.getLines();
	data.lines = parseLogLines(
		lines.map((line) => line.text),
		data.options.highlight,
	);

	addLineNumbers(addGutterElement);
	annotateLines(lines, data.lines);
}

function classifyRenderedLine(
	codeBlock: ExpressiveCodeBlock,
	lineIndex: number,
	lineAst: Element,
): void {
	const data = logData.getOrCreateFor(codeBlock);
	if (!data.enabled) return;
	const parsed = data.lines[lineIndex];
	if (!parsed) return;

	addClassName(lineAst, "log-line");
	addClassName(lineAst, `log-kind-${parsed.kind}`);
	if (parsed.level) addClassName(lineAst, `log-level-${parsed.level}`);
	if (parsed.inherited) addClassName(lineAst, "log-inherited");
	if (isTinted(parsed)) addClassName(lineAst, "log-tinted");
}

function buildFramesToggle(hidden: ElementContent[]): Element {
	const count = hidden.length;
	return h("details.log-frames", [
		h("summary.log-frames-summary", [
			h("span.log-frames-caret", { "aria-hidden": "true" }, "›"),
			h(
				"span.log-frames-label",
				`… ${count} more frame${count === 1 ? "" : "s"}`,
			),
		]),
		h("div.log-frames-list", hidden),
	]);
}

function frameRunEnd(lines: readonly ParsedLogLine[], start: number): number {
	let end = start;
	while (lines[end]?.kind === "frame") end += 1;
	return end;
}

function foldFrameRun(run: readonly Element[]): ElementContent[] {
	if (run.length <= VISIBLE_FRAMES) return [...run];
	return [
		...run.slice(0, VISIBLE_FRAMES),
		buildFramesToggle(run.slice(VISIBLE_FRAMES)),
	];
}

function foldFrameRuns(
	rendered: readonly Element[],
	lines: readonly ParsedLogLine[],
): ElementContent[] {
	const result: ElementContent[] = [];
	let index = 0;
	while (index < rendered.length) {
		const runEnd = frameRunEnd(lines, index);
		if (runEnd > index) {
			result.push(...foldFrameRun(rendered.slice(index, runEnd)));
			index = runEnd;
			continue;
		}
		const node = rendered[index];
		if (node) result.push(node);
		index += 1;
	}
	return result;
}

function collapseFrames(pre: Element, lines: readonly ParsedLogLine[]): void {
	const code = select("code", pre);
	if (!code) return;
	const rendered = code.children.filter(
		(child): child is Element => child.type === "element",
	);
	if (rendered.length !== lines.length) return;
	code.children = foldFrameRuns(rendered, lines);
}

function finishRenderedBlock(
	codeBlock: ExpressiveCodeBlock,
	blockAst: Element,
): void {
	const data = logData.getOrCreateFor(codeBlock);
	if (!data.enabled) return;
	const pre = findPre(blockAst);
	if (!pre) return;

	addClassName(pre, "log-block");
	// A log block scrolls horizontally on narrow panes, and a scroll container
	// needs a tab stop to be keyboard reachable. Expressive Code's client
	// script only marks the blocks it measures as overflowing — and does not
	// always get to them — so the tab stop is rendered in rather than waited
	// for. `wrap` blocks never scroll, so they stay out of the tab order.
	if (codeBlock.metaOptions.getBoolean("wrap") !== true) {
		pre.properties.tabindex = "0";
	}
	setInlineStyle(pre, "--log-digits", String(String(data.lines.length).length));
	if (!data.options.collapseTraces) return;
	collapseFrames(pre, data.lines);
}

/**
 * Renders ```log fences as a Minecraft server log viewer: per-level colouring,
 * a line number gutter, stack trace styling and optional frame collapsing.
 */
export function ecLog() {
	return definePlugin({
		name: "log",
		baseStyles: logBaseStyles,
		hooks: {
			preprocessLanguage: ({ codeBlock }) => enableLogBlock(codeBlock),
			annotateCode: ({ codeBlock, addGutterElement }) =>
				annotateLogBlock(codeBlock, addGutterElement),
			postprocessRenderedLine: ({ codeBlock, lineIndex, renderData }) =>
				classifyRenderedLine(codeBlock, lineIndex, renderData.lineAst),
			postprocessRenderedBlock: ({ codeBlock, renderData }) =>
				finishRenderedBlock(codeBlock, renderData.blockAst),
		},
	});
}
