import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart"
    as action;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("writes through the host using its checked expected type", (
    tester,
  ) async {
    final host = _TestPortableHost(root: _numericNode);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );

    await tester.enterText(find.byType(TextFormField), "7");
    await tester.pumpAndSettle();

    expect(host.writes, hasLength(1));
    expect(host.writes.single.$1, _reference);
    expect(host.writes.single.$2, types.DataValue.wrapInteger("7"));
    expect(host.expectedTypeReads, greaterThan(0));
  });

  testWidgets("escape leaves typed values applied", (tester) async {
    final host = _TestPortableHost(root: _numericNode);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );

    final field = find.byType(TextFormField);
    await tester.tap(field);
    await tester.enterText(field, "7");
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();

    expect(
      host.document.bindings[_bindingId]?.value.authoredInteger,
      BigInt.from(7),
    );
    expect(tester.widget<TextFormField>(field).controller?.text, "7");

    await tester.tap(field);
    await tester.enterText(field, "8");
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();

    expect(
      host.document.bindings[_bindingId]?.value.authoredInteger,
      BigInt.from(8),
    );
    expect(tester.widget<TextFormField>(field).controller?.text, "8");
  });

  testWidgets("surfaces rejected writes and delegates actions to the host", (
    tester,
  ) async {
    final host = _TestPortableHost(root: _actionNode, rejectWrites: true);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );

    await tester.enterText(find.byType(TextFormField), "8");
    await tester.pumpAndSettle();
    expect(find.byTooltip("The document rejected this write"), findsOneWidget);
    expect(find.bySemanticsLabel("Presentation error"), findsOneWidget);

    await tester.tap(find.text("Run action"));
    await tester.pump();
    expect(host.actions, hasLength(1));
  });

  testWidgets("compact indicators do not steal card selection", (tester) async {
    final host = _TestPortableHost(root: _compactNode);
    var cardTaps = 0;
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => cardTaps++,
          child: PortablePresentationRenderer(
            host: host,
            compactDiagnostics: [
              diagnostic.DiagnosticTemplate(
                code: "compact_error",
                message: "Compact problem",
                severity: diagnostic.DiagnosticSeverity.error,
                targets: const [],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tapAt(
      tester.getCenter(find.byIcon(Icons.error_outline_rounded)),
    );
    expect(cardTaps, 1);
  });

  testWidgets("editor and inspector roles keep full status messages", (
    tester,
  ) async {
    for (final role in [
      catalog.PresentationRole.editor,
      catalog.PresentationRole.inspector,
    ]) {
      final host = _TestPortableHost(
        root: _actionNode,
        rejectWrites: true,
        role: role,
      );
      addTearDown(host.dispose);
      await tester.pumpTestApp(
        child: Material(
          child: SizedBox(
            height: 300,
            child: PortablePresentationRenderer(host: host),
          ),
        ),
      );

      await tester.enterText(find.byType(TextFormField), "8");
      await tester.pumpAndSettle();

      expect(find.text("The document rejected this write"), findsOneWidget);
      expect(find.bySemanticsLabel("Presentation error"), findsNothing);
    }
  });

  testWidgets("compact information remains visibly informational", (
    tester,
  ) async {
    final host = _TestPortableHost(root: _numericNode);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(
        child: PortablePresentationRenderer(
          host: host,
          compactDiagnostics: [
            diagnostic.DiagnosticTemplate(
              code: "informational",
              message: "This value was inferred",
              severity: diagnostic.DiagnosticSeverity.information,
              targets: const [],
            ),
          ],
        ),
      ),
    );

    expect(find.bySemanticsLabel("Presentation information"), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsNothing);
  });

  testWidgets("separates an unspecified header from its first control", (
    tester,
  ) async {
    final host = _TestPortableHost(root: _headerNode);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );

    final description = tester.getRect(find.text("Document description"));
    final control = tester.getRect(find.byType(TextFormField));
    expect(control.top - description.bottom, greaterThanOrEqualTo(8));
    final label = tester.getRect(find.text("Count"));
    expect(control.top - label.bottom, greaterThanOrEqualTo(6));
    expect(find.byType(ValidatedTextField<types.DataValue>), findsOneWidget);
  });

  testWidgets("does not repeat a control label supplied by its header", (
    tester,
  ) async {
    final host = _TestPortableHost(root: _matchingHeaderNode);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );

    expect(find.text("Count"), findsOneWidget);
    expect(find.bySemanticsLabel("Count"), findsWidgets);
  });

  testWidgets("collapsing a header preserves a local invalid draft", (
    tester,
  ) async {
    final host = _TestPortableHost(root: _headerNode);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );

    await tester.enterText(find.byType(TextFormField), "-");
    await tester.pump();
    final writeCountBeforeCollapse = host.writes.length;
    await tester.tap(find.byTooltip("Collapse"));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip("Expand"));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text,
      "-",
    );
    expect(host.writes, hasLength(writeCountBeforeCollapse));
  });

  testWidgets("narrow headers move trailing actions into overflow", (
    tester,
  ) async {
    final host = _TestPortableHost(root: _overflowHeaderNode);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(
        child: SizedBox(
          width: 280,
          child: PortablePresentationRenderer(host: host),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip("More actions"), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets("renders published icon values with resolved styling", (
    tester,
  ) async {
    const color = Color(0xFF336699);
    await tester.pumpTestApp(
      child: Material(
        child: PortablePresentationNodeRenderer(
          node: _node(
            "icon",
            presentation.PresentationElement.createIcon(
              name: expression.ExpressionNode.wrapLiteral(
                types.DataValue.wrapStringValue(
                  '<svg xmlns="http://www.w3.org/2000/svg" '
                  'viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
                ),
              ),
              semanticLabel: expression.ExpressionNode.wrapLiteral(
                types.DataValue.wrapStringValue("Book icon"),
              ),
              color: expression.ExpressionNode.wrapLiteral(
                types.DataValue.wrapInteger(color.toARGB32().toString()),
              ),
              size: expression.ExpressionNode.wrapLiteral(
                types.DataValue.wrapFloat(28),
              ),
            ),
          ),
          scope: PortablePresentationScope(
            bindings: const {},
            budget: expression.EvaluationBudget(
              maxSteps: 100,
              maxCollectionItems: 100,
            ),
            setBinding: (_, _) {},
          ),
        ),
      ),
    );

    final icon = tester.widget<Icones>(find.byType(Icones));
    expect(icon.icon, contains("<svg"));
    expect(icon.color, color);
    expect(icon.size, 28);
    expect(find.bySemanticsLabel("Book icon"), findsOneWidget);
  });

  testWidgets("generated Tag cards adapt to one cell and wider placements", (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final width = ValueNotifier(48.0);
    final name = ValueNotifier("");
    addTearDown(width.dispose);
    addTearDown(name.dispose);

    presentation.PresentationNode tagCard(String tagName) {
      final label = tagName.isEmpty ? "Unnamed tag" : tagName;
      final icon = _node(
        "tag.icon",
        presentation.PresentationElement.createIcon(
          name: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue(
              '<svg xmlns="http://www.w3.org/2000/svg" '
              'viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
            ),
          ),
          semanticLabel: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue("Tag"),
          ),
          color: null,
          size: null,
        ),
      );
      final coloredIcon = _node(
        "tag.icon.color",
        presentation.PresentationElement.createContainer(
          child: _node(
            "tag.icon.padding",
            presentation.PresentationElement.createPadding(
              child: icon,
              top: 6,
              start: 6,
              end: 6,
              bottom: 6,
            ),
          ),
          border: null,
          backgroundColor: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapInteger("4288585374"),
          ),
          radius: presentation.PresentationRadius.none,
        ),
      );
      final center = _node(
        "tag.name",
        presentation.PresentationElement.createText(
          value: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue(label),
          ),
          color: null,
          fontSize: null,
          fontWeight: null,
          fontItalic: null,
          fontOpticalSize: null,
          fontSlant: null,
          fontWidth: null,
          textAlignment: null,
          lineHeight: null,
          letterSpacing: null,
          decoration: null,
          semanticLabel: null,
          paragraph: presentation.TextParagraph.defaultInstance,
        ),
      );
      final card = _node(
        "tag.card",
        presentation.PresentationElement.createAdaptiveLeading(
          leading: coloredIcon,
          center: center,
          suffix: null,
          padding: presentation.PresentationInsets.wrapAll(8),
          compactPadding: presentation.PresentationInsets.wrapAll(4),
          gap: 12,
          minimumCenterWidth: 80,
        ),
      );
      return _node(
        "tag.root",
        presentation.PresentationElement.wrapChildren(
          presentation.ChildrenElement.createColumn(
            children: [presentation.AxisChild.wrapFixed(card)],
            layout: presentation.AxisChildrenLayout(
              spacing: 0,
              mainAxisAlignment: presentation.MainAxisAlignment.start,
              crossAxisAlignment: presentation.CrossAxisAlignment.start,
            ),
          ),
        ),
      );
    }

    final scope = PortablePresentationScope(
      bindings: const {},
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
      setBinding: (_, _) {},
    );

    await tester.pumpTestApp(
      child: Material(
        child: SingleChildScrollView(
          child: Align(
            alignment: Alignment.topLeft,
            child: ValueListenableBuilder(
              valueListenable: width,
              builder: (context, cardWidth, child) {
                final card = Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ValueListenableBuilder(
                    valueListenable: name,
                    builder: (context, tagName, child) =>
                        PortablePresentationNodeRenderer(
                          node: tagCard(tagName),
                          scope: scope,
                        ),
                  ),
                );
                if (cardWidth == 48) {
                  return SizedBox(width: cardWidth, height: 48, child: card);
                }
                return SizedBox(
                  width: cardWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [card],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(Icones), findsOneWidget);
    expect(find.semantics.byLabel("Unnamed tag"), findsNothing);

    name.value = "Quest";
    width.value = 180;
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.semantics.byLabel("Quest"), findsOneWidget);
    semantics.dispose();
  });

  testWidgets("applies portable text styling and exposes style failures", (
    tester,
  ) async {
    const color = Color(0xFF884422);
    presentation.PresentationNode textNode(expression.ExpressionNode weight) =>
        _node(
          "styled.text",
          presentation.PresentationElement.createText(
            value: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapStringValue("Styled title"),
            ),
            color: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapInteger(color.toARGB32().toString()),
            ),
            fontSize: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapFloat(22),
            ),
            fontWeight: weight,
            fontItalic: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapFloat(1),
            ),
            fontOpticalSize: null,
            fontSlant: null,
            fontWidth: null,
            textAlignment: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapStringValue("center"),
            ),
            lineHeight: null,
            letterSpacing: null,
            decoration: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapStringValue("underline"),
            ),
            semanticLabel: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapStringValue("Styled heading"),
            ),
            paragraph: presentation.TextParagraph(
              maxLines: 1,
              overflow: presentation.PresentationTextOverflow.ellipsis,
              softWrap: false,
              selectable: false,
              tone: presentation.PresentationTextTone.primary,
            ),
          ),
        );
    final scope = PortablePresentationScope(
      bindings: const {},
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
      setBinding: (_, _) {},
    );
    await tester.pumpTestApp(
      child: Material(
        child: PortablePresentationNodeRenderer(
          node: textNode(
            expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapFloat(700),
            ),
          ),
          scope: scope,
        ),
      ),
    );

    final text = tester.widget<Text>(find.text("Styled title"));
    expect(text.style?.color, color);
    expect(text.style?.fontSize, 22);
    expect(text.style?.decoration, TextDecoration.underline);
    expect(text.textAlign, TextAlign.center);
    expect(text.semanticsLabel, "Styled heading");
    expect(text.style?.fontVariations, isNotEmpty);

    await tester.pumpTestApp(
      child: Material(
        child: PortablePresentationNodeRenderer(
          node: textNode(
            expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapStringValue("heavy"),
            ),
          ),
          scope: scope,
        ),
      ),
    );
    expect(
      find.text("Font weight must evaluate to a finite number"),
      findsOneWidget,
    );
  });

  testWidgets("invokes the presentation for a configured concrete value", (
    tester,
  ) async {
    final scope = PortablePresentationScope(
      bindings: {
        _bindingId: PortableExpressionBinding(
          value: types.DataValue.createNamed(
            actualType: _iconifyType,
            payload: types.DataValue.createRecord(
              fields: [
                types.FieldValue(
                  name: "value",
                  value: types.DataValue.wrapStringValue(
                    "material-symbols:book",
                  ),
                ),
              ],
            ),
          ),
        ),
      },
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
      setBinding: (_, _) {},
      catalog: _polymorphicCatalog,
    );

    await tester.pumpTestApp(
      child: Material(
        child: PortablePresentationNodeRenderer(
          node: _polymorphicNode,
          scope: scope,
        ),
      ),
    );

    expect(
      find.text("The selected concrete type is unavailable"),
      findsNothing,
    );
    expect(find.text("The invoked presentation is unavailable"), findsNothing);
    expect(find.byType(TextFormField), findsOneWidget);
    expect(
      tester.widget<TextFormField>(find.byType(TextFormField)).controller?.text,
      "material-symbols:book",
    );
  });

  testWidgets("record input scopes relative fields to the nested value", (
    tester,
  ) async {
    final writes = <(binding.BindingRef, types.DataValue)>[];
    final placementReference = binding.BindingRef(
      bindingId: _configuredBindingId,
      path: types.ValuePath(
        segments: [types.PathSegment.createField(name: "placement")],
      ),
    );
    final xReference = binding.BindingRef(
      bindingId: _configuredBindingId,
      path: types.ValuePath(
        segments: [types.PathSegment.createField(name: "x")],
      ),
    );
    final root = types.DataValue.createRecord(
      fields: [
        types.FieldValue(
          name: "placement",
          value: types.DataValue.createNamed(
            actualType: types.NamedTypeUse.defaultInstance,
            payload: types.DataValue.createRecord(
              fields: [
                types.FieldValue(
                  name: "x",
                  value: types.DataValue.wrapInteger("4"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final node = _node(
      "placement",
      presentation.PresentationElement.createRecordInput(
        control: presentation.BoundControl(
          binding: placementReference,
          label: null,
          description: null,
          prefix: null,
          semanticLabel: null,
        ),
        fieldPresentation: _node(
          "placement.x",
          presentation.PresentationElement.wrapNumericInput(
            presentation.BoundControl(
              binding: xReference,
              label: null,
              description: null,
              prefix: null,
              semanticLabel: null,
            ),
          ),
        ),
      ),
    );
    final scope = PortablePresentationScope(
      bindings: {_configuredBindingId: PortableExpressionBinding(value: root)},
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
      setBinding: (reference, value) => writes.add((reference, value)),
    );

    await tester.pumpTestApp(
      child: Material(
        child: PortablePresentationNodeRenderer(node: node, scope: scope),
      ),
    );

    expect(
      find.text("The numeric control binding is unavailable"),
      findsNothing,
    );
    final input = find.byType(TextFormField);
    expect(tester.widget<TextFormField>(input).controller?.text, "4");
    await tester.enterText(input, "6");
    await tester.pumpAndSettle();
    expect(writes, hasLength(1));
    expect(writes.single.$1, placementReference);
    expect(
      writes.single.$2.authoredActualType,
      types.NamedTypeUse.defaultInstance,
    );
    expect(
      writes.single.$2.authoredField("x")?.authoredInteger,
      BigInt.from(6),
    );
  });

  testWidgets("repairs an Unfilled collection with its normal item default", (
    tester,
  ) async {
    final fixture = _collectionFixture(
      value: types.DataValue.unfilled,
      allowAdd: true,
    );
    await tester.pumpTestApp(child: fixture.widget);

    expect(find.text("The collection binding is unavailable"), findsNothing);
    await tester.tap(find.text("Add item"));
    await tester.pump();

    expect(fixture.document.insertions, hasLength(1));
    expect(
      fixture.document.insertions.single.item.value,
      types.DataValue.wrapStringValue(""),
    );
  });

  testWidgets("empty collection controls retain their field guidance", (
    tester,
  ) async {
    final list = _collectionFixture(
      value: types.DataValue.createListValue(items: const []),
      allowAdd: true,
      label: "Pages",
      description: "Pages in this book",
    );
    await tester.pumpTestApp(child: list.widget);
    expect(find.text("Pages"), findsOneWidget);
    expect(find.text("Pages in this book"), findsOneWidget);
    expect(find.text("Add item"), findsOneWidget);

    final map = _mapFixture(label: "Translations");
    await tester.pumpTestApp(child: map.widget);
    expect(find.text("Translations"), findsOneWidget);
    expect(find.text("Add entry"), findsOneWidget);
    expect(find.widgetWithText(FilledButton, "Add entry"), findsOneWidget);
  });

  testWidgets("does not offer collection insertion when addition is disabled", (
    tester,
  ) async {
    final fixture = _collectionFixture(
      value: types.DataValue.createListValue(items: const []),
      allowAdd: false,
    );
    await tester.pumpTestApp(child: fixture.widget);

    expect(find.text("Add item"), findsNothing);
    expect(fixture.document.insertions, isEmpty);
  });

  testWidgets("adds a stable row to an Unfilled map", (tester) async {
    final fixture = _mapFixture();
    await tester.pumpTestApp(child: fixture.widget);

    expect(find.text("The map binding is unavailable"), findsNothing);
    await tester.tap(find.text("Add entry"));
    await tester.pump();

    expect(fixture.document.maps, hasLength(1));
    final row = fixture.document.maps.single.single;
    expect(row.id.value, startsWith("panel:"));
    expect(row.key, types.DataValue.wrapStringValue(""));
    expect(row.value, types.DataValue.wrapStringValue(""));
  });

  testWidgets("selects the first link before inserting an empty set item", (
    tester,
  ) async {
    final fixture = _linkCollectionFixture();
    await tester.pumpTestApp(child: fixture.widget);

    await tester.tap(find.text("Add link"));
    await tester.pumpAndSettle();
    expect(find.text("Target Alpha"), findsOneWidget);
    expect(find.text(fixture.target.value), findsNothing);
    await tester.tap(
      find.byKey(ValueKey("link.target.${fixture.target.value}.automatic")),
    );
    await tester.pumpAndSettle();

    expect(fixture.document.connections, hasLength(1));
    final connection = fixture.document.connections.single;
    expect(connection.target, fixture.target);
    expect(
      connection.source.id.location.path.segments.last,
      isA<types.PathSegment_itemWrapper>(),
    );
  });

  testWidgets("cancelling first link selection leaves the set untouched", (
    tester,
  ) async {
    final fixture = _linkCollectionFixture();
    await tester.pumpTestApp(child: fixture.widget);

    await tester.tap(find.text("Add link"));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(fixture.document.connections, isEmpty);
    expect(fixture.document.insertions, isEmpty);
  });

  testWidgets("searches and selects a linked resource with the keyboard", (
    tester,
  ) async {
    final fixture = _linkCollectionFixture();
    await tester.pumpTestApp(child: fixture.widget);

    await tester.tap(find.text("Add link"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, "Target Beta");
    await tester.pumpAndSettle();

    expect(
      find.byKey(ValueKey("link.target.${fixture.target.value}.automatic")),
      findsNothing,
    );
    expect(
      find.byKey(
        ValueKey("link.target.${fixture.secondTarget.value}.automatic"),
      ),
      findsOneWidget,
    );

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(fixture.document.connections, hasLength(1));
    expect(fixture.document.connections.single.target, fixture.secondTarget);
  });

  testWidgets("presents an existing link by its authored resource label", (
    tester,
  ) async {
    final fixture = _linkCollectionFixture(withPartialLinks: true);
    await tester.pumpTestApp(child: fixture.widget);

    expect(find.text("Target Alpha"), findsOneWidget);
    expect(find.text(fixture.target.value), findsNothing);
    expect(find.byTooltip("Clear link"), findsOneWidget);
    expect(find.byType(DepthBox), findsWidgets);
  });

  testWidgets("keeps selected link identity beside compact row actions", (
    tester,
  ) async {
    final fixture = _linkCollectionFixture(
      withPartialLinks: true,
      adaptiveAppearance: true,
    );
    await tester.pumpTestApp(
      child: SizedBox(width: 376, child: fixture.widget),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text("Target Alpha"), findsOneWidget);
    expect(find.byTooltip("Change linked resource"), findsOneWidget);
    expect(find.byTooltip("Clear link"), findsOneWidget);
    expect(find.byTooltip("Remove item"), findsNWidgets(2));
    expect(find.text("Change"), findsNothing);
  });

  testWidgets("frames a link collection once with explicit reorder handles", (
    tester,
  ) async {
    final fixture = _linkCollectionFixture(
      withPartialLinks: true,
      directCollection: true,
      label: "Related nodes",
    );
    await tester.pumpTestApp(child: fixture.widget);
    await tester.pumpAndSettle();

    expect(find.text("Related nodes"), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget.runtimeType.toString() == "_AuthoredReorderHandle",
      ),
      findsNWidgets(2),
    );
  });

  test("known link edits preserve an unfinished sibling", () {
    final removing = _linkCollectionFixture(withPartialLinks: true);

    replacePortableLinkCollection(
      draft: removing.document,
      catalog: removing.catalog,
      resource: _resource,
      field: "links",
      expected: [removing.target],
      proposed: const [],
    );

    expect(removing.document.disconnections, hasLength(1));
    expect(
      removing.document.disconnections.single.id.location.path.segments.last,
      types.PathSegment.createItem(id: _knownLinkItem),
    );
    expect(removing.document.connections, isEmpty);

    final adding = _linkCollectionFixture(withPartialLinks: true);
    replacePortableLinkCollection(
      draft: adding.document,
      catalog: adding.catalog,
      resource: _resource,
      field: "links",
      expected: [adding.target],
      proposed: [adding.target, adding.secondTarget],
    );

    expect(adding.document.disconnections, isEmpty);
    expect(adding.document.connections, hasLength(1));
    expect(adding.document.connections.single.target, adding.secondTarget);
    expect(
      adding.document.connections.single.source.id.location.path.segments.last,
      isNot(types.PathSegment.createItem(id: _unfinishedLinkItem)),
    );
  });

  testWidgets("an Unfilled polymorphic control offers its concrete forms", (
    tester,
  ) async {
    final document = _TestAuthoringDocument(
      defaultFactory: (_) => types.DataValue.unfilled,
      resources: {
        _resource: types.AuthoringRecord(
          configuration: types.TypeSelection.unknown,
          fields: const [],
        ),
      },
    );
    catalog.InitializationRequest? request;
    await tester.pumpTestApp(
      child: Material(
        child: PortablePresentationNodeRenderer(
          node: _polymorphicNode,
          scope: PortablePresentationScope(
            bindings: {
              _bindingId: PortableExpressionBinding(
                value: types.DataValue.unfilled,
                location: types.ValueLocation(
                  resource: _resource,
                  path: types.ValuePath(segments: const []),
                ),
              ),
            },
            budget: expression.EvaluationBudget(
              maxSteps: 100,
              maxCollectionItems: 100,
            ),
            setBinding: (_, _) {},
            authoring: document,
            catalog: _polymorphicCatalog,
            prepareCreation: (value) async {
              request = value;
              return catalog.PreparedCreation(
                record: types.AuthoringRecord(
                  configuration: value.type,
                  fields: [
                    types.FieldValue(
                      name: "value",
                      value: types.DataValue.wrapStringValue(""),
                    ),
                  ],
                ),
                findings: const [],
              );
            },
          ),
        ),
      ),
    );

    expect(find.text("Icon form"), findsOneWidget);
    expect(find.text("Choose a type"), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<int>), findsNothing);
    await tester.tap(find.text("Choose a type"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Iconify").last);
    await tester.pumpAndSettle();

    expect(request?.type, types.TypeSelection.wrapComplete(_iconifyType));
    expect(document.preparedApplications, hasLength(1));
  });

  testWidgets("hierarchy sequences preserve branches spacing and flattening", (
    tester,
  ) async {
    final itemBinding = types.ExpressionBindingId(value: "hierarchy.item");
    presentation.ConnectorStyle connector() => presentation.ConnectorStyle(
      stroke: presentation.ConnectorStroke(
        color: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapInteger("4286611584"),
        ),
        width: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapFloat(2),
        ),
      ),
      cornerRadius: expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapFloat(6),
      ),
      startMarker: null,
      endMarker: null,
    );
    presentation.PresentationNode hierarchy(List<String> values) => _node(
      "hierarchy",
      presentation.PresentationElement.createRepeated(
        source: expression.ExpressionNode.wrapLiteral(
          types.DataValue.createListValue(
            items: [
              for (final (index, value) in values.indexed)
                types.ListItem(
                  id: types.ItemId(value: "hierarchy:$index"),
                  value: types.DataValue.wrapStringValue(value),
                ),
            ],
          ),
        ),
        itemBindingId: itemBinding,
        presentation: presentation.SequencePresentation(
          item: _node(
            "hierarchy.item",
            presentation.PresentationElement.createText(
              value: expression.ExpressionNode.createRead(
                binding: itemBinding,
                path: types.ValuePath(segments: const []),
              ),
              color: null,
              fontSize: null,
              fontWeight: null,
              fontItalic: null,
              fontOpticalSize: null,
              fontSlant: null,
              fontWidth: null,
              textAlignment: null,
              lineHeight: null,
              letterSpacing: null,
              decoration: null,
              semanticLabel: null,
              paragraph: presentation.TextParagraph.defaultInstance,
            ),
          ),
          empty: null,
          separator: null,
          layout: presentation.SequenceLayout.createHierarchy(
            unaryConnector: connector(),
            trunkConnector: connector(),
            branchConnector: connector(),
            itemSpacing: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapFloat(20),
            ),
            indentation: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapFloat(24),
            ),
            leadingSpacing: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapFloat(12),
            ),
            itemAnchor: presentation.ConnectorAnchor.center,
            flattenSingleItem: expression.ExpressionNode.wrapLiteral(
              types.DataValue.wrapBoolean(true),
            ),
            crossAxisAlignment: presentation.CrossAxisAlignment.stretch,
          ),
        ),
      ),
    );
    final scope = PortablePresentationScope(
      bindings: const {},
      budget: expression.EvaluationBudget(
        maxSteps: 100,
        maxCollectionItems: 100,
      ),
      setBinding: (_, _) {},
    );
    Future<void> pumpHierarchy(List<String> values) => tester.pumpTestApp(
      child: Material(
        child: SizedBox(
          width: 300,
          child: PortablePresentationNodeRenderer(
            node: hierarchy(values),
            scope: scope,
          ),
        ),
      ),
    );

    await pumpHierarchy(["First", "Second"]);
    await tester.pumpAndSettle();

    final hierarchyFinder = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == "_HierarchyRenderSurface",
    );
    expect(hierarchyFinder, findsOneWidget);
    final renderObject = tester.renderObject(hierarchyFinder) as dynamic;
    expect(renderObject.debugStrokes as List<Object?>, hasLength(3));
    final surface = tester.getRect(hierarchyFinder);
    final first = tester.getRect(find.text("First"));
    final second = tester.getRect(find.text("Second"));
    expect(first.left - surface.left, closeTo(24, 0.01));
    expect(second.top - first.bottom, closeTo(20, 0.01));

    await pumpHierarchy(["First"]);
    await tester.pumpAndSettle();

    final flattenedSurface = tester.getRect(hierarchyFinder);
    final flattened = tester.getRect(find.text("First"));
    expect(flattened.left - flattenedSurface.left, closeTo(0, 0.01));
    final flattenedRenderObject =
        tester.renderObject(hierarchyFinder) as dynamic;
    expect(flattenedRenderObject.debugStrokes as List<Object?>, hasLength(1));
  });
}

({Widget widget, _TestAuthoringDocument document}) _collectionFixture({
  required types.DataValue value,
  required bool allowAdd,
  String? label,
  String? description,
}) {
  final document = _TestAuthoringDocument(
    defaultFactory: (_) => types.DataValue.wrapStringValue(""),
  );
  final reference = binding.BindingRef(
    bindingId: _bindingId,
    path: types.ValuePath(
      segments: [types.PathSegment.createField(name: "items")],
    ),
  );
  return (
    document: document,
    widget: Material(
      child: PortablePresentationNodeRenderer(
        node: _node(
          "collection",
          presentation.PresentationElement.wrapListInput(
            presentation.ListControl(
              control: presentation.BoundControl(
                binding: reference,
                label: label == null
                    ? null
                    : expression.ExpressionNode.wrapLiteral(
                        types.DataValue.wrapStringValue(label),
                      ),
                description: description == null
                    ? null
                    : expression.ExpressionNode.wrapLiteral(
                        types.DataValue.wrapStringValue(description),
                      ),
                prefix: null,
                semanticLabel: null,
              ),
              itemPresentation: null,
              allowAdd: allowAdd,
              allowRemove: true,
              allowReorder: true,
              itemBindingId: types.ExpressionBindingId(value: "item"),
              indexBindingId: types.ExpressionBindingId(value: "index"),
            ),
          ),
        ),
        scope: _authoringScope(document, "items", value),
      ),
    ),
  );
}

({Widget widget, _TestAuthoringDocument document}) _mapFixture({
  String? label,
}) {
  final document = _TestAuthoringDocument(
    defaultFactory: (_) => types.DataValue.wrapStringValue(""),
  );
  final reference = binding.BindingRef(
    bindingId: _bindingId,
    path: types.ValuePath(
      segments: [types.PathSegment.createField(name: "values")],
    ),
  );
  return (
    document: document,
    widget: Material(
      child: PortablePresentationNodeRenderer(
        node: _node(
          "map",
          presentation.PresentationElement.wrapMapInput(
            presentation.MapControl(
              control: presentation.BoundControl(
                binding: reference,
                label: label == null
                    ? null
                    : expression.ExpressionNode.wrapLiteral(
                        types.DataValue.wrapStringValue(label),
                      ),
                description: null,
                prefix: null,
                semanticLabel: null,
              ),
              keyPresentation: null,
              valuePresentation: null,
              allowAdd: true,
              allowRemove: true,
              keyBindingId: types.ExpressionBindingId(value: "key"),
              valueBindingId: types.ExpressionBindingId(value: "map_value"),
            ),
          ),
        ),
        scope: _authoringScope(document, "values", types.DataValue.unfilled),
      ),
    ),
  );
}

({
  Widget widget,
  _TestAuthoringDocument document,
  CheckedEditorCatalog catalog,
  types.ResourceId target,
  types.ResourceId secondTarget,
})
_linkCollectionFixture({
  bool withPartialLinks = false,
  bool directCollection = false,
  bool adaptiveAppearance = false,
  String? label,
}) {
  final rootDefinition = types.TypeDefinitionId(
    typeId: types.TypeId.createQualified(namespace: "test", name: "Node"),
    revision: 1,
  );
  final setDefinition = types.TypeDefinitionId(
    typeId: types.TypeId.createQualified(namespace: "test", name: "Links"),
    revision: 1,
  );
  final linkDefinition = types.TypeDefinitionId(
    typeId: types.TypeId.createQualified(namespace: "test", name: "NodeLink"),
    revision: 1,
  );
  final sourceEndpoint = types.EndpointId(value: "test.source");
  final targetEndpoint = types.EndpointId(value: "test.target");
  final rootUse = types.NamedTypeUse(
    definition: rootDefinition,
    arguments: const [],
  );
  final setUse = types.NamedTypeUse(
    definition: setDefinition,
    arguments: const [],
  );
  final linksOwner = types.FieldOwner(
    definition: rootDefinition,
    name: "links",
  );
  final rootTemplate = types.TypeTemplate.createNamed(
    definition: rootDefinition,
    arguments: const [],
  );
  final linkTemplate = types.TypeTemplate.createNamed(
    definition: linkDefinition,
    arguments: const [],
  );
  final setTemplate = types.TypeTemplate.createNamed(
    definition: setDefinition,
    arguments: const [],
  );
  final appearanceId = types.PresentationId(
    namespace: "test",
    name: "node.reference.option",
  );
  final appearanceTarget = catalog.PresentationTarget.createNamed(
    definition: rootDefinition,
    arguments: const [],
  );
  final appearanceText = _node(
    "node.reference.name",
    presentation.PresentationElement.createText(
      value: expression.ExpressionNode.createRead(
        binding: _configuredBindingId,
        path: types.ValuePath(
          segments: [types.PathSegment.createField(name: "name")],
        ),
      ),
      color: null,
      fontSize: null,
      fontWeight: null,
      fontItalic: null,
      fontOpticalSize: null,
      fontSlant: null,
      fontWidth: null,
      textAlignment: null,
      lineHeight: null,
      letterSpacing: null,
      decoration: null,
      semanticLabel: null,
      paragraph: presentation.TextParagraph.defaultInstance,
    ),
  );
  final appearanceIcon = _node(
    "node.reference.icon",
    presentation.PresentationElement.createIcon(
      name: expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapStringValue(
          '<svg xmlns="http://www.w3.org/2000/svg" '
          'viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
        ),
      ),
      semanticLabel: expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapStringValue("Node"),
      ),
      color: null,
      size: null,
    ),
  );
  final coloredIcon = _node(
    "node.reference.icon.color",
    presentation.PresentationElement.createContainer(
      child: _node(
        "node.reference.icon.padding",
        presentation.PresentationElement.createPadding(
          child: appearanceIcon,
          top: 6,
          start: 6,
          end: 6,
          bottom: 6,
        ),
      ),
      border: null,
      backgroundColor: expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapInteger("4288585374"),
      ),
      radius: presentation.PresentationRadius.none,
    ),
  );
  final appearanceCard = _node(
    "node.reference.card",
    presentation.PresentationElement.createAdaptiveLeading(
      leading: coloredIcon,
      center: appearanceText,
      suffix: null,
      padding: presentation.PresentationInsets.wrapAll(8),
      compactPadding: presentation.PresentationInsets.wrapAll(4),
      gap: 12,
      minimumCenterWidth: 80,
    ),
  );
  final appearanceLayout = _node(
    "node.reference.root",
    presentation.PresentationElement.wrapChildren(
      presentation.ChildrenElement.createColumn(
        children: [presentation.AxisChild.wrapFixed(appearanceCard)],
        layout: presentation.AxisChildrenLayout(
          spacing: 0,
          mainAxisAlignment: presentation.MainAxisAlignment.start,
          crossAxisAlignment: presentation.CrossAxisAlignment.start,
        ),
      ),
    ),
  );
  final collectionResourceBinding = types.ExpressionBindingId(
    value: "resource",
  );
  final collectionRowBinding = types.ExpressionBindingId(value: "row");
  final collectionDefinition = presentation.PresentationCollectionDefinition(
    sourceId: "nodes",
    rowType: rootTemplate,
    rowBindingId: collectionRowBinding,
    key: expression.ExpressionNode.createRead(
      binding: collectionResourceBinding,
      path: types.ValuePath(segments: const []),
    ),
    selectability: expression.ExpressionNode.wrapLiteral(
      types.DataValue.wrapBoolean(true),
    ),
    relations: const [],
    projection: null,
    resources: presentation.PresentationResourceCollection(
      root: rootDefinition,
      resourceBindingId: collectionResourceBinding,
      appearance: null,
    ),
  );
  final collectionMaterial = catalog.PresentationMaterial(
    provider: types.PresentationId(namespace: "test", name: "link.collection"),
    target: appearanceTarget,
    role: catalog.PresentationRole.inspector,
    layout: _compactNode,
    dependencies: presentation.PresentationDependencies(
      types: const [],
      presentations: const [],
      conversions: const [],
      capabilities: const [],
      collections: [collectionDefinition],
    ),
    subject: rootTemplate,
  );
  final checked = CheckedEditorCatalog(
    catalog.EditorCatalogWireSnapshot(
      generation: types.CatalogGeneration(value: "catalog:links"),
      types: [
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: rootDefinition,
            parameters: const [],
            representation: types.RepresentationTemplate.createRecord(
              fields: [
                types.FieldDeclaration(
                  owner: linksOwner,
                  type: setTemplate,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
              ],
              abstract_: false,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
          effectiveFields: [
            catalog.EffectiveFieldTemplate(
              key: "links",
              owner: linksOwner,
              type: setTemplate,
              rules: const [],
            ),
          ],
          ancestorTemplates: const [],
        ),
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: setDefinition,
            parameters: const [],
            representation: types.RepresentationTemplate.createSequence(
              item: linkTemplate,
              kind: types.CollectionKind.set_,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
          effectiveFields: const [],
          ancestorTemplates: const [],
        ),
        catalog.PublishedType(
          display: null,
          definition: types.TypeDefinition(
            id: linkDefinition,
            parameters: const [],
            representation: types.RepresentationTemplate.createLink(
              endpoint: sourceEndpoint,
              target: rootTemplate,
            ),
            parents: const [],
          ),
          status: catalog.DeclarationStatus.ready,
          effectiveFields: const [],
          ancestorTemplates: const [],
        ),
      ],
      relations: [
        catalog.RelationContract(
          id: types.RelationId(value: "test.links"),
          first: catalog.EndpointDefinition(
            id: sourceEndpoint,
            slot: catalog.EndpointSlot.first,
            resource: types.NamedTypeTemplate(
              definition: rootDefinition,
              arguments: const [],
            ),
            cardinality: catalog.EndpointCardinality.many,
            onDelete: catalog.RelationDeletePolicy.clear,
          ),
          second: catalog.EndpointDefinition(
            id: targetEndpoint,
            slot: catalog.EndpointSlot.second,
            resource: types.NamedTypeTemplate(
              definition: rootDefinition,
              arguments: const [],
            ),
            cardinality: catalog.EndpointCardinality.many,
            onDelete: catalog.RelationDeletePolicy.clear,
          ),
          families: const [],
        ),
      ],
      resourceDefinitions: const [],
      presentations: adaptiveAppearance
          ? [
              catalog.PresentationDescriptor(
                id: appearanceId,
                owner: types.DeclarationOwner.defaultInstance,
                target: appearanceTarget,
                roles: [catalog.PresentationRole.referenceOption],
                priority: 0,
              ),
            ]
          : const [],
      presentationMaterials: adaptiveAppearance
          ? [
              catalog.PresentationMaterial(
                provider: appearanceId,
                target: appearanceTarget,
                role: catalog.PresentationRole.referenceOption,
                layout: appearanceLayout,
                dependencies:
                    presentation.PresentationDependencies.defaultInstance,
                subject: rootTemplate,
              ),
            ]
          : const [],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: [
        catalog.EndpointBindingTemplate(
          endpoint: sourceEndpoint,
          containingResource: types.NamedTypeTemplate(
            definition: rootDefinition,
            arguments: const [],
          ),
          valueOwner: linkDefinition,
          relativePath: types.RelativeFieldPattern(
            segments: [
              types.FieldPatternSegment.createField(name: "links"),
              types.FieldPatternSegment.items,
            ],
          ),
          target: rootTemplate,
          containsCollection: true,
        ),
      ],
      capabilities: const [],
      recommendations: const [],
      roleFallbacks: const [],
    ),
  );
  final target = types.ResourceId(value: "resource:target");
  final secondTarget = types.ResourceId(value: "resource:second-target");
  final items = withPartialLinks
      ? [
          types.ListItem(
            id: _knownLinkItem,
            value: types.DataValue.createLink(
              endpoint: sourceEndpoint,
              target: types.LinkTarget(resource: target, opposite: null),
            ),
          ),
          types.ListItem(
            id: _unfinishedLinkItem,
            value: types.DataValue.unfilled,
          ),
        ]
      : const <types.ListItem>[];
  final sourceRecord = types.AuthoringRecord(
    configuration: types.TypeSelection.wrapComplete(rootUse),
    fields: [
      types.FieldValue(
        name: "links",
        value: types.DataValue.createNamed(
          actualType: setUse,
          payload: types.DataValue.createSetValue(items: items),
        ),
      ),
    ],
  );
  types.AuthoringRecord targetRecord(String name) => types.AuthoringRecord(
    configuration: types.TypeSelection.wrapComplete(rootUse),
    fields: [
      types.FieldValue(
        name: "name",
        value: types.DataValue.wrapStringValue(name),
      ),
      types.FieldValue(
        name: "links",
        value: types.DataValue.createNamed(
          actualType: setUse,
          payload: types.DataValue.createSetValue(items: const []),
        ),
      ),
    ],
  );
  final document = _TestAuthoringDocument(
    defaultFactory: (_) => types.DataValue.unfilled,
    resources: {
      _resource: sourceRecord,
      target: targetRecord("Target Alpha"),
      secondTarget: targetRecord("Target Beta"),
    },
  );
  final rootBinding = types.ExpressionBindingId(value: "root");
  final itemBinding = types.ExpressionBindingId(value: "item");
  final collectionReference = binding.BindingRef(
    bindingId: rootBinding,
    path: types.ValuePath(
      segments: [types.PathSegment.createField(name: "links")],
    ),
  );
  return (
    document: document,
    catalog: checked,
    target: target,
    secondTarget: secondTarget,
    widget: Material(
      child: PortablePresentationNodeRenderer(
        node: directCollection
            ? _node(
                "links.direct",
                presentation.PresentationElement.wrapLinkInput(
                  presentation.LinkControl(
                    control: presentation.BoundControl(
                      binding: collectionReference,
                      label: label == null
                          ? null
                          : expression.ExpressionNode.wrapLiteral(
                              types.DataValue.wrapStringValue(label),
                            ),
                      description: null,
                      prefix: null,
                      semanticLabel: null,
                    ),
                    allowReorder: true,
                    candidatePolicy: null,
                    rejectionDisplay:
                        presentation.LinkRejectionDisplay.disabled,
                    sourceId: null,
                  ),
                ),
              )
            : _node(
                "links",
                presentation.PresentationElement.wrapSetInput(
                  presentation.SetControl(
                    control: _boundControl(collectionReference),
                    itemPresentation: _node(
                      "link.item",
                      presentation.PresentationElement.wrapLinkInput(
                        presentation.LinkControl(
                          control: _boundControl(
                            binding.BindingRef(
                              bindingId: itemBinding,
                              path: types.ValuePath(segments: const []),
                            ),
                          ),
                          allowReorder: false,
                          candidatePolicy: null,
                          rejectionDisplay:
                              presentation.LinkRejectionDisplay.disabled,
                          sourceId: adaptiveAppearance ? "nodes" : null,
                        ),
                      ),
                    ),
                    allowAdd: true,
                    allowRemove: true,
                    itemBindingId: itemBinding,
                  ),
                ),
              ),
        scope: PortablePresentationScope(
          bindings: {
            rootBinding: PortableExpressionBinding(
              value: types.DataValue.createRecord(fields: sourceRecord.fields),
              location: types.ValueLocation(
                resource: _resource,
                path: types.ValuePath(segments: const []),
              ),
            ),
          },
          budget: expression.EvaluationBudget(
            maxSteps: 100,
            maxCollectionItems: 100,
          ),
          setBinding: (_, _) {},
          authoring: document,
          catalog: checked,
          material: adaptiveAppearance ? collectionMaterial : null,
        ),
      ),
    ),
  );
}

