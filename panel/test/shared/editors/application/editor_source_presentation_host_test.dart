import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart"
    as action;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("document freezes caller owned containers", () {
    final bindings = <types.ExpressionBindingId, PortablePresentationBinding>{
      _bindingId: PortablePresentationBinding(
        schema: PortablePresentationBindingSchema.complete(_textType),
        value: types.DataValue.wrapStringValue("first"),
      ),
    };
    final active = <types.PresentationId>{_presentationId};
    final slots = <String, presentation.PresentationNode>{
      "main": presentation.PresentationNode.defaultInstance,
    };

    final document = PortablePresentationDocument(
      catalog: _emptyCatalog(),
      root: presentation.PresentationNode.defaultInstance,
      bindings: bindings,
      budget: expression.EvaluationBudget.defaultInstance,
      activePresentations: active,
      slots: slots,
    );
    bindings.clear();
    active.clear();
    slots.clear();

    expect(document.bindings, contains(_bindingId));
    expect(document.activePresentations, contains(_presentationId));
    expect(document.slots, contains("main"));
    expect(() => document.bindings.clear(), throwsUnsupportedError);
  });

  test("rejects duplicate binding identities", () {
    final bindingValue = _binding(
      read: (_) => types.DataValue.wrapStringValue("value"),
    );

    expect(
      () => _host(bindings: [bindingValue, bindingValue]),
      throwsArgumentError,
    );
  });

  test("validates scalar writes before the backend decoder", () async {
    var value = types.DataValue.wrapInteger("1");
    var writes = 0;
    final host = _host(
      bindings: [
        _binding(
          use: types.TypeUse.wrapScalar(
            types.ScalarKind.createInteger(
              width: types.IntegerWidth.signedEight,
            ),
          ),
          read: (_) => value,
          write: (_, next) {
            writes++;
            value = next;
            return const PortablePresentationWriteResult.applied();
          },
        ),
      ],
    );
    addTearDown(host.dispose);

    final rejected = await host.write(
      _rootReference,
      types.DataValue.wrapInteger("128"),
    );
    expect(rejected, isA<PortablePresentationWriteRejected>());
    expect(writes, 0);

    final accepted = await host.write(
      _rootReference,
      types.DataValue.wrapInteger("127"),
    );
    expect(accepted, isA<PortablePresentationWriteApplied>());
    expect(writes, 1);
    expect(host.read(_rootReference), types.DataValue.wrapInteger("127"));
  });

  test("accepts nullable scalar roots without a named wrapper", () async {
    var value = types.DataValue.wrapStringValue("value");
    final host = _host(
      bindings: [
        _binding(
          use: types.TypeUse.createNullable(value: _textType),
          read: (_) => value,
          write: (_, next) {
            value = next;
            return const PortablePresentationWriteResult.applied();
          },
        ),
      ],
    );
    addTearDown(host.dispose);

    expect(
      await host.write(_rootReference, types.DataValue.null_),
      isA<PortablePresentationWriteApplied>(),
    );
    expect(host.read(_rootReference), types.DataValue.null_);
  });

  test("refreshes from its owner and detaches when disposed", () {
    final owner = ValueNotifier(types.DataValue.wrapStringValue("first"));
    final host = _host(
      bindings: [_binding(read: (_) => owner.value, owner: owner)],
    );

    expect(host.read(_rootReference), types.DataValue.wrapStringValue("first"));
    owner.value = types.DataValue.wrapStringValue("second");
    expect(
      host.read(_rootReference),
      types.DataValue.wrapStringValue("second"),
    );

    host.dispose();
    owner.value = types.DataValue.wrapStringValue("third");
    expect(
      host.read(_rootReference),
      types.DataValue.wrapStringValue("second"),
    );
    owner.dispose();
  });

  test("rejects writes to a read only backend binding", () async {
    final host = _host(
      bindings: [
        _binding(read: (_) => types.DataValue.wrapStringValue("value")),
      ],
    );
    addTearDown(host.dispose);

    expect(
      await host.write(
        _rootReference,
        types.DataValue.wrapStringValue("changed"),
      ),
      isA<PortablePresentationWriteRejected>(),
    );
  });

  test("uses the concrete named value while resolving nested fields", () {
    final message = _definition("Message");
    final textMessage = _definition("TextMessage");
    final textOwner = types.FieldOwner(definition: textMessage, name: "text");
    final catalog = _checkedCatalog([
      _publishedType(message, abstract: true),
      _publishedType(
        textMessage,
        parents: [_namedTemplate(message)],
        fields: [
          _field(
            textOwner,
            types.TypeTemplate.wrapScalar(types.ScalarKind.text),
          ),
        ],
      ),
    ]);
    final declared = types.NamedTypeUse(
      definition: message,
      arguments: const [],
    );
    final actual = types.NamedTypeUse(
      definition: textMessage,
      arguments: const [],
    );
    final host = _host(
      catalog: catalog,
      bindings: [
        _binding(
          use: types.TypeUse.wrapNamed(declared),
          read: (_) => types.DataValue.createNamed(
            actualType: actual,
            payload: types.DataValue.createRecord(
              fields: [
                types.FieldValue(
                  name: "text",
                  value: types.DataValue.wrapStringValue("hello"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    addTearDown(host.dispose);

    expect(
      host.expectedType(
        binding.BindingRef(
          bindingId: _bindingId,
          path: types.ValuePath(
            segments: [types.PathSegment.createField(name: "text")],
          ),
        ),
      ),
      _textType,
    );
  });

  test("uses the actual generic argument for nested write admission", () async {
    final reward = _definition("Reward");
    final coin = _definition("CoinReward");
    final item = _definition("ItemReward");
    final variable = _definition("Variable");
    final parameter = types.ParameterKey(owner: variable, index: 0);
    final valueOwner = types.FieldOwner(definition: variable, name: "value");
    final catalog = _checkedCatalog([
      _publishedType(reward, abstract: true),
      _publishedType(coin, parents: [_namedTemplate(reward)]),
      _publishedType(item, parents: [_namedTemplate(reward)]),
      _publishedType(
        variable,
        parameters: [
          types.TypeParameter(
            key: parameter,
            name: "T",
            bounds: [types.TypeTemplate.wrapNamed(_namedTemplate(reward))],
          ),
        ],
        fields: [
          _field(valueOwner, types.TypeTemplate.wrapParameter(parameter)),
        ],
      ),
    ]);
    final declared = types.NamedTypeUse(
      definition: variable,
      arguments: [
        types.TypeUse.createNamed(definition: reward, arguments: const []),
      ],
    );
    final actual = types.NamedTypeUse(
      definition: variable,
      arguments: [
        types.TypeUse.createNamed(definition: coin, arguments: const []),
      ],
    );
    final current = types.DataValue.createNamed(
      actualType: actual,
      payload: types.DataValue.createRecord(
        fields: [types.FieldValue(name: "value", value: _namedValue(coin))],
      ),
    );
    var writes = 0;
    final host = _host(
      catalog: catalog,
      bindings: [
        _binding(
          use: types.TypeUse.wrapNamed(declared),
          read: (_) => current,
          write: (_, _) {
            writes++;
            return const PortablePresentationWriteResult.applied();
          },
        ),
      ],
    );
    addTearDown(host.dispose);
    final valueReference = binding.BindingRef(
      bindingId: _bindingId,
      path: types.ValuePath(
        segments: [types.PathSegment.createField(name: "value")],
      ),
    );

    expect(
      host.expectedType(valueReference),
      types.TypeUse.createNamed(definition: coin, arguments: const []),
    );
    expect(
      await host.write(valueReference, _namedValue(item)),
      isA<PortablePresentationWriteRejected>(),
    );
    expect(writes, 0);
    expect(
      await host.write(valueReference, _namedValue(coin)),
      isA<PortablePresentationWriteApplied>(),
    );
    expect(writes, 1);
  });

  test("a delayed write may finish after the host is disposed", () async {
    final completion = Completer<PortablePresentationWriteResult>();
    final host = _host(
      bindings: [
        _binding(
          read: (_) => types.DataValue.wrapStringValue("value"),
          write: (_, _) => completion.future,
        ),
      ],
    );

    final pending = host.write(
      _rootReference,
      types.DataValue.wrapStringValue("changed"),
    );
    host.dispose();
    completion.complete(const PortablePresentationWriteResult.applied());

    expect(await pending, isA<PortablePresentationWriteApplied>());
  });

  test("a delayed action may finish after the host is disposed", () async {
    final completion = Completer<PortablePresentationWriteResult>();
    final host = _host(
      bindings: [
        _binding(read: (_) => types.DataValue.wrapStringValue("value")),
      ],
      executeAction: (_) => completion.future,
    );

    final pending = host.execute(action.EditorAction.unknown);
    host.dispose();
    completion.complete(const PortablePresentationWriteResult.applied());

    expect(await pending, isA<PortablePresentationWriteApplied>());
  });

  test("disposed hosts reject fresh writes and actions", () async {
    var writes = 0;
    var actions = 0;
    final host = _host(
      bindings: [
        _binding(
          read: (_) => types.DataValue.wrapStringValue("value"),
          write: (_, _) {
            writes++;
            return const PortablePresentationWriteResult.applied();
          },
        ),
      ],
      executeAction: (_) {
        actions++;
        return const PortablePresentationWriteResult.applied();
      },
    );
    final disposedHost = host..dispose();

    expect(
      await disposedHost.write(
        _rootReference,
        types.DataValue.wrapStringValue("changed"),
      ),
      isA<PortablePresentationWriteRejected>(),
    );
    expect(
      await disposedHost.execute(action.EditorAction.unknown),
      isA<PortablePresentationWriteRejected>(),
    );
    expect(writes, 0);
    expect(actions, 0);
  });
}

EditorSourcePresentationHost _host({
  required Iterable<EditorSourcePresentationBinding> bindings,
  CheckedEditorCatalog? catalog,
  FutureOr<PortablePresentationWriteResult> Function(
    action.EditorAction action,
  )?
  executeAction,
}) => EditorSourcePresentationHost(
  catalog: catalog ?? _emptyCatalog(),
  root: () => presentation.PresentationNode.defaultInstance,
  bindings: bindings,
  budget: expression.EvaluationBudget.defaultInstance,
  executeAction: executeAction,
);

EditorSourcePresentationBinding _binding({
  required PortableBindingReader read,
  types.TypeUse? use,
  PortableBindingWriter? write,
  Listenable? owner,
}) => EditorSourcePresentationBinding(
  id: _bindingId,
  use: use ?? _textType,
  read: read,
  write: write,
  owner: owner,
);

CheckedEditorCatalog _emptyCatalog() => CheckedEditorCatalog(
  catalog_wire.EditorCatalogWireSnapshot.defaultInstance,
);

final _bindingId = types.ExpressionBindingId(value: "value");
final _presentationId = types.PresentationId(
  namespace: "test",
  name: "presentation",
);
final _textType = types.TypeUse.wrapScalar(types.ScalarKind.text);
final _rootReference = binding.BindingRef(
  bindingId: _bindingId,
  path: types.ValuePath(segments: const []),
);

types.TypeDefinitionId _definition(String name) => types.TypeDefinitionId(
  typeId: types.TypeId.createQualified(namespace: "host.test", name: name),
  revision: 1,
);

types.NamedTypeTemplate _namedTemplate(types.TypeDefinitionId definition) =>
    types.NamedTypeTemplate(definition: definition, arguments: const []);

catalog_wire.EffectiveFieldTemplate _field(
  types.FieldOwner owner,
  types.TypeTemplate type,
) => catalog_wire.EffectiveFieldTemplate(
  key: owner.name,
  owner: owner,
  type: type,
  rules: const [],
);

catalog_wire.PublishedType _publishedType(
  types.TypeDefinitionId definition, {
  bool abstract = false,
  List<types.TypeParameter> parameters = const [],
  List<types.NamedTypeTemplate> parents = const [],
  List<catalog_wire.EffectiveFieldTemplate> fields = const [],
}) => catalog_wire.PublishedType(
  display: null,
  definition: types.TypeDefinition(
    id: definition,
    parameters: parameters,
    representation: types.RepresentationTemplate.createRecord(
      fields: [
        for (final field in fields)
          types.FieldDeclaration(
            owner: field.owner,
            type: field.type,
            overrides: const [],
            hasConstructorDefault: false,
          ),
      ],
      abstract_: abstract,
    ),
    parents: parents,
  ),
  status: catalog_wire.DeclarationStatus.ready,
  effectiveFields: fields,
  ancestorTemplates: parents,
);

CheckedEditorCatalog _checkedCatalog(
  List<catalog_wire.PublishedType> published,
) => CheckedEditorCatalog(
  catalog_wire.EditorCatalogWireSnapshot(
    generation: _hostCatalogGeneration,
    types: published,
    relations: const [],
    resourceDefinitions: const [],
    presentations: const [],
    presentationMaterials: const [],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  ),
);

final _hostCatalogGeneration = types.CatalogGeneration(value: "host:test");

types.DataValue _namedValue(types.TypeDefinitionId definition) =>
    types.DataValue.createNamed(
      actualType: types.NamedTypeUse(
        definition: definition,
        arguments: const [],
      ),
      payload: types.DataValue.createRecord(fields: const []),
    );
