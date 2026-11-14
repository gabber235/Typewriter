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
  joined("Joined"),
  spawn("Spawn"),
  title("Title"),
  reward("Reward"),
  perks("Perks"),
  tags("Tags"),
  scores("Scores"),
  volume("Volume");

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
    RecordField.spawn => recordSpawn(world: "lobby", height: 64),
    RecordField.title => recordTitle(null),
    RecordField.reward => recordCoins(0),
    RecordField.perks => recordPerks(const []),
    RecordField.tags => recordTags(const []),
    RecordField.scores => recordScores(const {}),
    RecordField.volume => skir.DataValue.wrapInteger("50"),
  };
}

/// A [RecordField.spawn]: a record of the [world] and the [height] an item
/// starts at, edited field by field.
skir.DataValue recordSpawn({required String world, required int height}) =>
    skir.DataValue.createNamed(
      actualType: _spawnUse,
      payload: skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "world",
            value: skir.DataValue.wrapStringValue(world),
          ),
          skir.FieldValue(
            name: "height",
            value: skir.DataValue.wrapInteger("$height"),
          ),
        ],
      ),
    );

/// A [RecordField.title]: [title], or no title at all when null.
skir.DataValue recordTitle(String? title) => title == null
    ? skir.DataValue.null_
    : skir.DataValue.wrapStringValue(title);

/// A [RecordField.reward] of [amount] coins.
skir.DataValue recordCoins(int amount) => skir.DataValue.createNamed(
  actualType: _coinsUse,
  payload: skir.DataValue.createRecord(
    fields: [
      skir.FieldValue(
        name: "amount",
        value: skir.DataValue.wrapInteger("$amount"),
      ),
    ],
  ),
);

/// A [RecordField.reward] of the badge [name].
skir.DataValue recordBadge(String name) => skir.DataValue.createNamed(
  actualType: _badgeUse,
  payload: skir.DataValue.createRecord(
    fields: [
      skir.FieldValue(
        name: "name",
        value: skir.DataValue.wrapStringValue(name),
      ),
    ],
  ),
);

/// The perks a [RecordField.perks] can hold, a set of known choices.
const recordPerkChoices = ["build", "fly", "chat"];

/// A [RecordField.perks] holding [perks], each one of [recordPerkChoices].
skir.DataValue recordPerks(Iterable<String> perks) =>
    skir.DataValue.createNamed(
      actualType: _perksUse,
      payload: skir.DataValue.createSetValue(
        items: [
          for (final perk in perks)
            skir.ListItem(
              id: skir.ItemId(value: perk),
              value: enumValue(_perkDefinition, perk),
            ),
        ],
      ),
    );

/// A [RecordField.tags] listing [tags] in order.
skir.DataValue recordTags(Iterable<String> tags) => skir.DataValue.createNamed(
  actualType: _tagsUse,
  payload: skir.DataValue.createListValue(
    items: [
      for (final (index, tag) in tags.indexed)
        skir.ListItem(
          id: skir.ItemId(value: "tag$index"),
          value: skir.DataValue.wrapStringValue(tag),
        ),
    ],
  ),
);

