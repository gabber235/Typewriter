import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";
import "package:widgetbook/widgetbook.dart";
import "package:widgetbook_annotation/widgetbook_annotation.dart" as widgetbook;
import "package:widgetbook_workspace/support/story.dart";

/// The actions of a quest: buttons, an icon button and a menu that move the
/// quest between Draft, Saved, Ready and Published.
@widgetbook.UseCase(
  name: "Configured actions",
  type: PortablePresentationRenderer,
)
Widget configuredActionsUseCase(BuildContext context) => Story(
  const [],
  at: PanelLocation.component(
    SizedBox(
      width: context.knobs.double.slider(
        label: "Width",
        initialValue: 640,
        min: 320,
        max: 900,
      ),
      child: _QuestPresentation(
        root: _questActions,
        readOnly: context.knobs.boolean(label: "Read only"),
      ),
    ),
  ),
);

/// A quest summary: its story line, region, status, objective progress and
/// Summary and Details tabs.
@widgetbook.UseCase(
  name: "Configured displays",
  type: PortablePresentationRenderer,
)
Widget configuredDisplaysUseCase(BuildContext context) {
  final configured = context.knobs.boolean(
    label: "Configured appearance",
    initialValue: true,
  );
  return Story(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: context.knobs.double.slider(
          label: "Width",
          initialValue: 640,
          min: 320,
          max: 900,
        ),
        child: _QuestPresentation(
          key: ValueKey(configured),
          root: () => _questSummary(configured: configured),
          readOnly: false,
        ),
      ),
    ),
  );
}

class _QuestPresentation extends HookWidget {
  const _QuestPresentation({
    required this.root,
    required this.readOnly,
    super.key,
  });

  final skir.PresentationNode Function() root;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final status = useRef(skir.DataValue.wrapStringValue("Draft"));
    final host = useMemoized(
      () => BoundPresentationHost(
        readOnly: readOnly,
        catalog: skir.EditorCatalog.defaultInstance.asTrustedLocalCatalog(),
        root: root,
        bindings: [
          BoundPresentationBinding(
            id: _status,
            use: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
            read: (_) => status.value,
            write: (_, next) async {
              status.value = next;
              return const PortablePresentationWriteApplied();
            },
          ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      ),
      [readOnly],
    );
    useEffect(() => host.dispose, [host]);
    return PortablePresentationRenderer(host: host);
  }
}

final _status = skir.ExpressionBindingId(value: "quest.status");

/// Sets the quest status to [status].
skir.EditorAction _markAs(String status) => skir.EditorAction.wrapLocal(
  skir.LocalEditorAction.createSetValue(
    target: skir.BindingRef(bindingId: _status, path: editorRootPath),
    value: textLiteral(status),
  ),
);

skir.PresentationColor _paint(int value) => skir.PresentationColor.wrapValue(
  skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapInteger(value.toString())),
);

skir.PresentationNode _icon(String id, String name) => presentationNode(
  id,
  skir.PresentationElement.createIcon(
    name: textLiteral(name),
    color: null,
    size: numberLiteral(18),
    semanticLabel: null,
  ),
);

skir.ActionAppearance _appearance(skir.ButtonVariant variant, String tooltip) =>
    (skir.ActionAppearance.mutable()
          ..variant = variant
          ..tooltip = textLiteral(tooltip)
          ..appearance =
              (skir.InputAppearance.mutable()
                    ..density = skir.ControlDensity.compact
                    ..radius = skir.PresentationRadius.small
                    ..iconColor = _paint(0xff7354bf)
                    ..valueStyle = (skir.InputTextStyle.mutable()..weight = 600)
                        .toFrozen())
                  .toFrozen())
        .toFrozen();

skir.PresentationNode _column(
  String id,
  List<skir.PresentationNode> children, {
  skir.CrossAxisAlignment cross = skir.CrossAxisAlignment.start,
}) => presentationNode(
  id,
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      layout: skir.AxisChildrenLayout(
        clipOverflow: false,
        spacing: 16,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: cross,
      ),
      children: [for (final child in children) skir.AxisChild.wrapFixed(child)],
    ),
  ),
);

skir.PresentationNode _text(String id, skir.ExpressionNode value) =>
    presentationNode(
      id,
      skir.PresentationElement.wrapText(
        (skir.TextContent.mutable()..value = value).toFrozen(),
      ),
    );

