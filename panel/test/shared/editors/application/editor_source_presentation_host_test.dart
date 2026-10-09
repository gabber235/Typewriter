import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("document freezes caller owned containers", () {
    final bindings = <skir.ExpressionBindingId, PortablePresentationBinding>{
      _bindingId: PortablePresentationBinding(
        schema: PortablePresentationBindingSchema.complete(_textType),
        value: skir.DataValue.wrapStringValue("first"),
      ),
    };
    final active = <skir.PresentationId>{_presentationId};
    final slots = <String, skir.PresentationNode>{
      "main": skir.PresentationNode.defaultInstance,
    };

    final document = PortablePresentationDocument(
      catalog: _emptyCatalog(),
      root: skir.PresentationNode.defaultInstance,
      bindings: bindings,
      budget: skir.EvaluationBudget.defaultInstance,
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
      read: (_) => skir.DataValue.wrapStringValue("value"),
    );

    expect(
      () => _host(bindings: [bindingValue, bindingValue]),
      throwsArgumentError,
    );
  });

  test("validates scalar writes before the backend decoder", () async {
    var value = skir.DataValue.wrapInteger("1");
    var writes = 0;
    final host = _host(
      bindings: [
        _binding(
          use: skir.TypeUse.wrapScalar(
            skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedEight),
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
      skir.DataValue.wrapInteger("128"),
      context: host.rootInvocation,
    );
    expect(rejected, isA<PortablePresentationWriteRejected>());
    expect(writes, 0);

    final accepted = await host.write(
      _rootReference,
      skir.DataValue.wrapInteger("127"),
      context: host.rootInvocation,
    );
    expect(accepted, isA<PortablePresentationWriteApplied>());
    expect(writes, 1);
    expect(
      host.read(_rootReference, context: host.rootInvocation),
      skir.DataValue.wrapInteger("127"),
    );
  });

  test(
    "local value actions evaluate current bindings and use checked writes",
    () async {
      var value = skir.DataValue.wrapStringValue("first");
      var writes = 0;
      final host = _host(
        bindings: [
          _binding(
            read: (_) => value,
            write: (_, next) {
              writes++;
              value = next;
              return const PortablePresentationWriteApplied();
            },
          ),
        ],
      );
      addTearDown(host.dispose);
      final uppercase = skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createSetValue(
          target: _rootReference,
          value: skir.ExpressionNode.createCall(
            operation: skir.OperationId(value: "typewriter.text.upper"),
            arguments: [
              skir.ExpressionNode.createRead(
                binding: _bindingId,
                path: skir.ValuePath(segments: const []),
              ),
            ],
          ),
        ),
      );
      expect(
        await host.execute(uppercase, context: host.rootInvocation),
        isA<PortablePresentationWriteApplied>(),
      );
      expect(
        host.read(_rootReference, context: host.rootInvocation),
        skir.DataValue.wrapStringValue("FIRST"),
      );
      expect(writes, 1);
      final invalid = skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createSetValue(
          target: _rootReference,
          value: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapBoolean(true),
          ),
        ),
      );
      expect(
        await host.execute(invalid, context: host.rootInvocation),
        isA<PortablePresentationWriteRejected>(),
      );
      expect(writes, 1);
    },
  );

  test("local value actions cannot mutate observational bindings", () async {
    final host = _host(
      bindings: [
        _binding(read: (_) => skir.DataValue.wrapStringValue("original")),
      ],
    );
    addTearDown(host.dispose);
    final result = await host.execute(
      skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createSetValue(
          target: _rootReference,
          value: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("changed"),
          ),
        ),
      ),
      context: host.rootInvocation,
    );
    expect(result, isA<PortablePresentationWriteRejected>());
    expect(
      host.read(_rootReference, context: host.rootInvocation),
      skir.DataValue.wrapStringValue("original"),
    );
  });

  test("accepts nullable scalar roots without a named wrapper", () async {
    var value = skir.DataValue.wrapStringValue("value");
    final host = _host(
      bindings: [
        _binding(
          use: skir.TypeUse.createNullable(value: _textType),
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
      await host.write(
        _rootReference,
        skir.DataValue.null_,
        context: host.rootInvocation,
      ),
      isA<PortablePresentationWriteApplied>(),
    );
    expect(
      host.read(_rootReference, context: host.rootInvocation),
      skir.DataValue.null_,
    );
  });

  test("refreshes from its owner and detaches when disposed", () {
    final owner = ValueNotifier(skir.DataValue.wrapStringValue("first"));
    final host = _host(
      bindings: [_binding(read: (_) => owner.value, owner: owner)],
    );

    expect(
      host.read(_rootReference, context: host.rootInvocation),
      skir.DataValue.wrapStringValue("first"),
    );
    owner.value = skir.DataValue.wrapStringValue("second");
    expect(
      host.read(_rootReference, context: host.rootInvocation),
      skir.DataValue.wrapStringValue("second"),
    );

    host.dispose();
    owner.value = skir.DataValue.wrapStringValue("third");
    expect(
      host.read(_rootReference, context: host.rootInvocation),
      skir.DataValue.wrapStringValue("second"),
    );
    owner.dispose();
  });

  test("rejects writes to a read only backend binding", () async {
    final host = _host(
      bindings: [
        _binding(read: (_) => skir.DataValue.wrapStringValue("value")),
      ],
    );
    addTearDown(host.dispose);

    expect(
      await host.write(
        _rootReference,
        skir.DataValue.wrapStringValue("changed"),
        context: host.rootInvocation,
      ),
      isA<PortablePresentationWriteRejected>(),
    );
  });

  test("uses the concrete named value while resolving nested fields", () {
    final message = _definition("Message");
    final textMessage = _definition("TextMessage");
    final textOwner = skir.FieldOwner(definition: textMessage, name: "text");
    final catalog = _checkedCatalog([
      _publishedType(message, abstract: true),
      _publishedType(
        textMessage,
        parents: [_namedTemplate(message)],
        fields: [
          _field(textOwner, skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)),
        ],
      ),
    ]);
    final declared = skir.NamedTypeUse(
      definition: message,
      arguments: const [],
    );
    final actual = skir.NamedTypeUse(
      definition: textMessage,
      arguments: const [],
    );
    final host = _host(
      catalog: catalog,
      bindings: [
        _binding(
          use: skir.TypeUse.wrapNamed(declared),
          read: (_) => skir.DataValue.createNamed(
            actualType: actual,
            payload: skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(
                  name: "text",
                  value: skir.DataValue.wrapStringValue("hello"),
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
        skir.BindingRef(
          bindingId: _bindingId,
          path: skir.ValuePath(
            segments: [skir.PathSegment.createField(name: "text")],
          ),
        ),
        context: host.rootInvocation,
      ),
      _textType,
    );
  });

  test("uses the actual generic argument for nested write admission", () async {
    final reward = _definition("Reward");
    final coin = _definition("CoinReward");
    final item = _definition("ItemReward");
    final variable = _definition("Variable");
    final parameter = skir.ParameterKey(owner: variable, index: 0);
    final valueOwner = skir.FieldOwner(definition: variable, name: "value");
    final catalog = _checkedCatalog([
      _publishedType(reward, abstract: true),
      _publishedType(coin, parents: [_namedTemplate(reward)]),
      _publishedType(item, parents: [_namedTemplate(reward)]),
      _publishedType(
        variable,
        parameters: [
          skir.TypeParameter(
            key: parameter,
            name: "T",
            bounds: [skir.TypeTemplate.wrapNamed(_namedTemplate(reward))],
          ),
        ],
        fields: [
          _field(valueOwner, skir.TypeTemplate.wrapParameter(parameter)),
        ],
      ),
    ]);
    final declared = skir.NamedTypeUse(
      definition: variable,
      arguments: [
        skir.TypeUse.createNamed(definition: reward, arguments: const []),
      ],
    );
    final actual = skir.NamedTypeUse(
      definition: variable,
      arguments: [
        skir.TypeUse.createNamed(definition: coin, arguments: const []),
      ],
    );
    final current = skir.DataValue.createNamed(
      actualType: actual,
      payload: skir.DataValue.createRecord(
        fields: [skir.FieldValue(name: "value", value: _namedValue(coin))],
      ),
    );
    var writes = 0;
    final host = _host(
      catalog: catalog,
      bindings: [
        _binding(
          use: skir.TypeUse.wrapNamed(declared),
          read: (_) => current,
          write: (_, _) {
            writes++;
            return const PortablePresentationWriteResult.applied();
          },
        ),
      ],
    );
    addTearDown(host.dispose);
    final valueReference = skir.BindingRef(
      bindingId: _bindingId,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "value")],
      ),
    );

    expect(
      host.expectedType(valueReference, context: host.rootInvocation),
      skir.TypeUse.createNamed(definition: coin, arguments: const []),
    );
    expect(
      await host.write(
        valueReference,
        _namedValue(item),
        context: host.rootInvocation,
      ),
      isA<PortablePresentationWriteRejected>(),
    );
    expect(writes, 0);
    expect(
      await host.write(
        valueReference,
        _namedValue(coin),
        context: host.rootInvocation,
      ),
      isA<PortablePresentationWriteApplied>(),
    );
    expect(writes, 1);
  });

  test("a delayed write may finish after the host is disposed", () async {
    final completion = Completer<PortablePresentationWriteResult>();
    final host = _host(
      bindings: [
        _binding(
          read: (_) => skir.DataValue.wrapStringValue("value"),
          write: (_, _) => completion.future,
        ),
      ],
    );

    final pending = host.write(
      _rootReference,
      skir.DataValue.wrapStringValue("changed"),
      context: host.rootInvocation,
    );
    host.dispose();
    completion.complete(const PortablePresentationWriteResult.applied());

    expect(await pending, isA<PortablePresentationWriteApplied>());
  });

  test("disposed hosts reject fresh writes and actions", () async {
    var writes = 0;
    final host = _host(
      bindings: [
        _binding(
          read: (_) => skir.DataValue.wrapStringValue("value"),
          write: (_, _) {
            writes++;
            return const PortablePresentationWriteResult.applied();
          },
        ),
      ],
    );
    final disposedHost = host..dispose();

    expect(
      await disposedHost.write(
        _rootReference,
        skir.DataValue.wrapStringValue("changed"),
        context: disposedHost.rootInvocation,
      ),
      isA<PortablePresentationWriteRejected>(),
    );
    expect(
      await disposedHost.execute(
        skir.EditorAction.unknown,
        context: disposedHost.rootInvocation,
      ),
      isA<PortablePresentationWriteRejected>(),
    );
    expect(writes, 0);
  });
}