/// A [RecordField.scores] mapping each game to its score.
skir.DataValue recordScores(Map<String, int> scores) =>
    skir.DataValue.createNamed(
      actualType: _scoresUse,
      payload: skir.DataValue.createMapValue(
        rows: [
          for (final MapEntry(key: game, value: score) in scores.entries)
            skir.MapRow(
              id: skir.ItemId(value: game),
              key: skir.DataValue.wrapStringValue(game),
              value: skir.DataValue.wrapInteger("$score"),
            ),
        ],
      ),
    );

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
/// text, number, switch, check, dropdown, segmented choice, color, date, a
/// nested record, a nullable text, a polymorphic reward, a set of known
/// choices, a list, a map and a slider.
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
            at: editorRootPath.field(field.name),
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

  static final _text = skir.ScalarKind.text;
  static final _integer = skir.ScalarKind.createInteger(
    width: skir.IntegerWidth.signedThirtyTwo,
  );

  skir.TypeTemplate get _template => switch (this) {
    RecordField.nickname ||
    RecordField.role ||
    RecordField.team => skir.TypeTemplate.wrapScalar(_text),
    RecordField.level ||
    RecordField.volume => skir.TypeTemplate.wrapScalar(_integer),
    RecordField.online ||
    RecordField.muted => skir.TypeTemplate.wrapScalar(skir.ScalarKind.boolean),
    RecordField.color => skir.TypeTemplate.wrapScalar(
      skir.ScalarKind.createInteger(width: skir.IntegerWidth.unsignedThirtyTwo),
    ),
    RecordField.joined => skir.TypeTemplate.wrapScalar(
      skir.ScalarKind.timestamp,
    ),
    RecordField.title => skir.TypeTemplate.createNullable(
      value: skir.TypeTemplate.wrapScalar(_text),
    ),
    RecordField.spawn => typeTemplateOf(_spawnDefinition),
    RecordField.reward => typeTemplateOf(_rewardDefinition),
    RecordField.perks => typeTemplateOf(_perksDefinition),
    RecordField.tags => typeTemplateOf(_tagsDefinition),
    RecordField.scores => typeTemplateOf(_scoresDefinition),
  };

  skir.TypeUse get _use => switch (_template) {
    skir.TypeTemplate_scalarWrapper(:final value) => skir.TypeUse.wrapScalar(
      value,
    ),
    skir.TypeTemplate_nullableWrapper() => skir.TypeUse.createNullable(
      value: skir.TypeUse.wrapScalar(_text),
    ),
    skir.TypeTemplate_namedWrapper(:final value) => skir.TypeUse.createNamed(
      definition: value.definition,
      arguments: const [],
    ),
    _ => throw StateError("$this has no type"),
  };

  skir.BindingRef _at(String field) =>
      skir.BindingRef(bindingId: _binding, path: editorRootPath.field(field));

  skir.PresentationElement get _element => switch (this) {
    RecordField.nickname => textInputElement(_reference, label: label),
    RecordField.level => numericInputElement(_reference, label: label),
    RecordField.online => _toggle(skir.TogglePresentation.switch_),
    RecordField.muted => _toggle(skir.TogglePresentation.checkbox),
    RecordField.role => _select(recordRoles),
    RecordField.team => _select(recordTeams),
    RecordField.color => colorInputElement(_reference, label: label),
    RecordField.joined => dateInputElement(_reference, label: label),
    RecordField.spawn => skir.PresentationElement.wrapRecordInput(
      skir.RecordControl(
        control: _control,
        fieldPresentation: presentationColumn("record.spawn.fields", [
          presentationNode(
            "record.spawn.world",
            textInputElement(_at("world"), label: "World"),
          ),
          presentationNode(
            "record.spawn.height",
            numericInputElement(_at("height"), label: "Height"),
          ),
        ]),
        appearance: null,
        content: null,
      ),
    ),
    RecordField.title => skir.PresentationElement.wrapNullableInput(
      skir.NullableControl(
        control: _control,
        valuePresentation: presentationNode(
          "record.title.text",
          textInputElement(_reference, label: "Title text"),
        ),
        emptyText: null,
        clearLabel: null,
      ),
    ),
    RecordField.reward => skir.PresentationElement.wrapPolymorphicInput(
      (skir.PolymorphicControl.mutable()
            ..control = _control
            ..concreteTypes = [
              _concrete(_coinsUse, "Coins", "amount", "Amount"),
              _concrete(_badgeUse, "Badge", "name", "Badge name"),
            ])
          .toFrozen(),
    ),
    RecordField.perks => skir.PresentationElement.wrapSetInput(
      (skir.SetControl.mutable()
            ..control = _control
            ..allowAdd = true
            ..allowRemove = true
            ..itemBinding = _item)
          .toFrozen(),
    ),
    RecordField.tags => skir.PresentationElement.wrapListInput(
      (skir.ListControl.mutable()
            ..control = _control
            ..itemPresentation = presentationNode(
              "record.tags.item",
              textInputElement(
                skir.BindingRef(bindingId: _item.id, path: editorRootPath),
              ),
            )
            ..allowAdd = true
            ..allowRemove = true
            ..itemBinding = _item
            ..indexBinding = skir.BindingDeclaration(
              id: skir.ExpressionBindingId(value: "record.$name.index"),
              type: skir.TypeTemplate.wrapScalar(_integer),
            ))
          .toFrozen(),
    ),
    RecordField.scores => skir.PresentationElement.wrapMapInput(
      (skir.MapControl.mutable()
            ..control = _control
            ..allowAdd = true
            ..allowRemove = true
            ..keyBinding = _item
            ..valueBinding = skir.BindingDeclaration(
              id: skir.ExpressionBindingId(value: "record.$name.value"),
              type: skir.TypeTemplate.wrapScalar(_integer),
            ))
          .toFrozen(),
    ),
    RecordField.volume => skir.PresentationElement.wrapSliderInput(
      skir.SliderControl(
        control: _control,
        minimum: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapInteger("0"),
        ),
        maximum: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapInteger("100"),
        ),
        divisions: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapInteger("100"),
        ),
        appearance: null,
        mappings: null,
        options: null,
      ),
    ),
  };

  skir.BindingDeclaration get _item => skir.BindingDeclaration(
    id: skir.ExpressionBindingId(value: "record.$name.item"),
    type: switch (this) {
      RecordField.perks => typeTemplateOf(_perkDefinition),
      _ => skir.TypeTemplate.wrapScalar(_text),
    },
  );

  skir.ConcreteTypePresentation _concrete(
    skir.NamedTypeUse type,
    String typeLabel,
    String field,
    String fieldLabel,
  ) => skir.ConcreteTypePresentation(
    concreteType: skir.TypeUse.wrapNamed(type),
    label: textLiteral(typeLabel),
    presentation: presentationNode(
      "record.$name.$field",
      (field == "amount" ? numericInputElement : textInputElement)(
        skir.BindingRef(
          bindingId: configuredValueBindingId,
          path: editorRootPath.field(field),
        ),
        label: fieldLabel,
      ),
    ),
  );

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