PortablePresentationScope _authoringScope(
  _TestAuthoringDocument document,
  String field,
  types.DataValue value,
) => PortablePresentationScope(
  bindings: {
    _bindingId: PortableExpressionBinding(
      value: types.DataValue.createRecord(
        fields: [types.FieldValue(name: field, value: value)],
      ),
      location: types.ValueLocation(
        resource: _resource,
        path: types.ValuePath(segments: const []),
      ),
    ),
  },
  budget: expression.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
  setBinding: (_, _) {},
  authoring: document,
);

presentation.BoundControl _boundControl(binding.BindingRef reference) =>
    presentation.BoundControl(
      binding: reference,
      label: null,
      description: null,
      prefix: null,
      semanticLabel: null,
    );

final class _TestPortableHost extends ChangeNotifier
    implements PortablePresentationHost {
  _TestPortableHost({
    required presentation.PresentationNode root,
    this.rejectWrites = false,
    catalog.PresentationRole? role,
  }) : _document = PortablePresentationDocument(
         catalog: CheckedEditorCatalog(
           catalog.EditorCatalogWireSnapshot.defaultInstance,
         ),
         root: root,
         bindings: {
           _bindingId: PortablePresentationBinding(
             schema: PortablePresentationBindingSchema.complete(_integerType),
             value: types.DataValue.wrapInteger("2"),
             editable: true,
           ),
         },
         budget: expression.EvaluationBudget(
           maxSteps: 100,
           maxCollectionItems: 100,
         ),
         role: role,
       );

  final bool rejectWrites;
  PortablePresentationDocument _document;
  final List<(binding.BindingRef, types.DataValue)> writes = [];
  final List<action.EditorAction> actions = [];
  int expectedTypeReads = 0;

  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();

  @override
  PortablePresentationDocument get document => _document;

  @override
  bool get enabled => true;

  @override
  bool get readOnly => false;

  @override
  Future<PortablePresentationWriteResult> execute(
    action.EditorAction editorAction,
  ) async {
    actions.add(editorAction);
    return const PortablePresentationWriteResult.applied();
  }

  @override
  types.TypeUse? expectedType(binding.BindingRef reference) {
    expectedTypeReads++;
    return _integerType;
  }

  @override
  types.ValueLocation? location(binding.BindingRef reference) => null;

  @override
  types.DataValue? read(binding.BindingRef reference) =>
      _document.bindings[reference.bindingId]?.value;

  @override
  Future<PortablePresentationWriteResult> write(
    binding.BindingRef reference,
    types.DataValue value,
  ) async {
    writes.add((reference, value));
    if (rejectWrites) {
      return const PortablePresentationWriteResult.rejected(
        "The document rejected this write",
      );
    }
    final current = _document.bindings[_bindingId]!;
    _document = PortablePresentationDocument(
      catalog: _document.catalog,
      root: _document.root,
      bindings: {
        ..._document.bindings,
        _bindingId: current.copyWith(value: value),
      },
      budget: _document.budget,
      role: _document.role,
      material: _document.material,
      activePresentations: _document.activePresentations,
      slots: _document.slots,
    );
    notifyListeners();
    return const PortablePresentationWriteResult.applied();
  }
}