EditorSourcePresentationHost _host({
  required Iterable<EditorSourcePresentationBinding> bindings,
  CheckedEditorCatalog? catalog,
}) => EditorSourcePresentationHost(
  catalog: catalog ?? _emptyCatalog(),
  root: () => skir.PresentationNode.defaultInstance,
  bindings: bindings,
  budget: skir.EvaluationBudget(maxSteps: 256, maxCollectionItems: 32),
);

EditorSourcePresentationBinding _binding({
  required PortableBindingReader read,
  skir.TypeUse? use,
  PortableBindingWriter? write,
  Listenable? owner,
}) => EditorSourcePresentationBinding(
  id: _bindingId,
  use: use ?? _textType,
  read: read,
  write: write,
  owner: owner,
);

CheckedEditorCatalog _emptyCatalog() =>
    CheckedEditorCatalog(skir.EditorCatalogWireSnapshot.defaultInstance);

final _bindingId = skir.ExpressionBindingId(value: "value");
final _presentationId = skir.PresentationId(
  namespace: "test",
  name: "presentation",
);
final _textType = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
final _rootReference = skir.BindingRef(
  bindingId: _bindingId,
  path: skir.ValuePath(segments: const []),
);

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "host.test", name: name),
  revision: 1,
);

skir.NamedTypeTemplate _namedTemplate(skir.TypeDefinitionId definition) =>
    skir.NamedTypeTemplate(definition: definition, arguments: const []);