skir.TypeDefinitionId _testkitType(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "testkit", name: name),
  revision: 1,
);

skir.NamedTypeUse _useOf(skir.TypeDefinitionId definition) =>
    skir.NamedTypeUse(definition: definition, arguments: const []);

final _recordDefinition = _testkitType("record");
final _recordUse = _useOf(_recordDefinition);
final _spawnDefinition = _testkitType("spawn");
final _spawnUse = _useOf(_spawnDefinition);
final _rewardDefinition = _testkitType("reward");
final _coinsDefinition = _testkitType("coins");
final _coinsUse = _useOf(_coinsDefinition);
final _badgeDefinition = _testkitType("badge");
final _badgeUse = _useOf(_badgeDefinition);
final _perkDefinition = _testkitType("perk");
final _perksDefinition = _testkitType("perks");
final _perksUse = _useOf(_perksDefinition);
final _tagsDefinition = _testkitType("tags");
final _tagsUse = _useOf(_tagsDefinition);
final _scoresDefinition = _testkitType("scores");
final _scoresUse = _useOf(_scoresDefinition);
final _recordCatalog = CheckedEditorCatalog(
  testCatalogSnapshot(
    generation: skir.CatalogGeneration(value: "testkit:record"),
    types: [
      declaredRecord(
        _recordDefinition,
        fields: {
          for (final field in RecordField.values) field.name: field._template,
        },
      ),
      declaredRecord(
        _spawnDefinition,
        fields: {
          "world": skir.ScalarKind.text,
          "height": skir.ScalarKind.createInteger(
            width: skir.IntegerWidth.signedThirtyTwo,
          ),
        },
      ),
      declaredRecord(
        _rewardDefinition,
        cases: [_coinsDefinition, _badgeDefinition],
      ),
      declaredRecord(
        _coinsDefinition,
        fields: {
          "amount": skir.ScalarKind.createInteger(
            width: skir.IntegerWidth.signedThirtyTwo,
          ),
        },
        parents: [_rewardDefinition],
      ),
      declaredRecord(
        _badgeDefinition,
        fields: {"name": skir.ScalarKind.text},
        parents: [_rewardDefinition],
      ),
      ...declaredEnum(_perkDefinition, recordPerkChoices),
      declaredCollection(
        _perksDefinition,
        _perkDefinition,
        kind: skir.CollectionKind.set_,
      ),
      declaredCollection(_tagsDefinition, skir.ScalarKind.text),
      declaredMap(
        _scoresDefinition,
        key: skir.ScalarKind.text,
        value: skir.ScalarKind.createInteger(
          width: skir.IntegerWidth.signedThirtyTwo,
        ),
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
