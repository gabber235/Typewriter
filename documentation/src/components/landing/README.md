# Landing

The components that make up the documentation site's home page
(`src/content/docs/index.mdx`, Starlight `splash` template). Everything under
this folder is specific to that one page; the page is wrapped in `<Landing>`,
which sets `.tw-home.not-content` so Starlight's prose styles stay out and
`src/styles/home.css` can scope the few CSS bridges the page needs.

## Research

The page was designed after reading how strong developer- and creator-tool
landing pages are built, plus the conversion literature they lean on. Read on
2026-09-04; each entry notes what was taken from it.

### Developer and creator tools

1. **Linear** (linear.app) — one headline that names the category
   ("The product development system for teams and agents"), the product shown
   at full width directly under the CTAs, then alternating text/media sections
   that each show *one* part of the product. Zoomed detail shots rather than
   whole screens. Quotes only from named people.
2. **Stripe** (stripe.com) — dual-audience page: business copy first, a
   dedicated developer block with concrete technical facts and multiple
   integration paths ("no-code, platforms, custom development"). Social proof is
   quantified and verifiable.
3. **Vercel** (vercel.com) — every feature block pairs a benefit headline with
   3–4 concrete capabilities. Final CTA repeats the first CTA verbatim.
4. **Raycast** (raycast.com) — "There's an extension for that" as its own
   section; a separate, later "Build the perfect tools" section for developers;
   an FAQ; closing line restates *free*.