skir.EffectiveFieldTemplate _field(
  skir.FieldOwner owner,
  skir.TypeTemplate type,
) => skir.EffectiveFieldTemplate(
  key: owner.name,
  owner: owner,
  type: type,
  rules: const [],
);

skir.PublishedType _publishedType(
  skir.TypeDefinitionId definition, {
  bool abstract = false,
  List<skir.TypeParameter> parameters = const [],
  List<skir.NamedTypeTemplate> parents = const [],
  List<skir.EffectiveFieldTemplate> fields = const [],
}) => skir.PublishedType(
  display: null,
  definition: skir.TypeDefinition(
    id: definition,
    parameters: parameters,
    representation: skir.RepresentationTemplate.createRecord(
      fields: [
        for (final field in fields)
          skir.FieldDeclaration(
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
  status: skir.DeclarationStatus.ready,
  effectiveFields: fields,
  ancestorTemplates: parents,
);

CheckedEditorCatalog _checkedCatalog(List<skir.PublishedType> published) =>
    CheckedEditorCatalog(
      skir.EditorCatalogWireSnapshot(
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

final _hostCatalogGeneration = skir.CatalogGeneration(value: "host:test");

skir.DataValue _namedValue(skir.TypeDefinitionId definition) =>
    skir.DataValue.createNamed(
      actualType: skir.NamedTypeUse(
        definition: definition,
        arguments: const [],
      ),
      payload: skir.DataValue.createRecord(fields: const []),
    );