final class _TestAuthoringDocument implements PortableAuthoringDocument {
  _TestAuthoringDocument({
    required this.defaultFactory,
    this.resources = const {},
  });

  final types.DataValue Function(types.TypeUse? type) defaultFactory;
  @override
  final Map<types.ResourceId, types.AuthoringRecord> resources;
  final List<({types.ValueLocation location, types.ListItem item})> insertions =
      [];
  final List<List<types.MapRow>> maps = [];
  final List<
    ({
      authoring.LinkOccurrence source,
      types.ResourceId target,
      authoring.CounterpartChoice? counterpart,
    })
  >
  connections = [];
  final List<catalog.InitializationRequest> preparedApplications = [];
  final List<authoring.LinkOccurrence> disconnections = [];

  @override
  types.CatalogGeneration get generation =>
      types.CatalogGeneration(value: "catalog:test");

  @override
  List<authoring.LinkProjection> get links => const [];

  @override
  List<diagnostic.InitializationDiagnostic> get initializationFindings =>
      const [];

  @override
  int get operationCount => insertions.length + maps.length;

  @override
  types.DataValue defaultValue(types.TypeUse? type) => defaultFactory(type);

  @override
  types.AuthoringRecord? resource(types.ResourceId id) => resources[id];

  @override
  PortablePathResult<types.DataValue> read(types.ValueLocation location) =>
      const PortablePathUnavailable("No stored value");

