import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("relative time refreshes without a new host snapshot", (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 5, 12);
    final host = _TestPortableHost(
      root: skir.PresentationNode(
        nodeId: "relative",
        properties: skir.PresentationProperties.defaultInstance,
        header: null,
        element: skir.PresentationElement.createRelativeTime(
          value: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapTimestamp(now),
          ),
          style: skir.RelativeTimeStyle.natural,
          timeZone: skir.DateTimeZone.utc,
        ),
      ),
    );
    addTearDown(host.dispose);
    await withClock(Clock(() => now), () async {
      await tester.pumpTestApp(
        child: Material(child: PortablePresentationRenderer(host: host)),
      );
      expect(find.text("Just now"), findsOneWidget);
      now = now.add(const Duration(minutes: 1));
      await tester.pump(const Duration(minutes: 1));
      expect(find.text("1 minute ago"), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });

  testWidgets("grid cells keep their content height", (tester) async {
    final host = _TestPortableHost(
      root: skir.PresentationNode(
        nodeId: "grid",
        properties: skir.PresentationProperties.defaultInstance,
        header: null,
        element: skir.PresentationElement.wrapChildren(
          skir.ChildrenElement.createGrid(
            layout: skir.GridChildrenLayout(
              columns: 2,
              horizontalSpacing: 12,
              verticalSpacing: 12,
            ),
            children: [
              _visualText("grid.first", "Alpha"),
              _visualText("grid.second", "Beta"),
              _visualText("grid.third", "Gamma"),
            ],
          ),
        ),
      ),
    );
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(
        child: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 600,
            child: PortablePresentationRenderer(host: host),
          ),
        ),
      ),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey("grid.first"))).height,
      lessThan(100),
    );
    expect(
      tester.getTopLeft(find.text("Gamma")).dy -
          tester.getTopLeft(find.text("Alpha")).dy,
      lessThan(100),
    );
    expect(
      tester.getTopLeft(find.text("Beta")).dx,
      greaterThan(tester.getTopLeft(find.text("Alpha")).dx),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets("text content retains inherited typography", (tester) async {
    final host = _TestPortableHost(
      root: _visualText("typography", "Inherited text"),
    );
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );
    final text = find.text("Inherited text");
    expect(
      tester.widget<Text>(text).style?.fontFamily,
      DefaultTextStyle.of(tester.element(text)).style.fontFamily,
    );
  });

  testWidgets("section surfaces include their collapsible headers", (
    tester,
  ) async {
    final host = _TestPortableHost(
      root: skir.PresentationNode(
        nodeId: "section",
        properties: skir.PresentationProperties.defaultInstance,
        element: skir.PresentationElement.createSection(
          child: _visualText("section.body", "Section body"),
          border: null,
        ),
        header: skir.PresentationHeader(
          binding: null,
          title: skir.PresentationHeaderTitle.wrapText(
            skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("Section title"),
            ),
          ),
          description: null,
          initiallyExpanded: true,
          items: const [],
          headerPadding: null,
          contentPadding: null,
        ),
      ),
    );
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );
    expect(
      find.ancestor(
        of: find.text("Section title"),
        matching: find.byType(DepthBox),
      ),
      findsOneWidget,
    );
    await tester.tap(find.byTooltip("Collapse"));
    await tester.pump();
    expect(find.text("Section body"), findsNothing);
    await tester.tap(find.byTooltip("Expand"));
    await tester.pump();
    expect(find.text("Section body"), findsOneWidget);
  });

  testWidgets("statuses preserve the source label and distinct visual tone", (
    tester,
  ) async {
    final host = _TestPortableHost(
      root: skir.PresentationNode(
        nodeId: "status",
        properties: skir.PresentationProperties.defaultInstance,
        header: null,
        element: skir.PresentationElement.createStatus(
          value: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Connected"),
          ),
          cases: [
            skir.StatusCase(
              match: skir.DataValue.wrapStringValue("Connected"),
              appearance: skir.StatusAppearance(
                tone: skir.StatusTone.online,
                label: null,
              ),
            ),
          ],
          fallback: null,
        ),
      ),
    );
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );
    expect(find.text("Connected"), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    final context = tester.element(find.text("Connected"));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.cloud_done_outlined)).color,
      context.colors.online,
    );
    expect(
      tester.widget<Text>(find.text("Connected")).style?.color,
      context.colors.online,
    );
  });

  testWidgets("enum statuses use their value as the default label", (
    tester,
  ) async {
    final host = _TestPortableHost(
      root: skir.PresentationNode(
        nodeId: "status",
        properties: skir.PresentationProperties.defaultInstance,
        header: null,
        element: skir.PresentationElement.createStatus(
          value: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapEnumCase("Connected"),
          ),
          cases: [
            skir.StatusCase(
              match: skir.DataValue.wrapEnumCase("Connected"),
              appearance: skir.StatusAppearance(
                tone: skir.StatusTone.online,
                label: null,
              ),
            ),
          ],
          fallback: null,
        ),
      ),
    );
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Material(child: PortablePresentationRenderer(host: host)),
    );
    expect(find.text("Connected"), findsOneWidget);
    expect(find.byIcon(Icons.cloud_done_outlined), findsOneWidget);
    final context = tester.element(find.text("Connected"));
    expect(
      tester.widget<Icon>(find.byIcon(Icons.cloud_done_outlined)).color,
      context.colors.online,
    );
    expect(
      tester.widget<Text>(find.text("Connected")).style?.color,
      context.colors.online,
    );
  });

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
    expect(host.writes.single.$2, skir.DataValue.wrapInteger("7"));
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
              skir.DiagnosticTemplate(
                code: "compact_error",
                message: "Compact problem",
                severity: skir.DiagnosticSeverity.error,
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
      skir.PresentationRole.editor,
      skir.PresentationRole.inspector,
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
            skir.DiagnosticTemplate(
              code: "informational",
              message: "This value was inferred",
              severity: skir.DiagnosticSeverity.information,
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
    expect(find.byType(ValidatedTextField<skir.DataValue>), findsOneWidget);
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
            skir.PresentationElement.createIcon(
              name: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue(
                  '<svg xmlns="http://www.w3.org/2000/svg" '
                  'viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
                ),
              ),
              semanticLabel: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue("Book icon"),
              ),
              color: skir.PresentationColor.wrapValue(
                skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapInteger(color.toARGB32().toString()),
                ),
              ),
              size: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapFloat(28),
              ),
            ),
          ),
          scope: PortablePresentationScope(
            bindings: const {},
            budget: skir.EvaluationBudget(
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

    skir.PresentationNode tagCard(String tagName) {
      final label = tagName.isEmpty ? "Unnamed tag" : tagName;
      final icon = _node(
        "tag.icon",
        skir.PresentationElement.createIcon(
          name: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue(
              '<svg xmlns="http://www.w3.org/2000/svg" '
              'viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
            ),
          ),
          semanticLabel: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Tag"),
          ),
          color: null,
          size: null,
        ),
      );
      final coloredIcon = _node(
        "tag.icon.color",
        skir.PresentationElement.createContainer(
          foregroundColor: null,
          transitionMilliseconds: 0,
          child: _node(
            "tag.icon.padding",
            skir.PresentationElement.createPadding(
              child: icon,
              top: 6,
              start: 6,
              end: 6,
              bottom: 6,
            ),
          ),
          border: null,
          backgroundColor: skir.PresentationColor.wrapValue(
            skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapInteger("4288585374"),
            ),
          ),
          radius: skir.PresentationRadius.none,
        ),
      );
      final center = _node(
        "tag.name",
        skir.PresentationElement.createText(
          value: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue(label),
          ),
          color: null,
          sizing: null,
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
          paragraph: skir.TextParagraph.defaultInstance,
        ),
      );
      final card = _node(
        "tag.card",
        skir.PresentationElement.createAdaptiveLeading(
          leading: coloredIcon,
          center: center,
          suffix: null,
          padding: skir.PresentationInsets.wrapAll(8),
          compactPadding: skir.PresentationInsets.wrapAll(4),
          gap: 12,
          minimumCenterWidth: 80,
        ),
      );
      return _node(
        "tag.root",
        skir.PresentationElement.wrapChildren(
          skir.ChildrenElement.createColumn(
            children: [skir.AxisChild.wrapFixed(card)],
            layout: skir.AxisChildrenLayout(
              spacing: 0,
              mainAxisAlignment: skir.MainAxisAlignment.start,
              crossAxisAlignment: skir.CrossAxisAlignment.start,
            ),
          ),
        ),
      );
    }

    final scope = PortablePresentationScope(
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
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
    skir.PresentationNode textNode(skir.ExpressionNode weight) => _node(
      "styled.text",
      skir.PresentationElement.createText(
        value: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("Styled title"),
        ),
        color: skir.PresentationColor.wrapValue(
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger(color.toARGB32().toString()),
          ),
        ),
        sizing: skir.TextSizing.wrapExact(
          skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(22)),
        ),
        fontWeight: weight,
        fontItalic: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapFloat(1),
        ),
        fontOpticalSize: null,
        fontSlant: null,
        fontWidth: null,
        textAlignment: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("center"),
        ),
        lineHeight: null,
        letterSpacing: null,
        decoration: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("underline"),
        ),
        semanticLabel: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("Styled heading"),
        ),
        paragraph: skir.TextParagraph(
          maxLines: 1,
          overflow: skir.PresentationTextOverflow.ellipsis,
          softWrap: false,
          selectable: false,
          tone: skir.PresentationTextTone.primary,
        ),
      ),
    );
    final scope = PortablePresentationScope(
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      setBinding: (_, _) {},
    );
    await tester.pumpTestApp(
      child: Material(
        child: PortablePresentationNodeRenderer(
          node: textNode(
            skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(700)),
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
            skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapStringValue("heavy"),
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
          value: skir.DataValue.createNamed(
            actualType: _iconifyType,
            payload: skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(
                  name: "value",
                  value: skir.DataValue.wrapStringValue(
                    "material-symbols:book",
                  ),
                ),
              ],
            ),
          ),
        ),
      },
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
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
    final writes = <(skir.BindingRef, skir.DataValue)>[];
    final placementReference = skir.BindingRef(
      bindingId: _configuredBindingId,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: "placement")],
      ),
    );
    final xReference = skir.BindingRef(
      bindingId: _configuredBindingId,
      path: skir.ValuePath(segments: [skir.PathSegment.createField(name: "x")]),
    );
    final root = skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "placement",
          value: skir.DataValue.createNamed(
            actualType: skir.NamedTypeUse.defaultInstance,
            payload: skir.DataValue.createRecord(
              fields: [
                skir.FieldValue(
                  name: "x",
                  value: skir.DataValue.wrapInteger("4"),
                ),
              ],
            ),
          ),
        ),
      ],
    );
    final node = _node(
      "placement",
      skir.PresentationElement.createRecordInput(
        control: skir.BoundControl(
          binding: placementReference,
          label: null,
          description: null,
          prefix: null,
          semanticLabel: null,
        ),
        fieldPresentation: _node(
          "placement.x",
          skir.PresentationElement.wrapNumericInput(
            skir.BoundControl(
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
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
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
      skir.NamedTypeUse.defaultInstance,
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
      value: skir.DataValue.unfilled,
      allowAdd: true,
    );
    await tester.pumpTestApp(child: fixture.widget);

    expect(find.text("The collection binding is unavailable"), findsNothing);
    await tester.tap(find.text("Add item"));
    await tester.pump();

    final submitted = await _submit(tester, fixture.document);
    expect(submitted.intents, hasLength(1));
    expect(
      (submitted.intents.single as skir.EditIntent_insertWrapper)
          .value
          .item
          .value,
      skir.DataValue.wrapStringValue(""),
    );
  });

  testWidgets("empty collection controls retain their field guidance", (
    tester,
  ) async {
    final list = _collectionFixture(
      value: skir.DataValue.createListValue(items: const []),
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
      value: skir.DataValue.createListValue(items: const []),
      allowAdd: false,
    );
    await tester.pumpTestApp(child: fixture.widget);

    expect(find.text("Add item"), findsNothing);
    expect(fixture.document.workspace.state.groups, isEmpty);
  });

  testWidgets("adds a stable row to an Unfilled map", (tester) async {
    final fixture = _mapFixture();
    await tester.pumpTestApp(child: fixture.widget);

    expect(find.text("The map binding is unavailable"), findsNothing);
    await tester.tap(find.text("Add entry"));
    await tester.pump();

    final submitted = await _submit(tester, fixture.document);
    final row =
        ((submitted.intents.single as skir.EditIntent_setValueWrapper)
                    .value
                    .value
                    .authoredPayload
                as skir.DataValue_mapValueWrapper)
            .value
            .rows
            .single;
    expect(row.id.value, startsWith("panel:"));
    expect(row.key, skir.DataValue.wrapStringValue(""));
    expect(row.value, skir.DataValue.wrapStringValue(""));
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

    final submitted = await _submit(tester, fixture.document);
    final connection = submitted.intents
        .whereType<skir.EditIntent_connectRelationWrapper>()
        .single
        .value;
    expect(connection.target, fixture.target);
    expect(
      connection.source.id.location.path.segments.last,
      isA<skir.PathSegment_itemWrapper>(),
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

    expect(fixture.document.workspace.state.groups, isEmpty);
    expect(fixture.document.workspace.state.groups, isEmpty);
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

    final submitted = await _submit(tester, fixture.document);
    expect(
      submitted.intents
          .whereType<skir.EditIntent_connectRelationWrapper>()
          .single
          .value
          .target,
      fixture.secondTarget,
    );
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
    final fixture = _linkCollectionFixture(withPartialLinks: true);
    final branch = AuthoringEdit.fromDocument(
      fixture.document.workspace.document,
    );
    replacePortableLinkCollection(
      draft: branch,
      catalog: fixture.catalog,
      resource: _resource,
      field: "links",
      expected: [fixture.target],
      proposed: const [],
    );
    final remaining = branch
        .resource(_resource)!
        .authoredField("links")!
        .authoredItems!;
    expect(remaining.single.id, _unfinishedLinkItem);
    expect(remaining.single.value, skir.DataValue.unfilled);
    expect(
      branch.intents.single,
      isA<skir.EditIntent_disconnectRelationWrapper>(),
    );
  });

  testWidgets("an Unfilled polymorphic control offers its concrete forms", (
    tester,
  ) async {
    final document = _RendererWorkspace(
      catalog: _polymorphicCatalog,
      resources: {
        _resource: skir.AuthoringRecord(
          configuration: skir.TypeSelection.unknown,
          fields: [
            skir.FieldValue(name: "icon", value: skir.DataValue.unfilled),
          ],
        ),
      },
    );
    skir.InitializationRequest? request;
    await tester.pumpTestApp(
      child: Material(
        child: PortablePresentationNodeRenderer(
          node: _polymorphicNode,
          scope: PortablePresentationScope(
            bindings: {
              _bindingId: PortableExpressionBinding(
                value: skir.DataValue.unfilled,
                location: skir.ValueLocation(
                  resource: _resource,
                  path: skir.ValuePath(
                    segments: [skir.PathSegment.createField(name: "icon")],
                  ),
                ),
              ),
            },
            budget: skir.EvaluationBudget(
              maxSteps: 100,
              maxCollectionItems: 100,
            ),
            setBinding: (_, _) {},
            authoring: document.workspace.document,
            edit: document.binding,
            catalog: _polymorphicCatalog,
            prepareCreation: (value) async {
              request = value;
              return skir.PreparedCreation(
                record: skir.AuthoringRecord(
                  configuration: value.type,
                  fields: [
                    skir.FieldValue(
                      name: "value",
                      value: skir.DataValue.wrapStringValue(""),
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

    expect(request?.type, skir.TypeSelection.wrapComplete(_iconifyType));
    expect(
      document.workspace.document
          .resource(_resource)!
          .authoredField("icon")!
          .authoredActualType,
      _iconifyType,
    );
  });

  testWidgets("hierarchy sequences preserve branches spacing and flattening", (
    tester,
  ) async {
    final itemBinding = skir.ExpressionBindingId(value: "hierarchy.item");
    skir.ConnectorStyle connector() => skir.ConnectorStyle(
      stroke: skir.ConnectorStroke(
        color: skir.PresentationColor.wrapValue(
          skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapInteger("4286611584"),
          ),
        ),
        width: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(2)),
      ),
      cornerRadius: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapFloat(6),
      ),
      startMarker: null,
      endMarker: null,
    );
    skir.PresentationNode hierarchy(List<String> values) => _node(
      "hierarchy",
      skir.PresentationElement.createRepeated(
        source: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.createListValue(
            items: [
              for (final (index, value) in values.indexed)
                skir.ListItem(
                  id: skir.ItemId(value: "hierarchy:$index"),
                  value: skir.DataValue.wrapStringValue(value),
                ),
            ],
          ),
        ),
        itemBindingId: itemBinding,
        presentation: skir.SequencePresentation(
          item: _node(
            "hierarchy.item",
            skir.PresentationElement.createText(
              value: skir.ExpressionNode.createRead(
                binding: itemBinding,
                path: skir.ValuePath(segments: const []),
              ),
              color: null,
              sizing: null,
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
              paragraph: skir.TextParagraph.defaultInstance,
            ),
          ),
          empty: null,
          separator: null,
          layout: skir.SequenceLayout.createHierarchy(
            unaryConnector: connector(),
            trunkConnector: connector(),
            branchConnector: connector(),
            itemSpacing: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapFloat(20),
            ),
            indentation: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapFloat(24),
            ),
            leadingSpacing: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapFloat(12),
            ),
            itemAnchor: skir.ConnectorAnchor.center,
            flattenSingleItem: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(true),
            ),
            crossAxisAlignment: skir.CrossAxisAlignment.stretch,
          ),
        ),
      ),
    );
    final scope = PortablePresentationScope(
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
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

({Widget widget, _RendererWorkspace document}) _collectionFixture({
  required skir.DataValue value,
  required bool allowAdd,
  String? label,
  String? description,
}) {
  final document = _RendererWorkspace(
    catalog: _collectionCatalog(),
    resources: {_resource: _collectionRecord("items", value)},
  );
  final reference = skir.BindingRef(
    bindingId: _bindingId,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "items")],
    ),
  );
  return (
    document: document,
    widget: Material(
      child: PortablePresentationNodeRenderer(
        node: _node(
          "collection",
          skir.PresentationElement.wrapListInput(
            skir.ListControl(
              control: skir.BoundControl(
                binding: reference,
                label: label == null
                    ? null
                    : skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapStringValue(label),
                      ),
                description: description == null
                    ? null
                    : skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapStringValue(description),
                      ),
                prefix: null,
                semanticLabel: null,
              ),
              itemPresentation: null,
              allowAdd: allowAdd,
              allowRemove: true,
              allowReorder: true,
              itemBindingId: skir.ExpressionBindingId(value: "item"),
              indexBindingId: skir.ExpressionBindingId(value: "index"),
            ),
          ),
        ),
        scope: _authoringScope(document, "items", value),
      ),
    ),
  );
}

({Widget widget, _RendererWorkspace document}) _mapFixture({String? label}) {
  final document = _RendererWorkspace(
    catalog: _collectionCatalog(),
    resources: {
      _resource: _collectionRecord("values", skir.DataValue.unfilled),
    },
  );
  final reference = skir.BindingRef(
    bindingId: _bindingId,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "values")],
    ),
  );
  return (
    document: document,
    widget: Material(
      child: PortablePresentationNodeRenderer(
        node: _node(
          "map",
          skir.PresentationElement.wrapMapInput(
            skir.MapControl(
              control: skir.BoundControl(
                binding: reference,
                label: label == null
                    ? null
                    : skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapStringValue(label),
                      ),
                description: null,
                prefix: null,
                semanticLabel: null,
              ),
              keyPresentation: null,
              valuePresentation: null,
              allowAdd: true,
              allowRemove: true,
              keyBindingId: skir.ExpressionBindingId(value: "key"),
              valueBindingId: skir.ExpressionBindingId(value: "map_value"),
            ),
          ),
        ),
        scope: _authoringScope(document, "values", skir.DataValue.unfilled),
      ),
    ),
  );
}

