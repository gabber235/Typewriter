/**
 * Base styles for `log` code blocks.
 *
 * Expressive Code scopes every top-level selector under `.expressive-code` but
 * unscopes any selector reaching for `:root`, `html` or `body` — which is how
 * the light-mode block escapes the scope, and why no class name here may
 * contain those words as a substring.
 *
 * Nothing is dimmed with `opacity`: an opacity that clears 4.5:1 on a plain row
 * drops under AA as soon as a level tint is layered beneath it, so the dimming
 * is colour only.
 */
export const logBaseStyles = `
	.log-block {
		--log-info: var(--material-light-blue-300);
		--log-warn: var(--material-amber-400);
		--log-error: var(--material-red-300);
		--log-fatal: var(--material-red-accent-100);
		--log-debug: var(--material-blue-grey-300);
		--log-trace: var(--material-blue-grey-400);
		--log-muted: var(--material-blue-grey-200);
		--log-dim: var(--material-blue-grey-300);
		--log-source: var(--material-blue-grey-300);
		--log-link: var(--material-light-blue-300);
		--log-hover: rgba(var(--color-primary-rgb), 0.07);
		--log-tint: 10%;
		--log-accent: transparent;
		/* Mixed into EC's editor background rather than left translucent, so a
		   marked line's background cannot bleed through and drag the line
		   numbers under AA. */
		--log-gutter-fill: color-mix(in srgb, var(--sl-color-text) 4%, var(--ec-frm-edBg));
		--log-gutter-edge: color-mix(in srgb, var(--sl-color-text) 12%, transparent);
	}

	.log-block > code {
		font-family: var(--font-mono);
	}

	/* Line number gutter */
	.log-block .ec-line > .gutter {
		background-color: var(--log-gutter-fill);
		border-inline-end: 1px solid var(--log-gutter-edge);
	}

	.log-block .log-ln {
		display: block;
		min-width: calc(var(--log-digits, 2) * 1ch);
		padding-inline: 0.9ch;
		text-align: right;
		font-variant-numeric: tabular-nums;
		color: var(--log-muted);
		user-select: none;
		-webkit-user-select: none;
	}

	.log-block .ec-line:hover .log-ln {
		color: var(--log-link);
	}

	/* Rows */
	.log-block .ec-line.log-line {
		transition: background-color 0.12s ease;
	}

	.log-block .ec-line.log-line:hover {
		background: var(--log-hover);
	}

	.log-block .log-level-info { --log-accent: var(--log-info); }
	.log-block .log-level-warn { --log-accent: var(--log-warn); }
	.log-block .log-level-error { --log-accent: var(--log-error); }
	.log-block .log-level-fatal { --log-accent: var(--log-fatal); }
	.log-block .log-level-debug { --log-accent: var(--log-debug); }
	.log-block .log-level-trace { --log-accent: var(--log-trace); }

	/* Left accent bar. Skipped on lines that EC's text markers already own. */
	.log-block .log-line:not(.mark):not(.ins):not(.del) > .code {
		--ecLineBrdCol: var(--log-accent);
	}

	.log-block .log-line.log-inherited:not(.mark):not(.ins):not(.del) > .code {
		--ecLineBrdCol: color-mix(in srgb, var(--log-accent) 40%, transparent);
	}

	.log-block .log-line.log-tinted {
		--log-tint-color: color-mix(in srgb, var(--log-accent) var(--log-tint), transparent);
	}

	.log-block .log-line.log-tinted:not(.mark):not(.ins):not(.del) > .code {
		background-color: var(--log-tint-color);
	}

	/* Layered so the gutter keeps its own base colour under the tint. */
	.log-block .log-line.log-tinted:not(.mark):not(.ins):not(.del) > .gutter {
		background-image: linear-gradient(var(--log-tint-color) 0 0);
	}

	/* Segments */
	.log-block .log-ts { color: var(--log-muted); }
	.log-block .log-thread { color: var(--log-dim); }
	.log-block .log-src { color: var(--log-source); }
	.log-block .log-msg { color: var(--sl-color-text); }
	.log-block .log-lvl { font-weight: 600; }

	.log-block .log-level-info .log-lvl { color: var(--log-info); }

	.log-block .log-level-warn .log-lvl,
	.log-block .log-level-warn .log-msg { color: var(--log-warn); }

	.log-block .log-level-error .log-lvl,
	.log-block .log-level-error .log-msg { color: var(--log-error); }

	.log-block .log-level-fatal .log-lvl,
	.log-block .log-level-fatal .log-msg { color: var(--log-fatal); }

	.log-block .log-level-debug .log-lvl,
	.log-block .log-level-debug .log-msg { color: var(--log-debug); }

	.log-block .log-level-trace .log-lvl,
	.log-block .log-level-trace .log-msg { color: var(--log-trace); }

	/* Stack traces */
	.log-block .log-kind-frame > .code,
	.log-block .log-kind-more > .code,
	.log-block .log-kind-continuation > .code,
	.log-block .log-kind-plain > .code {
		color: var(--log-muted);
	}

	.log-block .log-kind-more > .code { font-style: italic; }
	.log-block .log-kind-frame .log-key { font-style: italic; }
	.log-block .log-kind-frame .log-loc { color: var(--log-source); }

	.log-block .log-kind-exception > .code,
	.log-block .log-kind-caused-by > .code {
		color: color-mix(in srgb, var(--log-error) 75%, var(--sl-color-text));
	}

	.log-block .log-exc { color: var(--log-error); font-weight: 600; }
	.log-block .log-kind-caused-by .log-key { color: var(--log-error); font-weight: 700; }

	/* A marker's background is EC theme colour this plugin cannot measure
	   against, so segment colours defer to EC's own foreground there. */
	.log-block .ec-line:is(.mark, .ins, .del) :is(
		.log-ts, .log-thread, .log-lvl, .log-src, .log-msg,
		.log-key, .log-loc, .log-exc
	) {
		color: inherit;
	}

	/* highlight="…". The chip wraps whatever segment it lands on, so the colour
	   is restated for its descendants at the same specificity as the per-level
	   segment rules, and after them, so the chip reads as one word. */
	.log-block .ec-line .log-hl,
	.log-block .ec-line .log-hl * {
		color: var(--log-link);
	}

	.log-block .log-hl {
		font-weight: 700;
		background: rgba(var(--color-primary-rgb), 0.14);
		border-radius: 3px;
		padding: 0 0.15em;
	}

	/* collapse-traces */
	.log-block .log-frames { display: block; }

	.log-block .log-frames-summary {
		display: flex;
		align-items: center;
		gap: 0.9ch;
		list-style: none;
		cursor: pointer;
		user-select: none;
		-webkit-user-select: none;
		padding-inline-start: calc(var(--log-digits, 2) * 1ch + 1.8ch + 1rem);
		color: var(--log-muted);
		font-style: italic;
		transition: background-color 0.12s ease, color 0.12s ease;
	}

	.log-block .log-frames-summary::-webkit-details-marker { display: none; }

	.log-block .log-frames-summary:hover {
		background: var(--log-hover);
		color: var(--log-link);
	}

	.log-block .log-frames-caret {
		display: inline-block;
		transition: transform 0.15s ease;
	}

	.log-block .log-frames[open] > .log-frames-summary > .log-frames-caret {
		transform: rotate(90deg);
	}

	@media (prefers-reduced-motion: reduce) {
		.log-block .ec-line.log-line,
		.log-block .log-frames-summary,
		.log-block .log-frames-caret {
			transition: none;
		}
	}

	:root[data-theme="light"] .log-block {
		/* The 300-400 end of every ramp lands between 2:1 and 4:1 on a light
		   ground, so light mode takes the 600-900 end instead. */
		--log-info: var(--material-light-blue-900);
		--log-warn: var(--material-deep-orange-900);
		--log-error: var(--material-red-800);
		--log-fatal: var(--material-red-900);
		--log-debug: var(--material-blue-grey-700);
		--log-trace: var(--material-blue-grey-600);
		--log-muted: var(--material-grey-700);
		--log-dim: var(--material-grey-700);
		--log-source: var(--material-blue-grey-700);
		--log-link: var(--material-light-blue-900);
	}
`;