  @override
  PortablePathResult<types.AuthoringRecord> set(
    types.ValueLocation location,
    types.DataValue value,
  ) => PortablePathValue(_emptyRecord);

  @override
  PortablePathResult<types.AuthoringRecord> insert(
    types.ValueLocation location,
    types.ItemId? after,
    types.ListItem item,
  ) {
    insertions.add((location: location, item: item));
    return PortablePathValue(_emptyRecord);
  }

  @override
  PortablePathResult<types.AuthoringRecord> insertPrepared(
    types.ValueLocation location,
    types.ItemId? after,
    types.ItemId item,
    catalog.InitializationRequest request,
    catalog.PreparedCreation prepared,
  ) => insert(
    location,
    after,
    types.ListItem(id: item, value: types.DataValue.unfilled),
  );

  @override
  PortablePathResult<types.AuthoringRecord> remove(
    types.ValueLocation location,
    types.ItemId item,
  ) => PortablePathValue(_emptyRecord);

  @override
  PortablePathResult<types.AuthoringRecord> move(
    types.ValueLocation location,
    types.ItemId item,
    types.ItemId? after,
  ) => PortablePathValue(_emptyRecord);

  @override
  PortablePathResult<types.AuthoringRecord> replaceMap(
    types.ValueLocation location,
    Iterable<types.MapRow> rows,
  ) {
    maps.add(rows.toList(growable: false));
    return PortablePathValue(_emptyRecord);
  }

