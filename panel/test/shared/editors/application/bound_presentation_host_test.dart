import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

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
      catalog: testCheckedCatalog(),
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
    final bindingValue = BoundPresentationBinding(
      id: _bindingId,
      use: _textType,
      read: (_) => skir.DataValue.wrapStringValue("value"),
    );

    expect(
      () => BoundPresentationHost(
        catalog: testCheckedCatalog(),
        root: () => skir.PresentationNode.defaultInstance,
        bindings: [bindingValue, bindingValue],
        budget: skir.EvaluationBudget(maxSteps: 256, maxCollectionItems: 32),
      ),
      throwsArgumentError,
    );
  });

  test("validates scalar writes before the backend decoder", () async {
    var value = skir.DataValue.wrapInteger("1");
    var writes = 0;
    final host = singleBindingHost(
      BoundPresentationBinding(
        id: _bindingId,
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
    );
    addTearDown(host.dispose);

    final rejected = await host.write(
      _rootReference,
      skir.DataValue.wrapInteger("128"),
      context: host.rootInvocation,
    );
    expect(
      rejected,
      writeRejectedBecause("The value does not match the binding type"),
    );
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
      final host = singleBindingHost(
        BoundPresentationBinding(
          id: _bindingId,
          use: _textType,
          read: (_) => value,
          write: (_, next) {
            writes++;
            value = next;
            return const PortablePresentationWriteApplied();
          },
        ),
      );
      addTearDown(host.dispose);
      final uppercase = skir.EditorAction.wrapLocal(
        skir.LocalEditorAction.createSetValue(
          target: _rootReference,
          value: portableCall("text.upper", [
            skir.ExpressionNode.createInput(
              binding: _bindingId,
              path: skir.ValuePath(segments: const []),
            ),
          ]),
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
        writeRejectedBecause("The value does not match the binding type"),
      );
      expect(writes, 1);
    },
  );

  test("local value actions cannot mutate observational bindings", () async {
    final host = singleBindingHost(
      BoundPresentationBinding(
        id: _bindingId,
        use: _textType,
        read: (_) => skir.DataValue.wrapStringValue("original"),
      ),
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
    expect(
      result,
      writeRejectedBecause("This presentation binding is read only"),
    );
    expect(
      host.read(_rootReference, context: host.rootInvocation),
      skir.DataValue.wrapStringValue("original"),
    );
  });

  test("accepts nullable scalar roots without a named wrapper", () async {
    var value = skir.DataValue.wrapStringValue("value");
    final host = singleBindingHost(
      BoundPresentationBinding(
        id: _bindingId,
        use: skir.TypeUse.createNullable(value: _textType),
        read: (_) => value,
        write: (_, next) {
          value = next;
          return const PortablePresentationWriteResult.applied();
        },
      ),
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
    final host = singleBindingHost(
      BoundPresentationBinding(
        id: _bindingId,
        use: _textType,
        read: (_) => owner.value,
        owner: owner,
      ),
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
    final host = singleBindingHost(
      BoundPresentationBinding(
        id: _bindingId,
        use: _textType,
        read: (_) => skir.DataValue.wrapStringValue("value"),
      ),
    );
    addTearDown(host.dispose);

    expect(
      await host.write(
        _rootReference,
        skir.DataValue.wrapStringValue("changed"),
        context: host.rootInvocation,
      ),
      writeRejectedBecause("This presentation binding is read only"),
    );
  });

  test("uses the concrete named value while resolving nested fields", () {
    final message = typeDefinition("Message", namespace: "host.test");
    final textMessage = typeDefinition("TextMessage", namespace: "host.test");
    final textOwner = skir.FieldOwner(definition: textMessage, name: "text");
    final catalog = testCheckedCatalog(
      generation: _hostCatalogGeneration,
      types: [
        testPublishedRecord(message, const {}, abstract: true),
        testPublishedRecord(
          textMessage,
          {textOwner.name: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text)},
          parents: [
            skir.NamedTypeTemplate(definition: message, arguments: const []),
          ],
        ),
      ],
    );
    final declared = skir.NamedTypeUse(
      definition: message,
      arguments: const [],
    );
    final actual = skir.NamedTypeUse(
      definition: textMessage,
      arguments: const [],
    );
    final host = BoundPresentationHost(
      catalog: catalog,
      root: () => skir.PresentationNode.defaultInstance,
      bindings: [
        BoundPresentationBinding(
          id: _bindingId,
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
      budget: skir.EvaluationBudget(maxSteps: 256, maxCollectionItems: 32),
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
    final reward = typeDefinition("Reward", namespace: "host.test");
    final coin = typeDefinition("CoinReward", namespace: "host.test");
    final item = typeDefinition("ItemReward", namespace: "host.test");
    final variable = typeDefinition("Variable", namespace: "host.test");
    final parameter = skir.ParameterKey(owner: variable, index: 0);
    final valueOwner = skir.FieldOwner(definition: variable, name: "value");
    final catalog = testCheckedCatalog(
      generation: _hostCatalogGeneration,
      types: [
        testPublishedRecord(reward, const {}, abstract: true),
        testPublishedRecord(
          coin,
          const {},
          parents: [
            skir.NamedTypeTemplate(definition: reward, arguments: const []),
          ],
        ),
        testPublishedRecord(
          item,
          const {},
          parents: [
            skir.NamedTypeTemplate(definition: reward, arguments: const []),
          ],
        ),
        testPublishedRecord(
          variable,
          {valueOwner.name: skir.TypeTemplate.wrapParameter(parameter)},
          parameters: [
            skir.TypeParameter(
              key: parameter,
              name: "T",
              bounds: [
                skir.TypeTemplate.wrapNamed(
                  skir.NamedTypeTemplate(
                    definition: reward,
                    arguments: const [],
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
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
        fields: [
          skir.FieldValue(
            name: "value",
            value: skir.DataValue.createNamed(
              actualType: skir.NamedTypeUse(
                definition: coin,
                arguments: const [],
              ),
              payload: skir.DataValue.createRecord(fields: const []),
            ),
          ),
        ],
      ),
    );
    var writes = 0;
    final host = BoundPresentationHost(
      catalog: catalog,
      root: () => skir.PresentationNode.defaultInstance,
      bindings: [
        BoundPresentationBinding(
          id: _bindingId,
          use: skir.TypeUse.wrapNamed(declared),
          read: (_) => current,
          write: (_, _) {
            writes++;
            return const PortablePresentationWriteResult.applied();
          },
        ),
      ],
      budget: skir.EvaluationBudget(maxSteps: 256, maxCollectionItems: 32),
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
        skir.DataValue.createNamed(
          actualType: skir.NamedTypeUse(definition: item, arguments: const []),
          payload: skir.DataValue.createRecord(fields: const []),
        ),
        context: host.rootInvocation,
      ),
      writeRejectedBecause("The value does not match the binding type"),
    );
    expect(writes, 0);
    expect(
      await host.write(
        valueReference,
        skir.DataValue.createNamed(
          actualType: skir.NamedTypeUse(definition: coin, arguments: const []),
          payload: skir.DataValue.createRecord(fields: const []),
        ),
        context: host.rootInvocation,
      ),
      isA<PortablePresentationWriteApplied>(),
    );
    expect(writes, 1);
  });

  test("a delayed write may finish after the host is disposed", () async {
    final completion = Completer<PortablePresentationWriteResult>();
    final host = singleBindingHost(
      BoundPresentationBinding(
        id: _bindingId,
        use: _textType,
        read: (_) => skir.DataValue.wrapStringValue("value"),
        write: (_, _) => completion.future,
      ),
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
    final host = singleBindingHost(
      BoundPresentationBinding(
        id: _bindingId,
        use: _textType,
        read: (_) => skir.DataValue.wrapStringValue("value"),
        write: (_, _) {
          writes++;
          return const PortablePresentationWriteResult.applied();
        },
      ),
    );
    final disposedHost = host..dispose();

    expect(
      await disposedHost.write(
        _rootReference,
        skir.DataValue.wrapStringValue("changed"),
        context: disposedHost.rootInvocation,
      ),
      writeRejectedBecause("This presentation is read only"),
    );
    expect(
      await disposedHost.execute(
        skir.EditorAction.unknown,
        context: disposedHost.rootInvocation,
      ),
      writeRejectedBecause("This presentation is read only"),
    );
    expect(writes, 0);
  });
}

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

final _hostCatalogGeneration = skir.CatalogGeneration(value: "host:test");