skir.PresentationNode _questActions() {
  final more = skir.MenuElement.mutable()
    ..label = textLiteral("More")
    ..appearance = _appearance(skir.ButtonVariant.text, "More quest actions")
    ..popup =
        (skir.PopupAppearance.mutable()
              ..minimumWidth = numberLiteral(240)
              ..maximumWidth = numberLiteral(300)
              ..maximumExtent = numberLiteral(280)
              ..padding = skir.PresentationInsets.wrapAll(12)
              ..radius = skir.PresentationRadius.medium)
            .toFrozen()
    ..items = [
      (skir.MenuItem.mutable()
            ..itemId = "ready"
            ..label = textLiteral("Mark ready")
            ..action = _markAs("Ready")
            ..description = textLiteral("Players can start it")
            ..icon = _icon("menu.ready.icon", "material-symbols:check-circle"))
          .toFrozen(),
      (skir.MenuItem.mutable()
            ..itemId = "separator"
            ..separator = true)
          .toFrozen(),
      (skir.MenuItem.mutable()
            ..itemId = "delete"
            ..label = textLiteral("Delete quest")
            ..action = _markAs("Deleted")
            ..enabledIf = skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(false),
            )
            ..disabledReason = textLiteral("Remove its objectives first"))
          .toFrozen(),
    ];
  return _column("quest.actions", [
    presentationNode(
      "save",
      skir.PresentationElement.wrapButton(
        (skir.ButtonElement.mutable()
              ..label = textLiteral("Save quest")
              ..action = _markAs("Saved")
              ..appearance = _appearance(
                skir.ButtonVariant.outlined,
                "Save the quest",
              )
              ..icon = _icon("save.icon", "mdi:content-save"))
            .toFrozen(),
      ),
    ),
    presentationNode(
      "publish",
      skir.PresentationElement.wrapButton(
        (skir.ButtonElement.mutable()
              ..label = textLiteral("Publish")
              ..action = _markAs("Published"))
            .toFrozen(),
      ),
    ),
    presentationNode(
      "reopen",
      skir.PresentationElement.wrapIconButton(
        (skir.IconButtonElement.mutable()
              ..icon = textLiteral("material-symbols:restart-alt")
              ..semanticLabel = textLiteral("Reopen as draft")
              ..action = _markAs("Draft")
              ..appearance = _appearance(
                skir.ButtonVariant.filled,
                "Reopen as draft",
              ))
            .toFrozen(),
      ),
    ),
    presentationNode("more", skir.PresentationElement.wrapMenu(more.toFrozen())),
    _text(
      "status",
      skir.ExpressionNode.createInput(binding: _status, path: editorRootPath),
    ),
  ]);
}

skir.PresentationNode _questSummary({required bool configured}) {
  final paint = configured
      ? (skir.InputAppearance.mutable()
              ..fill = _paint(0xffe5dcfa)
              ..valueStyle =
                  (skir.InputTextStyle.mutable()
                        ..color = _paint(0xff40266b)
                        ..weight = 600)
                      .toFrozen()
              ..density = skir.ControlDensity.compact
              ..padding = skir.PresentationInsets.wrapAll(10)
              ..border = skir.BorderOverride.none
              ..radius = skir.PresentationRadius.medium)
            .toFrozen()
      : null;
  final display =
      (skir.DisplayAppearance.mutable()
            ..appearance = paint
            ..icon = skir.InputAdornment.none)
          .toFrozen();
  final progress = skir.ProgressContent.mutable()
    ..value = numberLiteral(3)
    ..maximum = numberLiteral(10)
    ..label = textLiteral("3 of 10 objectives");
  if (configured) {
    progress.appearance =
        (skir.ProgressAppearance.mutable()
              ..color = _paint(0xff7354bf)
              ..backgroundColor = _paint(0xffe5dcfa)
              ..minimumHeight = numberLiteral(12)
              ..radius = skir.PresentationRadius.small)
            .toFrozen();
  }
  final divider = skir.DividerAppearance.mutable();
  if (configured) {
    divider
      ..color = _paint(0xff7354bf)
      ..thickness = numberLiteral(3)
      ..space = numberLiteral(20);
  }
  final tabs = skir.TabsLayout.mutable()
    ..appearance = paint
    ..spacing = 12
    ..contentSpacing = 18
    ..tabs = [
      (skir.TabItem.mutable()
            ..tabId = "summary"
            ..label = textLiteral("Summary")
            ..child = _text(
              "summary.body",
              textLiteral("Find the lost lantern before nightfall"),
            ))
          .toFrozen(),
      (skir.TabItem.mutable()
            ..tabId = "details"
            ..label = textLiteral("Details")
            ..icon = _icon("details.icon", "mdi:information-outline")
            ..child = _text(
              "details.body",
              textLiteral("Starts at the village gate"),
            ))
          .toFrozen(),
    ];
  return _column("quest.summary", [
    presentationNode(
      "story",
      skir.PresentationElement.wrapBadge(
        (skir.BadgeContent.mutable()
              ..label = textLiteral("Main story")
              ..options = display)
            .toFrozen(),
      ),
    ),
    presentationNode(
      "region",
      skir.PresentationElement.wrapChip(
        (skir.ChipContent.mutable()
              ..label = textLiteral("The Lost Village")
              ..options = display)
            .toFrozen(),
      ),
    ),
    presentationNode(
      "status",
      skir.PresentationElement.wrapStatus(
        (skir.StatusContent.mutable()
              ..value = textLiteral("ready")
              ..fallback =
                  (skir.StatusAppearance.mutable()
                        ..tone = skir.StatusTone.success
                        ..label = textLiteral("Ready")
                        ..options = display)
                      .toFrozen())
            .toFrozen(),
      ),
    ),
    presentationNode(
      "progress",
      skir.PresentationElement.wrapProgress(progress.toFrozen()),
    ),
    presentationNode(
      "divider",
      skir.PresentationElement.wrapDivider(divider.toFrozen()),
    ),
    presentationNode("tabs", skir.PresentationElement.wrapTabs(tabs.toFrozen())),
    presentationNode(
      "rewards",
      skir.PresentationElement.wrapTooltip(
        (skir.TooltipElement.mutable()
              ..message = textLiteral("50 coins and the Lantern")
              ..child = _text("rewards.label", textLiteral("Rewards"))
              ..appearance =
                  (skir.TooltipAppearance.mutable()
                        ..waitMilliseconds = 0
                        ..showMilliseconds = 3000
                        ..preferBelow = false
                        ..appearance = paint)
                      .toFrozen())
            .toFrozen(),
      ),
    ),
  ]);
}