  @override
  PortablePathResult<types.AuthoringRecord> applyPreparedRecord(
    types.ValueLocation location,
    catalog.InitializationRequest request,
    catalog.PreparedCreation prepared,
  ) {
    preparedApplications.add(request);
    return PortablePathValue(_emptyRecord);
  }

  @override
  bool stageExpressionEdit(
    Iterable<PortableExpressionRead> reads,
    bool Function(PortableAuthoringDocument document) edit,
  ) => edit(this);

  @override
  void delete(types.ResourceId id) {}

  @override
  void connect(
    authoring.LinkOccurrence source,
    types.ResourceId target, {
    authoring.CounterpartChoice? counterpart,
  }) {
    connections.add((source: source, target: target, counterpart: counterpart));
  }

  @override
  void disconnect(authoring.LinkOccurrence occurrence) {
    disconnections.add(occurrence);
  }
}

final _bindingId = types.ExpressionBindingId(value: "value");
final _resource = types.ResourceId(value: "resource:test");
final _knownLinkItem = types.ItemId(value: "link:known");
final _unfinishedLinkItem = types.ItemId(value: "link:unfinished");
final _emptyRecord = types.AuthoringRecord(
  configuration: types.TypeSelection.unknown,
  fields: const [],
);
final _reference = binding.BindingRef(
  bindingId: _bindingId,
  path: types.ValuePath(segments: const []),
);
final _integerType = types.TypeUse.wrapScalar(
  types.ScalarKind.createInteger(width: types.IntegerWidth.signedThirtyTwo),
);
final _iconifyDefinition = types.TypeDefinitionId(
  typeId: types.TypeId.createQualified(namespace: "test", name: "Iconify"),
  revision: 1,
);
final _iconifyType = types.NamedTypeUse(
  definition: _iconifyDefinition,
  arguments: const [],
);
final _iconifyPresentation = types.PresentationId(
  namespace: "test",
  name: "iconify.inspector",
);
final _configuredBindingId = types.ExpressionBindingId(
  value: "configured_value",
);
final _configuredValueReference = binding.BindingRef(
  bindingId: _configuredBindingId,
  path: types.ValuePath(
    segments: [types.PathSegment.createField(name: "value")],
  ),
);
final _control = presentation.BoundControl(
  binding: _reference,
  label: null,
  description: null,
  prefix: null,
  semanticLabel: null,
);
final _numericNode = _node(
  "numeric",
  presentation.PresentationElement.wrapNumericInput(_control),
);
final _polymorphicNode = _node(
  "polymorphic",
  presentation.PresentationElement.createPolymorphicInput(
    control: presentation.BoundControl(
      binding: _reference,
      label: expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapStringValue("Icon form"),
      ),
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
    concreteTypes: [
      presentation.ConcreteTypePresentation(
        concreteType: types.TypeUse.wrapNamed(_iconifyType),
        label: expression.ExpressionNode.wrapLiteral(
          types.DataValue.wrapStringValue("Iconify"),
        ),
        presentation: _node(
          "polymorphic.iconify",
          presentation.PresentationElement.createInvocation(
            presentationId: _iconifyPresentation,
            arguments: const [],
          ),
        ),
      ),
    ],
  ),
);
final _polymorphicCatalog = CheckedEditorCatalog(
  catalog.EditorCatalogWireSnapshot(
    generation: types.CatalogGeneration(value: "test"),
    types: [
      catalog.PublishedType(
        display: null,
        definition: types.TypeDefinition(
          id: _iconifyDefinition,
          parameters: const [],
          representation: types.RepresentationTemplate.createRecord(
            fields: const [],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: catalog.DeclarationStatus.ready,
        effectiveFields: const [],
        ancestorTemplates: const [],
      ),
    ],
    relations: const [],
    resourceDefinitions: const [],
    presentations: const [],
    presentationMaterials: [
      catalog.PresentationMaterial(
        provider: _iconifyPresentation,
        target: catalog.PresentationTarget.createNamed(
          definition: _iconifyDefinition,
          arguments: const [],
        ),
        role: catalog.PresentationRole.inspector,
        layout: _node(
          "iconify.value",
          presentation.PresentationElement.createTextInput(
            control: presentation.BoundControl(
              binding: _configuredValueReference,
              label: expression.ExpressionNode.wrapLiteral(
                types.DataValue.wrapStringValue("Icon"),
              ),
              description: null,
              prefix: null,
              semanticLabel: null,
            ),
            multiline: false,
            placeholder: null,
            inputFormatters: const [],
          ),
        ),
        dependencies: presentation.PresentationDependencies.defaultInstance,
        subject: types.TypeTemplate.createNamed(
          definition: _iconifyDefinition,
          arguments: const [],
        ),
      ),
    ],
    configuration: const [],
    diagnostics: const [],
    initialization: const [],
    endpointBindings: const [],
    capabilities: const [],
    recommendations: const [],
    roleFallbacks: const [],
  ),
);
final _actionNode = _node(
  "action.root",
  presentation.PresentationElement.wrapChildren(
    presentation.ChildrenElement.createColumn(
      children: [
        presentation.AxisChild.wrapFixed(_numericNode),
        presentation.AxisChild.wrapFixed(
          _node(
            "action.button",
            presentation.PresentationElement.createButton(
              label: expression.ExpressionNode.wrapLiteral(
                types.DataValue.wrapStringValue("Run action"),
              ),
              action: action.EditorAction.wrapLocal(
                action.LocalEditorAction.createSetValue(
                  target: _reference,
                  value: expression.ExpressionNode.wrapLiteral(
                    types.DataValue.wrapInteger("9"),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      layout: presentation.AxisChildrenLayout(
        spacing: 8,
        mainAxisAlignment: presentation.MainAxisAlignment.start,
        crossAxisAlignment: presentation.CrossAxisAlignment.stretch,
      ),
    ),
  ),
);
final _compactNode = _node(
  "compact.root",
  presentation.PresentationElement.createText(
    value: expression.ExpressionNode.wrapLiteral(
      types.DataValue.wrapStringValue("Compact card"),
    ),
    color: null,
    fontSize: null,
    fontWeight: null,
    fontItalic: null,
    fontOpticalSize: null,
    fontSlant: null,
    fontWidth: null,
    textAlignment: null,
    lineHeight: null,
    letterSpacing: null,
    decoration: null,
    semanticLabel: null,
    paragraph: presentation.TextParagraph.defaultInstance,
  ),
);
final _headerNode = presentation.PresentationNode(
  nodeId: "header.root",
  properties: presentation.PresentationProperties.defaultInstance,
  element: presentation.PresentationElement.wrapNumericInput(
    presentation.BoundControl(
      binding: _reference,
      label: expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapStringValue("Count"),
      ),
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
  ),
  header: presentation.PresentationHeader(
    binding: _reference,
    title: presentation.PresentationHeaderTitle.wrapText(
      expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapStringValue("Document"),
      ),
    ),
    description: expression.ExpressionNode.wrapLiteral(
      types.DataValue.wrapStringValue("Document description"),
    ),
    initiallyExpanded: true,
    items: const [],
    headerPadding: null,
    contentPadding: null,
  ),
);
final _matchingHeaderNode = presentation.PresentationNode(
  nodeId: "matching.header.root",
  properties: presentation.PresentationProperties.defaultInstance,
  element: presentation.PresentationElement.wrapNumericInput(
    presentation.BoundControl(
      binding: _reference,
      label: expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapStringValue("Count"),
      ),
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
  ),
  header: presentation.PresentationHeader(
    binding: _reference,
    title: presentation.PresentationHeaderTitle.wrapText(
      expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapStringValue("Count"),
      ),
    ),
    description: null,
    initiallyExpanded: true,
    items: const [],
    headerPadding: null,
    contentPadding: null,
  ),
);
final _overflowHeaderNode = presentation.PresentationNode(
  nodeId: "overflow.header.root",
  properties: presentation.PresentationProperties.defaultInstance,
  element: presentation.PresentationElement.wrapNumericInput(_control),
  header: presentation.PresentationHeader(
    binding: _reference,
    title: presentation.PresentationHeaderTitle.wrapText(
      expression.ExpressionNode.wrapLiteral(
        types.DataValue.wrapStringValue("Document with actions"),
      ),
    ),
    description: null,
    initiallyExpanded: null,
    items: [
      for (var index = 0; index < 6; index++)
        presentation.HeaderItem.createButton(
          itemId: presentation.HeaderItemId(
            namespace: "test",
            name: "action.$index",
          ),
          icon: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue("edit"),
          ),
          label: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue("Action $index"),
          ),
          tooltip: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapStringValue("Action $index"),
          ),
          action: action.EditorAction.wrapLocal(
            action.LocalEditorAction.createSetValue(
              target: _reference,
              value: expression.ExpressionNode.wrapLiteral(
                types.DataValue.wrapInteger(index.toString()),
              ),
            ),
          ),
          priority: null,
          visibleIf: null,
          enabledIf: null,
          tone: presentation.HeaderActionTone.neutral,
          confirmation: null,
          placement: presentation.HeaderActionPlacement.end,
        ),
    ],
    headerPadding: null,
    contentPadding: null,
  ),
);

presentation.PresentationNode _node(
  String id,
  presentation.PresentationElement element,
) => presentation.PresentationNode(
  nodeId: id,
  properties: presentation.PresentationProperties.defaultInstance,
  element: element,
  header: null,
);