({
  Widget widget,
  _RendererWorkspace document,
  CheckedEditorCatalog catalog,
  skir.ResourceId target,
  skir.ResourceId secondTarget,
})
_linkCollectionFixture({
  bool withPartialLinks = false,
  bool directCollection = false,
  bool adaptiveAppearance = false,
  String? label,
}) {
  final rootDefinition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Node"),
    revision: 1,
  );
  final setDefinition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Links"),
    revision: 1,
  );
  final linkDefinition = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "NodeLink"),
    revision: 1,
  );
  final sourceEndpoint = skir.EndpointId(value: "test.source");
  final targetEndpoint = skir.EndpointId(value: "test.target");
  final rootUse = skir.NamedTypeUse(
    definition: rootDefinition,
    arguments: const [],
  );
  final setUse = skir.NamedTypeUse(
    definition: setDefinition,
    arguments: const [],
  );
  final linksOwner = skir.FieldOwner(definition: rootDefinition, name: "links");
  final rootTemplate = skir.TypeTemplate.createNamed(
    definition: rootDefinition,
    arguments: const [],
  );
  final linkTemplate = skir.TypeTemplate.createNamed(
    definition: linkDefinition,
    arguments: const [],
  );
  final setTemplate = skir.TypeTemplate.createNamed(
    definition: setDefinition,
    arguments: const [],
  );
  final appearanceId = skir.PresentationId(
    namespace: "test",
    name: "node.reference.option",
  );
  final appearanceTarget = skir.PresentationTarget.createNamed(
    definition: rootDefinition,
    arguments: const [],
  );
  final appearanceText = _node(
    "node.reference.name",
    skir.PresentationElement.createText(
      value: skir.ExpressionNode.createRead(
        binding: _configuredBindingId,
        path: skir.ValuePath(
          segments: [skir.PathSegment.createField(name: "name")],
        ),
      ),
      color: null,
      sizing: null,
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
      paragraph: skir.TextParagraph.defaultInstance,
    ),
  );
  final appearanceIcon = _node(
    "node.reference.icon",
    skir.PresentationElement.createIcon(
      name: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue(
          '<svg xmlns="http://www.w3.org/2000/svg" '
          'viewBox="0 0 24 24"><path d="M4 4h16v16H4z"/></svg>',
        ),
      ),
      semanticLabel: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Node"),
      ),
      color: null,
      size: null,
    ),
  );
  final coloredIcon = _node(
    "node.reference.icon.color",
    skir.PresentationElement.createContainer(
      foregroundColor: null,
      transitionMilliseconds: 0,
      child: _node(
        "node.reference.icon.padding",
        skir.PresentationElement.createPadding(
          child: appearanceIcon,
          top: 6,
          start: 6,
          end: 6,
          bottom: 6,
        ),
      ),
      border: null,
      backgroundColor: skir.PresentationColor.wrapValue(
        skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapInteger("4288585374"),
        ),
      ),
      radius: skir.PresentationRadius.none,
    ),
  );
  final appearanceCard = _node(
    "node.reference.card",
    skir.PresentationElement.createAdaptiveLeading(
      leading: coloredIcon,
      center: appearanceText,
      suffix: null,
      padding: skir.PresentationInsets.wrapAll(8),
      compactPadding: skir.PresentationInsets.wrapAll(4),
      gap: 12,
      minimumCenterWidth: 80,
    ),
  );
  final appearanceLayout = _node(
    "node.reference.root",
    skir.PresentationElement.wrapChildren(
      skir.ChildrenElement.createColumn(
        children: [skir.AxisChild.wrapFixed(appearanceCard)],
        layout: skir.AxisChildrenLayout(
          spacing: 0,
          mainAxisAlignment: skir.MainAxisAlignment.start,
          crossAxisAlignment: skir.CrossAxisAlignment.start,
        ),
      ),
    ),
  );
  final collectionResourceBinding = skir.ExpressionBindingId(value: "resource");
  final collectionRowBinding = skir.ExpressionBindingId(value: "row");
  final collectionDefinition = skir.PresentationCollectionDefinition(
    sourceId: "nodes",
    rowType: rootTemplate,
    rowBindingId: collectionRowBinding,
    key: skir.ExpressionNode.createRead(
      binding: collectionResourceBinding,
      path: skir.ValuePath(segments: const []),
    ),
    selectability: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapBoolean(true),
    ),
    relations: const [],
    projection: null,
    resources: skir.PresentationResourceCollection(
      root: rootDefinition,
      resourceBindingId: collectionResourceBinding,
      appearance: null,
    ),
  );
  final collectionMaterial = skir.PresentationMaterial(
    provider: skir.PresentationId(namespace: "test", name: "link.collection"),
    target: appearanceTarget,
    role: skir.PresentationRole.inspector,
    layout: _compactNode,
    dependencies: skir.PresentationDependencies(
      types: const [],
      presentations: const [],
      conversions: const [],
      capabilities: const [],
      collections: [collectionDefinition],
    ),
    subject: rootTemplate,
  );
  final checked = CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: skir.CatalogGeneration(value: "catalog:links"),
      types: [
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: rootDefinition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createRecord(
              fields: [
                skir.FieldDeclaration(
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
          status: skir.DeclarationStatus.ready,
          effectiveFields: [
            skir.EffectiveFieldTemplate(
              key: "links",
              owner: linksOwner,
              type: setTemplate,
              rules: const [],
            ),
          ],
          ancestorTemplates: const [],
        ),
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: setDefinition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createSequence(
              item: linkTemplate,
              kind: skir.CollectionKind.set_,
            ),
            parents: const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: const [],
          ancestorTemplates: const [],
        ),
        skir.PublishedType(
          display: null,
          definition: skir.TypeDefinition(
            id: linkDefinition,
            parameters: const [],
            representation: skir.RepresentationTemplate.createLink(
              endpoint: sourceEndpoint,
              target: rootTemplate,
            ),
            parents: const [],
          ),
          status: skir.DeclarationStatus.ready,
          effectiveFields: const [],
          ancestorTemplates: const [],
        ),
      ],
      relations: [
        skir.RelationContract(
          id: skir.RelationId(value: "test.links"),
          first: skir.EndpointDefinition(
            id: sourceEndpoint,
            slot: skir.EndpointSlot.first,
            resource: skir.NamedTypeTemplate(
              definition: rootDefinition,
              arguments: const [],
            ),
            cardinality: skir.EndpointCardinality.many,
            onDelete: skir.RelationDeletePolicy.clear,
          ),
          second: skir.EndpointDefinition(
            id: targetEndpoint,
            slot: skir.EndpointSlot.second,
            resource: skir.NamedTypeTemplate(
              definition: rootDefinition,
              arguments: const [],
            ),
            cardinality: skir.EndpointCardinality.many,
            onDelete: skir.RelationDeletePolicy.clear,
          ),
          families: const [],
        ),
      ],
      resourceDefinitions: const [],
      presentations: adaptiveAppearance
          ? [
              skir.PresentationDescriptor(
                id: appearanceId,
                owner: skir.DeclarationOwner.defaultInstance,
                target: appearanceTarget,
                roles: [skir.PresentationRole.referenceOption],
                priority: 0,
              ),
            ]
          : const [],
      presentationMaterials: adaptiveAppearance
          ? [
              skir.PresentationMaterial(
                provider: appearanceId,
                target: appearanceTarget,
                role: skir.PresentationRole.referenceOption,
                layout: appearanceLayout,
                dependencies: skir.PresentationDependencies.defaultInstance,
                subject: rootTemplate,
              ),
            ]
          : const [],
      configuration: const [],
      diagnostics: const [],
      initialization: const [],
      endpointBindings: [
        skir.EndpointBindingTemplate(
          endpoint: sourceEndpoint,
          containingResource: skir.NamedTypeTemplate(
            definition: rootDefinition,
            arguments: const [],
          ),
          valueOwner: linkDefinition,
          relativePath: skir.RelativeFieldPattern(
            segments: [
              skir.FieldPatternSegment.createField(name: "links"),
              skir.FieldPatternSegment.items,
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
  final target = skir.ResourceId(value: "resource:target");
  final secondTarget = skir.ResourceId(value: "resource:second-target");
  final items = withPartialLinks
      ? [
          skir.ListItem(
            id: _knownLinkItem,
            value: skir.DataValue.createLink(
              endpoint: sourceEndpoint,
              target: skir.LinkTarget(resource: target, opposite: null),
            ),
          ),
          skir.ListItem(
            id: _unfinishedLinkItem,
            value: skir.DataValue.unfilled,
          ),
        ]
      : const <skir.ListItem>[];
  final sourceRecord = skir.AuthoringRecord(
    configuration: skir.TypeSelection.wrapComplete(rootUse),
    fields: [
      skir.FieldValue(
        name: "links",
        value: skir.DataValue.createNamed(
          actualType: setUse,
          payload: skir.DataValue.createSetValue(items: items),
        ),
      ),
    ],
  );
  skir.AuthoringRecord targetRecord(String name) => skir.AuthoringRecord(
    configuration: skir.TypeSelection.wrapComplete(rootUse),
    fields: [
      skir.FieldValue(
        name: "name",
        value: skir.DataValue.wrapStringValue(name),
      ),
      skir.FieldValue(
        name: "links",
        value: skir.DataValue.createNamed(
          actualType: setUse,
          payload: skir.DataValue.createSetValue(items: const []),
        ),
      ),
    ],
  );
  final document = _RendererWorkspace(
    catalog: checked,
    resources: {
      _resource: sourceRecord,
      target: targetRecord("Target Alpha"),
      secondTarget: targetRecord("Target Beta"),
    },
  );
  final rootBinding = skir.ExpressionBindingId(value: "root");
  final itemBinding = skir.ExpressionBindingId(value: "item");
  final collectionReference = skir.BindingRef(
    bindingId: rootBinding,
    path: skir.ValuePath(
      segments: [skir.PathSegment.createField(name: "links")],
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
                skir.PresentationElement.wrapLinkInput(
                  skir.LinkControl(
                    control: skir.BoundControl(
                      binding: collectionReference,
                      label: label == null
                          ? null
                          : skir.ExpressionNode.wrapLiteral(
                              skir.DataValue.wrapStringValue(label),
                            ),
                      description: null,
                      prefix: null,
                      semanticLabel: null,
                    ),
                    allowReorder: true,
                    candidatePolicy: null,
                    rejectionDisplay: skir.LinkRejectionDisplay.disabled,
                    sourceId: null,
                  ),
                ),
              )
            : _node(
                "links",
                skir.PresentationElement.wrapSetInput(
                  skir.SetControl(
                    control: _boundControl(collectionReference),
                    itemPresentation: _node(
                      "link.item",
                      skir.PresentationElement.wrapLinkInput(
                        skir.LinkControl(
                          control: _boundControl(
                            skir.BindingRef(
                              bindingId: itemBinding,
                              path: skir.ValuePath(segments: const []),
                            ),
                          ),
                          allowReorder: false,
                          candidatePolicy: null,
                          rejectionDisplay: skir.LinkRejectionDisplay.disabled,
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
              value: skir.DataValue.createRecord(fields: sourceRecord.fields),
              location: skir.ValueLocation(
                resource: _resource,
                path: skir.ValuePath(segments: const []),
              ),
            ),
          },
          budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
          setBinding: (_, _) {},
          authoring: document.workspace.document,
          edit: document.binding,
          catalog: checked,
          material: adaptiveAppearance ? collectionMaterial : null,
        ),
      ),
    ),
  );
}

PortablePresentationScope _authoringScope(
  _RendererWorkspace document,
  String field,
  skir.DataValue value,
) => PortablePresentationScope(
  bindings: {
    _bindingId: PortableExpressionBinding(
      value: skir.DataValue.createRecord(
        fields: [skir.FieldValue(name: field, value: value)],
      ),
      location: skir.ValueLocation(
        resource: _resource,
        path: skir.ValuePath(segments: const []),
      ),
    ),
  },
  budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
  setBinding: (_, _) {},
  authoring: document.workspace.document,
  edit: document.binding,
  catalog: document.workspace.document.catalog,
);

skir.BoundControl _boundControl(skir.BindingRef reference) => skir.BoundControl(
  binding: reference,
  label: null,
  description: null,
  prefix: null,
  semanticLabel: null,
);

final class _TestPortableHost extends ChangeNotifier
    implements PortablePresentationHost {
  _TestPortableHost({
    required skir.PresentationNode root,
    this.rejectWrites = false,
    skir.PresentationRole? role,
  }) : _document = PortablePresentationDocument(
         catalog: CheckedEditorCatalog(
           skir.EditorCatalogWireSnapshot.defaultInstance,
         ),
         root: root,
         bindings: {
           _bindingId: PortablePresentationBinding(
             schema: PortablePresentationBindingSchema.complete(_integerType),
             value: skir.DataValue.wrapInteger("2"),
             editable: true,
           ),
         },
         budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
         role: role,
       );

  final bool rejectWrites;
  PortablePresentationDocument _document;
  final List<(skir.BindingRef, skir.DataValue)> writes = [];
  final List<skir.EditorAction> actions = [];
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
    skir.EditorAction editorAction,
  ) async {
    actions.add(editorAction);
    return const PortablePresentationWriteResult.applied();
  }

  @override
  skir.TypeUse? expectedType(skir.BindingRef reference) {
    expectedTypeReads++;
    return _integerType;
  }

  @override
  skir.ValueLocation? location(skir.BindingRef reference) => null;

  @override
  skir.DataValue? read(skir.BindingRef reference) =>
      _document.bindings[reference.bindingId]?.value;

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value,
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

final class _RendererWorkspace {
  _RendererWorkspace({
    required CheckedEditorCatalog catalog,
    required Map<skir.ResourceId, skir.AuthoringRecord> resources,
    List<skir.LinkProjection> links = const [],
  }) {
    final document = AuthoringDocument(
      catalog: catalog,
      entries: {
        for (final entry in resources.entries)
          entry.key: skir.AuthoringResource(
            id: entry.key,
            definition: skir.ResourceDefinitionId(value: "test.resource"),
            content: entry.value,
          ),
      },
      links: links,
    );
    transport = ScriptedAuthoringTransport(AsyncData(document));
    workspace = AuthoringWorkspace(transport: transport, initial: document);
    binding = workspace.attach(
      _resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    addTearDown(workspace.dispose);
    addTearDown(transport.dispose);
  }
  late final ScriptedAuthoringTransport transport;
  late final AuthoringWorkspace workspace;
  late final AuthoringBinding binding;
}

Future<skir.PreparedEdit> _submit(
  WidgetTester tester,
  _RendererWorkspace fixture,
) async {
  unawaited(fixture.binding.save());
  await tester.pump();
  return fixture.transport.requests.single.edit;
}

CheckedEditorCatalog _collectionCatalog() {
  final root = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "Collections"),
    revision: 1,
  );
  final list = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "TextList"),
    revision: 1,
  );
  final map = skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: "TextMap"),
    revision: 1,
  );
  final text = skir.TypeTemplate.wrapScalar(skir.ScalarKind.text);
  final fields = {
    "items": skir.TypeTemplate.createNamed(
      definition: list,
      arguments: const [],
    ),
    "values": skir.TypeTemplate.createNamed(
      definition: map,
      arguments: const [],
    ),
  };
  skir.PublishedType published(
    skir.TypeDefinitionId id,
    skir.RepresentationTemplate representation, {
    List<skir.EffectiveFieldTemplate> effective = const [],
  }) => skir.PublishedType(
    definition: skir.TypeDefinition(
      id: id,
      parameters: const [],
      representation: representation,
      parents: const [],
    ),
    display: null,
    status: skir.DeclarationStatus.ready,
    effectiveFields: effective,
    ancestorTemplates: const [],
  );
  return CheckedEditorCatalog(
    skir.EditorCatalogWireSnapshot(
      generation: skir.CatalogGeneration(value: "catalog:test"),
      types: [
        published(
          root,
          skir.RepresentationTemplate.createRecord(
            abstract_: false,
            fields: [
              for (final field in fields.entries)
                skir.FieldDeclaration(
                  owner: skir.FieldOwner(definition: root, name: field.key),
                  type: field.value,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
            ],
          ),
          effective: [
            for (final field in fields.entries)
              skir.EffectiveFieldTemplate(
                key: field.key,
                owner: skir.FieldOwner(definition: root, name: field.key),
                type: field.value,
                rules: const [],
              ),
          ],
        ),
        published(
          list,
          skir.RepresentationTemplate.createSequence(
            item: text,
            kind: skir.CollectionKind.list,
          ),
        ),
        published(
          map,
          skir.RepresentationTemplate.createMapping(key: text, value: text),
        ),
      ],
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
}

skir.AuthoringRecord _collectionRecord(String field, skir.DataValue value) =>
    skir.AuthoringRecord(
      configuration: skir.TypeSelection.createComplete(
        definition: skir.TypeDefinitionId(
          typeId: skir.TypeId.createQualified(
            namespace: "test",
            name: "Collections",
          ),
          revision: 1,
        ),
        arguments: const [],
      ),
      fields: [skir.FieldValue(name: field, value: value)],
    );

final _bindingId = skir.ExpressionBindingId(value: "value");
final _resource = skir.ResourceId(value: "resource:test");
final _knownLinkItem = skir.ItemId(value: "link:known");
final _unfinishedLinkItem = skir.ItemId(value: "link:unfinished");
final _reference = skir.BindingRef(
  bindingId: _bindingId,
  path: skir.ValuePath(segments: const []),
);
final _integerType = skir.TypeUse.wrapScalar(
  skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
);
final _iconifyDefinition = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: "Iconify"),
  revision: 1,
);
final _iconifyType = skir.NamedTypeUse(
  definition: _iconifyDefinition,
  arguments: const [],
);
final _iconifyPresentation = skir.PresentationId(
  namespace: "test",
  name: "iconify.inspector",
);
final _configuredBindingId = skir.ExpressionBindingId(
  value: "configured_value",
);
final _configuredValueReference = skir.BindingRef(
  bindingId: _configuredBindingId,
  path: skir.ValuePath(segments: [skir.PathSegment.createField(name: "value")]),
);
final _control = skir.BoundControl(
  binding: _reference,
  label: null,
  description: null,
  prefix: null,
  semanticLabel: null,
);
final _numericNode = _node(
  "numeric",
  skir.PresentationElement.wrapNumericInput(_control),
);
final _polymorphicNode = _node(
  "polymorphic",
  skir.PresentationElement.createPolymorphicInput(
    control: skir.BoundControl(
      binding: _reference,
      label: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Icon form"),
      ),
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
    concreteTypes: [
      skir.ConcreteTypePresentation(
        concreteType: skir.TypeUse.wrapNamed(_iconifyType),
        label: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapStringValue("Iconify"),
        ),
        presentation: _node(
          "polymorphic.iconify",
          skir.PresentationElement.createInvocation(
            presentationId: _iconifyPresentation,
            arguments: const [],
          ),
        ),
      ),
    ],
  ),
);
final _polymorphicCatalog = CheckedEditorCatalog(
  skir.EditorCatalogWireSnapshot(
    generation: skir.CatalogGeneration(value: "test"),
    types: [
      skir.PublishedType(
        display: null,
        definition: skir.TypeDefinition(
          id: _iconifyDefinition,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              skir.FieldDeclaration(
                owner: skir.FieldOwner(
                  definition: _iconifyDefinition,
                  name: "value",
                ),
                type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
                overrides: const [],
                hasConstructorDefault: false,
              ),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: [
          skir.EffectiveFieldTemplate(
            key: "value",
            owner: skir.FieldOwner(
              definition: _iconifyDefinition,
              name: "value",
            ),
            type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
            rules: const [],
          ),
        ],
        ancestorTemplates: const [],
      ),
    ],
    relations: const [],
    resourceDefinitions: const [],
    presentations: const [],
    presentationMaterials: [
      skir.PresentationMaterial(
        provider: _iconifyPresentation,
        target: skir.PresentationTarget.createNamed(
          definition: _iconifyDefinition,
          arguments: const [],
        ),
        role: skir.PresentationRole.inspector,
        layout: _node(
          "iconify.value",
          skir.PresentationElement.createTextInput(
            control: skir.BoundControl(
              binding: _configuredValueReference,
              label: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue("Icon"),
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
        dependencies: skir.PresentationDependencies.defaultInstance,
        subject: skir.TypeTemplate.createNamed(
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
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.createColumn(
      children: [
        skir.AxisChild.wrapFixed(_numericNode),
        skir.AxisChild.wrapFixed(
          _node(
            "action.button",
            skir.PresentationElement.createButton(
              label: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue("Run action"),
              ),
              action: skir.EditorAction.wrapLocal(
                skir.LocalEditorAction.createSetValue(
                  target: _reference,
                  value: skir.ExpressionNode.wrapLiteral(
                    skir.DataValue.wrapInteger("9"),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
      layout: skir.AxisChildrenLayout(
        spacing: 8,
        mainAxisAlignment: skir.MainAxisAlignment.start,
        crossAxisAlignment: skir.CrossAxisAlignment.stretch,
      ),
    ),
  ),
);
final _compactNode = _node(
  "compact.root",
  skir.PresentationElement.createText(
    value: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapStringValue("Compact card"),
    ),
    color: null,
    sizing: null,
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
    paragraph: skir.TextParagraph.defaultInstance,
  ),
);
final _headerNode = skir.PresentationNode(
  nodeId: "header.root",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapNumericInput(
    skir.BoundControl(
      binding: _reference,
      label: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Count"),
      ),
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
  ),
  header: skir.PresentationHeader(
    binding: _reference,
    title: skir.PresentationHeaderTitle.wrapText(
      skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Document"),
      ),
    ),
    description: skir.ExpressionNode.wrapLiteral(
      skir.DataValue.wrapStringValue("Document description"),
    ),
    initiallyExpanded: true,
    items: const [],
    headerPadding: null,
    contentPadding: null,
  ),
);
final _matchingHeaderNode = skir.PresentationNode(
  nodeId: "matching.header.root",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapNumericInput(
    skir.BoundControl(
      binding: _reference,
      label: skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Count"),
      ),
      description: null,
      prefix: null,
      semanticLabel: null,
    ),
  ),
  header: skir.PresentationHeader(
    binding: _reference,
    title: skir.PresentationHeaderTitle.wrapText(
      skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapStringValue("Count")),
    ),
    description: null,
    initiallyExpanded: true,
    items: const [],
    headerPadding: null,
    contentPadding: null,
  ),
);
final _overflowHeaderNode = skir.PresentationNode(
  nodeId: "overflow.header.root",
  properties: skir.PresentationProperties.defaultInstance,
  element: skir.PresentationElement.wrapNumericInput(_control),
  header: skir.PresentationHeader(
    binding: _reference,
    title: skir.PresentationHeaderTitle.wrapText(
      skir.ExpressionNode.wrapLiteral(
        skir.DataValue.wrapStringValue("Document with actions"),
      ),
    ),
    description: null,
    initiallyExpanded: null,
    items: [
      for (var index = 0; index < 6; index++)
        skir.HeaderItem.createButton(
          itemId: skir.HeaderItemId(namespace: "test", name: "action.$index"),
          icon: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("edit"),
          ),
          label: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Action $index"),
          ),
          tooltip: skir.ExpressionNode.wrapLiteral(
            skir.DataValue.wrapStringValue("Action $index"),
          ),
          action: skir.EditorAction.wrapLocal(
            skir.LocalEditorAction.createSetValue(
              target: _reference,
              value: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapInteger(index.toString()),
              ),
            ),
          ),
          priority: null,
          visibleIf: null,
          enabledIf: null,
          tone: skir.HeaderActionTone.neutral,
          confirmation: null,
          placement: skir.HeaderActionPlacement.end,
        ),
    ],
    headerPadding: null,
    contentPadding: null,
  ),
);

skir.PresentationNode _node(String id, skir.PresentationElement element) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      element: element,
      header: null,
    );

skir.PresentationNode _visualText(String id, String value) =>
    skir.PresentationNode(
      nodeId: id,
      properties: skir.PresentationProperties.defaultInstance,
      header: null,
      element: skir.PresentationElement.wrapText(
        (skir.TextContent.defaultInstance.toMutable()
              ..value = skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapStringValue(value),
              ))
            .toFrozen(),
      ),
    );
