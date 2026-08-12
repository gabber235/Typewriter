import "package:typewriter_panel/typewriter_panel.dart";
import "package:widgetbook_workspace/stories/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors/semantic_header_gallery.dart";

const _root = BindingReference(bindingId: BindingId(0));
const _title = BindingReference(
  bindingId: BindingId(0),
  path: DataPath([FieldPathSegment("title")]),
);

SemanticHeaderScenario actionOverflowScenario() => (
  type: _actionType,
  value: _actionValue,
  presentation: PresentationNode(
    id: "actions",
    header: PresentationHeader(
      binding: _root,
      title: "Quest controls".asStringLiteral,
      description:
          "Resize the canvas to see lower priority actions move into the menu."
              .asStringLiteral,
      initiallyExpanded: true,
      actions: [
        _title.setAction(
          "publish",
          "Publish",
          "mdi:publish",
          "Published",
          120,
          placement: HeaderActionPlacement.beforeTitle,
        ),
        _title.setAction("preview", "Preview", "mdi:play", "Previewing", 90),
        _title.setAction(
          "reset",
          "Reset",
          "mdi:restore",
          "Untitled quest",
          50,
          placement: HeaderActionPlacement.afterTitle,
        ),
        _title.setAction(
          "copy",
          "Make copy",
          "mdi:content-copy",
          "Quest copy",
          30,
        ),
        _title.setAction(
          "archive",
          "Archive",
          "mdi:archive-outline",
          "Archived quest",
          10,
          tone: HeaderActionTone.destructive,
          confirmation: const HeaderActionConfirmation(
            title: TypedExpression(
              resultType: StringType(),
              expression: LiteralExpression(StringValue("Archive quest?")),
            ),
            message: TypedExpression(
              resultType: StringType(),
              expression: LiteralExpression(
                StringValue(
                  "The quest will no longer be available to players.",
                ),
              ),
            ),
            confirmationLabel: TypedExpression(
              resultType: StringType(),
              expression: LiteralExpression(StringValue("Archive")),
            ),
          ),
        ),
      ],
    ),
    element: const RecordInputElement(control: BoundControl(binding: _root)),
  ),
  description:
      "Actions are ordered by evaluated priority. Compact buttons remain visible while lower priorities move into an anchored menu.",
);

SemanticHeaderScenario actionStatesScenario() => (
  type: _actionType,
  value: _actionValue,
  presentation: PresentationNode(
    id: "states",
    header: PresentationHeader(
      binding: _root,
      title: "Action states".asStringLiteral,
      description:
          "Visible, disabled, hidden, destructive, and invalid actions are resolved independently."
              .asStringLiteral,
      initiallyExpanded: true,
      actions: [
        _title.setAction("ready", "Ready", "mdi:check", "Ready", 100),
        _title.setAction(
          "disabled",
          "Unavailable",
          "mdi:lock-outline",
          "Unavailable",
          90,
          enabledIf: false.literal,
        ),
        _title.setAction(
          "hidden",
          "Hidden",
          "mdi:eye-off-outline",
          "Hidden",
          80,
          visibleIf: false.literal,
        ),
        EditorHeaderAction(
          id: const HeaderActionId(namespace: "widgetbook", name: "invalid"),
          icon: "This is not an icon".asStringLiteral,
          label: "Invalid icon".asStringLiteral,
          tooltip:
              "Invalid expressions become diagnostic actions".asStringLiteral,
          priority: 70.literal,
          activation: HeaderActionActivation.invoke(
            EditorAction.local(
              SetValueAction(target: _title, value: "Invalid".asStringLiteral),
            ),
          ),
        ),
      ],
    ),
    element: const RecordInputElement(control: BoundControl(binding: _root)),
  ),
  description:
      "Invalid expressions disable only their own action. Hidden actions disappear, while disabled actions remain discoverable.",
);

final _actionType = RecordType(
  fields: {
    "title": const TypeField(name: "title", type: StringType()),
    "published": const TypeField(name: "published", type: BooleanType()),
  },
);

final _actionValue = RecordValue({
  "title": const StringValue("The lost library"),
  "published": const BooleanValue(false),
});

extension on BindingReference {
  EditorHeaderAction setAction(
    String name,
    String label,
    String icon,
    String value,
    int priority, {
    HeaderActionTone tone = HeaderActionTone.neutral,
    HeaderActionPlacement placement = HeaderActionPlacement.end,
    HeaderActionConfirmation? confirmation,
    TypedExpression? visibleIf,
    TypedExpression? enabledIf,
  }) => EditorHeaderAction(
    id: HeaderActionId(namespace: "widgetbook", name: name),
    icon: icon.iconLiteral,
    label: label.asStringLiteral,
    tooltip: "$label quest".asStringLiteral,
    priority: priority.literal,
    visibleIf: visibleIf,
    enabledIf: enabledIf,
    placement: placement,
    tone: tone,
    confirmation: confirmation,
    activation: HeaderActionActivation.invoke(
      EditorAction.local(
        SetValueAction(target: this, value: value.asStringLiteral),
      ),
    ),
  );
}

extension on String {
  TypedExpression get iconLiteral => TypedExpression(
    resultType: NamedType(standardTypeRefs.icon),
    expression: LiteralExpression(IconValue.iconify(this).typedValue),
  );
}

extension on int {
  TypedExpression get literal => TypedExpression(
    resultType: const IntegerType(width: IntegerWidth.signed64),
    expression: LiteralExpression(IntegerValue(BigInt.from(this))),
  );
}

extension on bool {
  TypedExpression get literal => TypedExpression(
    resultType: const BooleanType(),
    expression: LiteralExpression(BooleanValue(this)),
  );
}