5. **Supabase** (supabase.com) — benefit headline plus factual subhead ("the
   Postgres development platform: an open source backend…"); features listed
   as concrete numbers ("40+ preinstalled extensions"); licence/self-host
   stated plainly as a differentiator.
6. **Framer** (framer.com) — designers and developers get different examples
   in the same sections rather than separate pages.
7. **Figma** (figma.com) — designers and engineers addressed as "design" and
   "build and ship"; benefit-oriented verbs.
8. **Notion** (notion.com) — three pillars, each with its own product shot;
   hero video/animation is *of the product*, not decorative.
9. **Obsidian** (obsidian.md) — "The free and flexible app…": *free* stated in
   the subhead; "Free without limits" section; a Plugins section for
   extensibility with a developer-docs link; community links instead of a
   second download prompt at the end.
10. **Godot** (godotengine.org) — "Your free, open-source game engine": the
    licence status is the headline; feature cards with real screenshots;
    community/"get involved" section.
11. **Unity** (unity.com) — three capability areas, editor screenshot in the
    hero, "get started for free" spelled out, tutorials before conversion.

### Narrative tooling (closest to Typewriter)

12. **Yarn Spinner** (yarnspinner.dev) — headline names every audience
    ("for writers, programmers, game designers, and everyone in between");
    "Features for Everyone"; a "Made with…" section for social proof; no code
    on the page.
13. **Ink / Inky** (inklestudios.com/ink) — "A narrative scripting language for
    games" + editor screenshot; the writer's angle ("Text comes first") and the
    developer's angle ("middleware", engine integrations) in separate
    sections; licence (MIT) and free status stated once, plainly.
14. **Twine** (twinery.org, via mirrors) — "An open-source tool for telling
    interactive, nonlinear stories"; the no-code promise is qualified: no code
    for a simple story, code available "when you're ready".
15. **articy:draft** (articy.com) — "Narrative design for interactive projects";
    audience cards (Narrative Design / Project Planning / Game CMS); "GET FREE
    VERSION" as the primary action; heavy studio testimonials, which a young
    project cannot honestly copy.

### Minecraft plugin pages

16. **Typewriter on Modrinth** (modrinth.com/plugin/typewriter) — the current
    public pitch: five feature bullets, compatibility list, licence named as
    "TYPEWRITER SOFTWARE LICENSE AGREEMENT". Confirms the licence is *not* an
    open-source licence, so this page says "source on GitHub", never "open
    source".
17. **Typewriter on GitHub** (github.com/Gabber235/typewriter) — README frames
    the two audiences ("no coding required" / "highly extensible"); lists
    sponsors by name.
18. **Oraxen** (oraxen.com) — problem-first headline ("Stop Looking Like Every
    Other Server"), chaptered full-width sections, an FAQ that answers "What
    servers are supported?" and "What dependencies are required?" — the two
    objections every plugin page must handle.
19. **ItemsAdder** (wiki.itemsadder.com) — a docs hub doubling as a landing
    page: "First Install", compatibility list, help link. Shows what happens
    without a landing page: no value proposition above the fold.
20. **Denizen** (denizenscript.com) — a link list; the counter-example.

### Conversion guidance

21. **Julian Shapiro, Landing Page Handbook** (julian.com/guide/growth/landing-pages)
    — the template: navbar → hero → social proof → CTA → features & objections
    → repeated CTA → footer. Headline "fully descriptive of what you're
    selling", subhead explains *how*; each feature block states the benefit
    bluntly and answers the objection under it; images show the product, not
    abstractions. Social proof only if you have it.
22. **NN/g, Scrolling and Attention** (nngroup.com/articles/scrolling-and-attention)
    — 57% of viewing time is above the fold, 74% in the first two screens:
    headline, subhead, CTA and product shot must all land in the first
    viewport; no false floors between sections.
23. **NN/g, Homepage Design Principles** (nngroup.com/articles/homepage-design-principles)
    — a concise tagline that says what the thing does, "reveal content through
    examples", minimise motion, no scroll-triggered animation that delays
    comprehension. This is why the pixel-art intro animation was removed.
24. **NN/g, F-Shaped Pattern** (nngroup.com/articles/f-shaped-pattern-reading-web-content)
    — front-load headings with the information-carrying words; readers scan
    headings and skip body text, so every section heading has to work alone.
25. **Growth.Design case studies** (growth.design/case-studies) — framing
    effect, cognitive load, honest social proof, matching CTA wording to the
    reader's mental model.
26. **Refactoring UI** (refactoringui.com) — dual CTA ("two free chapters" /
    "buy"), objections answered in an FAQ, price stated on the page.

### What was extracted

- **Section order.** Hero (headline, subhead, two CTAs, product shot) → what
  you can build → how it works in three steps → the product up close →
  developer section → requirements → FAQ → repeated CTA. This is Shapiro's
  template with the "social proof" slot replaced by "show the product",
  because Typewriter 1.0 has no honest proof yet (no 1.0 users, no numbers).
- **Headline formula.** Descriptive noun phrase + the main objection answered:
  *what it is* ("interactive stories for your Paper server") and *no coding
  required*. Subhead says how: a plugin plus a web panel, and the developer
  escape hatch.
- **CTA verbs.** "Get started" (imperative, low commitment) as the single
  primary action, repeated verbatim at the end; "Join the Discord" and
  "GitHub" as secondaries. No "Download" until the 1.0 build is public.
- **Show the product.** Every section that makes a claim shows the panel:
  the pixel-art intro, whole mockups for the four things you build, annotated
  screenshots (hotspots) for the editor, the manifest tree for audiences. The
  mockups are wireframes, so the alt text says so.
- **Light/dark.** The hero swaps between the light and dark mockup with the
  site theme, so the first screen never shows a mismatched product.
- **Three steps.** Connect → build → play, each one sentence plus a picture,
  as Unity/Notion do with "pillars".
- **Dual audience.** No-code readers get sections 2–5; developers get one
  clearly labelled section with a real `@Entry` class, entry counts and a
  link to the develop docs, like Raycast's and Obsidian's late developer
  sections.
- **Honesty.** No testimonials, user counts, download counts or logos. The
  only proof is checkable: extension and entry counts from the source, the
  licence name, the GitHub link, the Discord link, and sponsor avatars that
  already appear in the project README.
- **Objections.** FAQ answers: is it free, do I need to code, which servers,
  is 1.0 ready (it is in development), do I host the panel.

## Section plan

| # | Section | Why it exists | Component |
|---|---------|---------------|-----------|
| 1 | Hero | Value proposition, primary/secondary actions and the product in the first viewport | `hero/` |
| 2 | What you build | Four things people make, one sentence and one mockup each; nothing tries to imitate the panel or the game | `outcomes/` |
| 3 | How it works | Removes the "what do I actually do" uncertainty in three steps; scroll-driven: the current step lights up, a progress line fills, and one sticky stage swaps to that step's picture | `howitworks/` |
| 4 | The panel | One annotated page-editor screenshot (four pins), then three uniform tiles: timeline, search, dark/light compare | `editor/` + `:::hotspots` + `:::compare` |
| 5 | Player memory | Why stories react to players: a screenplay of one NPC across three beats (NPC left with an orange name, player right) with a margin ledger of what was stored (purple = changed, the panel's fact colour), then the six kinds of fact as a flat spec list; no cards, icons or code | `memory/` |
| 6 | For developers | Real `@Entry` code first (wider, left), with Expressive Code marker labels naming what each part becomes; extension entry counts as dot-leader rows, integrations as one sentence, develop-docs link | `developers/` |
| 7 | Before you start | Requirements as dot-leader rows on the left (server, Java, PacketEvents, client, price, licence), the remaining objections as flattened `:::details` rows on the right; one section instead of two | `start/` + `:::details` in MDX |
| 8 | Get started | Flat closing band under a rule: one large line, the two actions, sponsors beside them with a "Sponsor the project" link; no card, no glow | `cta/` |

Shared pieces: `shell/` (page wrapper), `section/` (eyebrow + h2 + lead) and
`shared/` (button and text styles).

## Decisions worth knowing

- **Licence wording.** `LICENSE` is the Typewriter Software License, which
  allows free use and contribution but forbids redistribution and
  modification. The page therefore says "free to use" and "source on GitHub"
  and never "open source"; the FAQ spells the distinction out.
- **Hero theme swap.** Both hero mockups are in the DOM; the dark one is
  eager with `fetchpriority="high"`, the light one `loading="lazy"` and
  `display: none` unless `data-theme="light"`. Chrome does not fetch a lazy
  image without a box, so dark-mode visitors download one image; light-mode
  visitors download the light one as soon as it has a box. No JavaScript is
  involved, so the first paint always shows the right theme.
- **Zoomed crops.** `shared/Crop.astro` scales the full mockup inside an
  `overflow-hidden` frame around a chosen focal point (`shared/focus.ts`),
  so a card can show one detail without a separate asset. The scaled `<img>`
  extends past the viewport on paper but is clipped by its frame; overflow
  checks look at `scrollWidth`, which stays equal to the viewport.
- **No in-game screenshot.** Step 3 uses a schematic chat illustration
  (`howitworks/ChatIllustration.astro`) labelled "Illustration" rather than
  the 1.8 MB `public/media/chat-messages.gif` from 0.9.
- **Mockups.** `panel-connect.png` (Services page with the "Connect a
  Service" dialog) was added to `src/assets/mockups/src/build.ts` for step 1.
  Regenerate all mockups with `bun run src/assets/mockups/src/build.ts`.
- **Removed.** The 0.9-era `home`, `hero`, `intro`, `featuregrid`,
  `audiencesplit`, `community` and `ctaband` components. The sponsor list
  moved to `cta/data.ts`. `src/assets/home/*`, `public/fonts/minecraft-ten.ttf`
  and `public/media/chat-messages.gif` are no longer referenced by any page.

## Verification

- `bunx biome check src/components/landing src/styles/home.css src/content/docs/index.mdx`
- Scoped `tsc` over the `.ts` files in this folder (see the repo notes; the
  pre-existing `badge/processor.ts` error is unrelated).
- `bunx astro build --outDir dist/<scratch>` then serve the folder statically
  and run axe (`wcag2a`, `wcag2aa`, `wcag21a`, `wcag21aa`, `wcag22aa`) in
  both themes at 1440 and 375 — zero violations at the time of writing.
- No horizontal overflow at 320, 375, 768, 1024 and 1440; every interactive
  target outside running text is at least 24×24; under
  `prefers-reduced-motion: reduce` nothing transitions longer than 0.02 s.

## Conventions

- Tailwind class strings live in each component's `styles.ts` as complete
  literals; colours come from the site tokens (`--color-primary`,
  `--surface*`, `--sl-color-*`, `--material-*`). No hard-coded brand hex.
- Headings and labels use `--font-sans` (JetBrains Mono), running text
  `--font-reading` (Lilex), matching the docs pages.
- Mockups go through `astro:assets` `<Image>` with `widths`/`sizes`; the hero
  image is eager with `fetchpriority="high"`, everything else lazy.
- Nothing on the page depends on JavaScript to be readable; the only script is
  the hotspots/compare runtime already loaded site-wide.
- Motion: hover transitions only, all behind `motion-reduce:`.
