import "package:flutter/material.dart";
import "package:iconify_flutter_plus/icons/mdi.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_renderer_story.dart";
import "package:widgetbook_workspace/stories/shared/editors/presentation/protocol/renderers/presentation_story_support.dart";

const _path = "shared/editors/presentation/protocol/renderers/content";

final contentRendererScenarios = [
  RendererStoryScenario(
    kind: RendererStoryKind.text,
    name: "Text",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "text",
      PresentationElement.text(
        "A concise line of supporting copy.".asStringLiteral,
        color: const Color(0xFF967BFA).asColorLiteral,
        fontSize: floatLiteral(22),
        fontWeight: floatLiteral(575.5),
        fontItalic: floatLiteral(0.65),
        fontOpticalSize: floatLiteral(18),
        fontSlant: floatLiteral(-8),
        fontWidth: floatLiteral(112.5),
        textAlignment: "center".asStringLiteral,
        lineHeight: floatLiteral(1.4),
        letterSpacing: floatLiteral(1.5),
        decoration: "underline".asStringLiteral,
        semanticLabel: "Styled supporting copy".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.markdown,
    name: "Markdown",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "markdown",
      PresentationElement.markdown(
        "## Quest notes\n\nUse **clear objectives** and concise instructions."
            .asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.icon,
    name: "Icon",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "icon",
      PresentationElement.icon(
        name: svgIconLiteral(Mdi.map_marker_path),
        semanticLabel: "Quest path".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.image,
    name: "Image",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "image",
      PresentationElement.image(
        source: "https://picsum.photos/640/240".asStringLiteral,
        semanticLabel: "Example quest artwork".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.badge,
    name: "Badge",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "badge",
      PresentationElement.badge(
        label: "Experimental".asStringLiteral,
        tone: "warning",
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.progress,
    name: "Progress",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "progress",
      PresentationElement.progress(
        value: floatLiteral(68),
        maximum: floatLiteral(100),
        label: "Quest completion".asStringLiteral,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.chip,
    name: "Chip",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "chip",
      PresentationElement.chip(
        label: "Adventure".asStringLiteral,
        color: TypedExpression(
          resultType: NamedType(standardTypeRefs.color),
          expression: LiteralExpression(IntegerValue(BigInt.from(0xFF967BFA))),
        ),
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.status,
    name: "Status",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "status",
      PresentationElement.status(
        value: "Reconciling".asStringLiteral,
        cases: const [
          StatusCase(
            match: StringValue("Reconciling"),
            appearance: StatusAppearance(tone: StatusTone.inProgress),
          ),
        ],
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.dateTime,
    name: "Date time",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "dateTime",
      PresentationElement.dateTime(
        value: TypedExpression(
          resultType: const TimestampType(),
          expression: LiteralExpression(
            TimestampValue(DateTime.utc(2026, 8, 22, 12, 30, 45)),
          ),
        ),
        format: "yyyy/MM/dd HH:mm:ss".asStringLiteral,
        timeZone: DateTimeZone.utc,
      ),
    ),
  ),
  RendererStoryScenario(
    kind: RendererStoryKind.relativeTime,
    name: "Relative time",
    type: const UnitType(),
    value: const UnitValue(),
    presentation: storyNode(
      "relativeTime",
      PresentationElement.relativeTime(
        value: TypedExpression(
          resultType: const TimestampType(),
          expression: LiteralExpression(
            TimestampValue(DateTime.now().subtract(const Duration(minutes: 5))),
          ),
        ),
      ),
    ),
  ),
];

@widgetbook.UseCase(name: "Text", type: EditorProtocolRenderer, path: _path)
Widget textRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[0]);

@widgetbook.UseCase(name: "Markdown", type: EditorProtocolRenderer, path: _path)
Widget markdownRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[1]);

@widgetbook.UseCase(name: "Icon", type: EditorProtocolRenderer, path: _path)
Widget iconRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[2]);

@widgetbook.UseCase(name: "Image", type: EditorProtocolRenderer, path: _path)
Widget imageRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[3]);

@widgetbook.UseCase(name: "Badge", type: EditorProtocolRenderer, path: _path)
Widget badgeRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[4]);

@widgetbook.UseCase(name: "Progress", type: EditorProtocolRenderer, path: _path)
Widget progressRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[5]);

@widgetbook.UseCase(name: "Chip", type: EditorProtocolRenderer, path: _path)
Widget chipRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[6]);

