import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

part "record_selectable.g.dart";

/// The saved field values of every [RecordSelectableIdentifier], by id.
@Riverpod(keepAlive: true)
class RecordSelectableData extends _$RecordSelectableData {
  @override
  Map<String, Map<String, skir.DataValue>> build() => {};

  void save(String id, Map<String, skir.DataValue> fields) {
    state = {...state, id: fields};
  }
}

/// One field of a [RecordSelectable]: its name, the label its control shows
/// and the value it starts with.
enum RecordField {
  nickname("Nickname"),
  level("Level"),
  online("Online"),
  muted("Muted"),
  role("Role"),
  team("Team"),
  color("Color"),
  joined("Joined");

  const RecordField(this.label);

  final String label;

  /// The value a field holds when the item does not say otherwise.
  skir.DataValue get initial => switch (this) {
    RecordField.nickname => skir.DataValue.wrapStringValue(""),
    RecordField.level => skir.DataValue.wrapInteger("1"),
    RecordField.online ||
    RecordField.muted => skir.DataValue.wrapBoolean(false),
    RecordField.role => skir.DataValue.wrapStringValue("player"),
    RecordField.team => skir.DataValue.wrapStringValue("red"),
    RecordField.color => skir.DataValue.wrapInteger(0xFF2196F3.toString()),
    RecordField.joined => skir.DataValue.wrapTimestamp(DateTime.utc(2026)),
  };
}

/// The choices of [RecordField.role], a dropdown since it has more than
/// three.
const recordRoles = {
  "player": "Player",
  "builder": "Builder",
  "moderator": "Moderator",
  "admin": "Admin",
};

/// The choices of [RecordField.team], a segmented control since it has two.
const recordTeams = {"red": "Red", "blue": "Blue"};

/// An item whose data is a record of [RecordField]s, one control per field:
/// text, number, switch, check, dropdown, segmented choice, color and date.
///
/// Several selected items are edited together in the inspector through one
/// combined editor, as members or services are.
class RecordSelectableIdentifier extends SelectableIdentifier {
  RecordSelectableIdentifier({
    required this.id,
    this.fields = const {},
    this.noun = const SelectableNoun(one: "member", many: "members"),
  });

  @override
  final String id;

  /// The values this item starts with; every other field holds its
  /// [RecordField.initial] value.
  final Map<RecordField, skir.DataValue> fields;
  final SelectableNoun noun;

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) =>
      other is RecordSelectableIdentifier && other.id == id;

  @override
  AsyncValue<Selectable> create(Ref ref) {
    final saved = ref.watch(recordSelectableDataProvider)[id];
    final values = {
      for (final field in RecordField.values)
        field.name: saved?[field.name] ?? fields[field] ?? field.initial,
    };
    final data = recordEditorValue(values);
    final snapshot = FakeEditorSnapshot(
      EditorDocument(
        rootType: skir.TypeUse.wrapNamed(_recordUse),
        catalog: _recordCatalog,
        confirmedValue: data,
        revision: 1,
      ),
      validation: acceptTestEditorMutation,
    );
    final store = ref.read(recordSelectableDataProvider.notifier);
    final target = ValueEditingRegistration(
      targetId: this,
      label: id,
      persistence: ScriptedValuePersistence(
        key: EditorResourceKey(scope: null, identity: this),
        current: snapshot,
        commit: (commit) async {
          store.save(id, {
            for (final field in commit.rootValue.authoredRecord!.fields)
              field.name: field.value,
          });
          return TypedMutationResult.success(
            revision: commit.expectedRevision + 1,
            value: commit.rootValue,
          );
        },
      ),
      snapshot: snapshot,
    );
    return AsyncData(RecordSelectable(id: this, target: target));
  }

  @override
  String toString() => "RecordSelectableIdentifier(id: $id)";
}

/// The selectable a [RecordSelectableIdentifier] resolves to.
class RecordSelectable
    extends InspectableSelectable<RecordSelectableIdentifier> {
  const RecordSelectable({required this.id, required this.target});

  @override
  final RecordSelectableIdentifier id;
  final ValueEditingRegistration target;

  @override
  String get name => id.id.formatted;

  @override
  SelectableNoun get noun => id.noun;

  @override
  List<SelectionCapability> get capabilities => const [];

  @override
  List<PortableMultiInspectionSurface> get portableMultiInspectionSurfaces => [
    _RecordFieldsSurface(target),
  ];

  @override
  InspectionContent buildInspection(InspectionBindingScope owners) =>
      InspectionContent(host: _recordFieldsHost(owners.editor(target)));
}

final class _RecordFieldsSurface implements PortableMultiInspectionSurface {
  const _RecordFieldsSurface(this.target);

  @override
  final ValueEditingRegistration target;

  @override
  Object get id => "record.fields";

  @override
  skir.TypeUse get rootType => skir.TypeUse.wrapNamed(_recordUse);