@widgetbook.UseCase(name: "Status", type: EditorProtocolRenderer, path: _path)
Widget statusRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[7]);

@widgetbook.UseCase(
  name: "Date time",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget dateTimeRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[8]);

@widgetbook.UseCase(
  name: "Relative time",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget relativeTimeRendererUseCase(BuildContext context) =>
    rendererStory(context, contentRendererScenarios[9]);

@widgetbook.UseCase(
  name: "Status tones",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget statusTonesRendererUseCase(BuildContext context) =>
    rendererStory(context, _statusTonesScenario);

@widgetbook.UseCase(
  name: "Date formats",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget dateFormatsRendererUseCase(BuildContext context) =>
    rendererStory(context, _dateFormatsScenario);

@widgetbook.UseCase(
  name: "Relative styles",
  type: EditorProtocolRenderer,
  path: _path,
)
Widget relativeStylesRendererUseCase(BuildContext context) =>
    rendererStory(context, _relativeStylesScenario);

final _statusTonesScenario = RendererStoryScenario(
  kind: RendererStoryKind.column,
  name: "Status tones",
  type: const UnitType(),
  value: const UnitValue(),
  presentation: storyNode(
    "statusTones",
    PresentationElement.column(
      spacing: 10,
      crossAxisAlignment: PresentationCrossAxisAlignment.start,
      children: [
        for (final tone in StatusTone.values)
          storyNode(
            "statusTones.${tone.name}",
            PresentationElement.status(
              value: tone.name.formatted.asStringLiteral,
              cases: [
                StatusCase(
                  match: StringValue(tone.name.formatted),
                  appearance: StatusAppearance(tone: tone),
                ),
              ],
            ),
          ),
      ],
    ),
  ),
);

final _dateFormatsScenario = RendererStoryScenario(
  kind: RendererStoryKind.column,
  name: "Date formats",
  type: const UnitType(),
  value: const UnitValue(),
  presentation: storyNode(
    "dateFormats",
    PresentationElement.column(
      spacing: 12,
      crossAxisAlignment: PresentationCrossAxisAlignment.start,
      children: [
        for (final (index, format) in [
          "yyyy/MM/dd HH:mm:ss",
          "EEEE, MMMM d, y",
          "HH:mm 'UTC'",
        ].indexed)
          storyNode(
            "dateFormats.$index",
            PresentationElement.dateTime(
              value: _storyTimestamp(DateTime.utc(2026, 8, 22, 12, 30, 45)),
              format: format.asStringLiteral,
              timeZone: index == 2 ? DateTimeZone.utc : DateTimeZone.local,
            ),
          ),
      ],
    ),
  ),
);

final _relativeStylesScenario = RendererStoryScenario(
  kind: RendererStoryKind.column,
  name: "Relative styles",
  type: const UnitType(),
  value: const UnitValue(),
  presentation: storyNode(
    "relativeStyles",
    PresentationElement.column(
      spacing: 12,
      crossAxisAlignment: PresentationCrossAxisAlignment.start,
      children: [
        storyNode(
          "relativeStyles.compactPast",
          PresentationElement.relativeTime(
            value: _storyTimestamp(
              DateTime.now().subtract(const Duration(minutes: 5)),
            ),
          ),
        ),
        storyNode(
          "relativeStyles.naturalFuture",
          PresentationElement.relativeTime(
            value: _storyTimestamp(
              DateTime.now().add(const Duration(hours: 2)),
            ),
            style: RelativeTimeStyle.natural,
          ),
        ),
      ],
    ),
  ),
);

TypedExpression _storyTimestamp(DateTime value) => TypedExpression(
  resultType: const TimestampType(),
  expression: LiteralExpression(TimestampValue(value)),
);