  @override
  CheckedEditorCatalog get catalog => _recordCatalog;

  @override
  bool isCompatibleWith(PortableMultiInspectionSurface other) =>
      other is _RecordFieldsSurface;

  @override
  PortablePresentationHost buildHost(
    List<PortableMultiInspectionSurface> members,
    EditOwner combinedOwner,
  ) => _recordFieldsHost(combinedOwner);
}

/// A host with one control per [RecordField], editing [owner].
BoundPresentationHost _recordFieldsHost(EditOwner owner) =>
    BoundPresentationHost(
      catalog: _recordCatalog,
      root: () => presentationColumn("record", [
        for (final field in RecordField.values)
          presentationNode("record.${field.name}", field._element),
      ]),
      bindings: [
        for (final field in RecordField.values)
          BoundPresentationBinding.owned(
            id: field._binding,
            use: field._use,
            owner: owner,
            read: (owner) =>
                owner.value(editorRootPath.field(field.name)).valueOrNull ??
                skir.DataValue.unfilled,
            write: (path, value) => owner
                .update(
                  skir.ValuePath(
                    segments: [
                      ...editorRootPath.field(field.name).segments,
                      ...path.segments,
                    ],
                  ),
                  value,
                )
                .toPortablePresentationResult(
                  binding: field._binding,
                  sourcePath: editorRootPath.field(field.name),
                ),
          ),
      ],
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    );

extension on RecordField {
  skir.ExpressionBindingId get _binding =>
      skir.ExpressionBindingId(value: "record.$name");

  skir.BindingRef get _reference =>
      skir.BindingRef(bindingId: _binding, path: editorRootPath);

  skir.BoundControl get _control =>
      presentationControl(_reference, label: label);

  skir.ScalarKind get _kind => switch (this) {
    RecordField.nickname ||
    RecordField.role ||
    RecordField.team => skir.ScalarKind.text,
    RecordField.level => skir.ScalarKind.createInteger(
      width: skir.IntegerWidth.signedThirtyTwo,
    ),
    RecordField.online || RecordField.muted => skir.ScalarKind.boolean,
    RecordField.color => skir.ScalarKind.createInteger(
      width: skir.IntegerWidth.unsignedThirtyTwo,
    ),
    RecordField.joined => skir.ScalarKind.timestamp,
  };

  skir.TypeUse get _use => skir.TypeUse.wrapScalar(_kind);

  skir.PresentationElement get _element => switch (this) {
    RecordField.nickname => textInputElement(_reference, label: label),
    RecordField.level => numericInputElement(_reference, label: label),
    RecordField.online => _toggle(skir.TogglePresentation.switch_),
    RecordField.muted => _toggle(skir.TogglePresentation.checkbox),
    RecordField.role => _select(recordRoles),
    RecordField.team => _select(recordTeams),
    RecordField.color => colorInputElement(_reference, label: label),
    RecordField.joined => dateInputElement(_reference, label: label),
  };

  skir.PresentationElement _toggle(skir.TogglePresentation presentation) =>
      skir.PresentationElement.wrapToggleInput(
        (skir.ToggleControl.mutable()
              ..control = _control
              ..options = skir.ToggleInteractionOptions(
                presentation: presentation,
                position: null,
                trueLabel: null,
                falseLabel: null,
                thumbColor: null,
                trackColor: null,
                checkColor: null,
              ))
            .toFrozen(),
      );

  skir.PresentationElement _select(Map<String, String> choices) =>
      skir.PresentationElement.wrapSelectInput(
        (skir.SelectControl.mutable()
              ..control = _control
              ..options = [
                for (final MapEntry(key: value, value: label)
                    in choices.entries)
                  (skir.SelectOption.mutable()
                        ..optionId = value
                        ..label = textLiteral(label)
                        ..value = textLiteral(value))
                      .toFrozen(),
              ])
            .toFrozen(),
      );
}

final _recordDefinition = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "testkit", name: "record"),
  revision: 1,
);
final _recordUse = skir.NamedTypeUse(
  definition: _recordDefinition,
  arguments: const [],
);
final _recordCatalog = CheckedEditorCatalog(
  testCatalogSnapshot(
    generation: skir.CatalogGeneration(value: "testkit:record"),
    types: [
      declaredRecord(
        _recordDefinition,
        fields: {
          for (final field in RecordField.values)
            field.name: skir.TypeTemplate.wrapScalar(field._kind),
        },
      ),
    ],
  ),
);

/// Reading what record items hold.
extension RecordFieldValues on PanelDriver {
  /// The value [item] holds for [field]: what it last saved, else what it
  /// started with.
  skir.DataValue heldBy(RecordSelectableIdentifier item, RecordField field) =>
      container.read(recordSelectableDataProvider)[item.id]?[field.name] ??
      item.fields[field] ??
      field.initial;
}
