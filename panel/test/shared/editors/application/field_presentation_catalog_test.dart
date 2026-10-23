import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/catalog_fixture.dart";

void main() {
  test(
    "equal canonical nodes reused in local decoration remain unambiguous",
    () {
      final descriptor = _descriptor("base", _base);
      final source = _text("name");
      final display = presentationNode(
        "display",
        skir.PresentationElement.wrapBadge(
          (skir.BadgeContent.defaultInstance.toMutable()
                ..label = skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapStringValue("Shared"),
                )
                ..options =
                    (skir.DisplayAppearance.defaultInstance.toMutable()
                          ..icon = skir.InputAdornment.wrapContent(source))
                        .toFrozen())
              .toFrozen(),
        ),
      );
      final catalog = _catalog(
        [descriptor],
        [
          _material(descriptor, [source, display], references: ["name"]),
        ],
      );
      expect(
        catalog.fieldPresentation(
          _selection(_child),
          "name",
          skir.PresentationRole.inspector,
        ),
        isA<SelectedEditorFieldPresentation>(),
      );
    },
  );

  for (final nestedFirst in [true, false]) {
    test(
      "atomic nested editors diagnose overlap in either body order ($nestedFirst)",
      () {
        final outer = skir.PresentationPartId(owner: _base, name: "outer");
        final inner = skir.PresentationPartId(owner: _base, name: "inner");
        final descriptor = _descriptor("base", _base);
        final call = _part("inner.call", inner, null);
        final direct = _text("direct");
        final body = presentationColumn(
          "outer.body",
          nestedFirst ? [call, direct] : [direct, call],
        );
        final catalog = _catalog(
          [descriptor],
          [
            _material(descriptor, [
              _part("outer", outer, body),
              _part("inner", inner, _text("inner.name")),
            ]),
          ],
        );
        expect(
          catalog.partPresentation(
            _selection(_child),
            outer,
            skir.PresentationRole.inspector,
          ),
          isA<InvalidEditorPartPresentation>(),
        );
      },
    );
  }

  test("an unpublished conditional part declaration stays invalid instead of falling back", () {
    final key = skir.PresentationPartId(owner: _base, name: "heading");
    final base = _descriptor("base", _base);
    final child = _descriptor("child", _child);
    final hidden = presentationNode(
      "conditional",
      skir.PresentationElement.createConditional(
        condition: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapBoolean(false),
        ),
        whenTrue: _part("hidden", key, _text("name")),
        whenFalse: null,
      ),
    );
    final catalog = _catalog(
      [base, child],
      [
        _material(base, [_part("base.heading", key, _text("base.name"))]),
        _material(child, [hidden], references: const []),
      ],
    );
    expect(
      catalog.partPresentation(
        _selection(_child),
        key,
        skir.PresentationRole.inspector,
      ),
      isA<InvalidEditorPartPresentation>(),
    );
  });

  test("a malformed name member leaves a valid sibling member available", () {
    final descriptor = _descriptor("base", _base);
    final invalid = presentationNode(
      "name",
      skir.PresentationElement.wrapToggleInput(
        (skir.ToggleControl.defaultInstance.toMutable()
              ..control = _control("name"))
            .toFrozen(),
      ),
    );
    final catalog = _catalog(
      [descriptor],
      [
        _material(descriptor, [invalid, _text("sibling", field: "sibling")]),
      ],
    );
    expect(
      catalog.fieldPresentation(
        _selection(_child),
        "name",
        skir.PresentationRole.inspector,
      ),
      isA<InvalidEditorFieldPresentation>(),
    );
    expect(
      catalog.fieldPresentation(
        _selection(_child),
        "sibling",
        skir.PresentationRole.inspector,
      ),
      isA<SelectedEditorFieldPresentation>(),
    );
  });

  test(
    "an invalid field only source never becomes an inspector continuation",
    () {
      final family = _descriptor("family", _base);
      final child = _descriptor("child", _child);
      final source = presentationNode(
        "wrong",
        skir.PresentationElement.wrapToggleInput(
          (skir.ToggleControl.defaultInstance.toMutable()
                ..control = _control("name"))
              .toFrozen(),
        ),
      );
      final catalog = _catalog(
        [family],
        [
          _material(family, [source]),
        ],
      );
      expect(
        catalog.nextInspectorLayout(
          actualOwner: _selection(_child),
          below: child.target,
        ),
        isA<MissingEditorInspectorLayout>(),
      );
      expect(
        catalog.fieldPresentation(
          _selection(_child),
          "name",
          skir.PresentationRole.inspector,
        ),
        isA<InvalidEditorFieldPresentation>(),
      );
      expect(
        catalog.partPresentation(
          _selection(_child),
          skir.PresentationPartId(owner: _base, name: "heading"),
          skir.PresentationRole.inspector,
        ),
        isA<MissingEditorPartPresentation>(),
      );
    },
  );

  test("a structural source cannot omit the canonical neutral root", () {
    final family = _descriptor("family", _base);
    final child = _descriptor("child", _child);
    final remainder = presentationNode(
      "remaining",
      skir.PresentationElement.createRemainingFields(
        excluded: const [],
        excludedParts: const [],
      ),
    );
    final catalog = _catalog(
      [family],
      [
        _material(
          family,
          [_text("name"), remainder],
          references: ["name", "remaining"],
        ),
      ],
    );
    expect(
      (catalog.nextInspectorLayout(
        actualOwner: _selection(_child),
        below: child.target,
      ) as InvalidEditorInspectorLayout).diagnostic,
      contains("neutral ancestor"),
    );
  });

  test("part alternatives rank independently and losing bodies add no fallback fields", () {
    final key = skir.PresentationPartId(owner: _base, name: "details");
    final low = _descriptor("low", _base, priority: 1);
    final high = _descriptor("high", _base, priority: 10);
    final catalog = _catalog(
      [low, high],
      [
        _material(low, [_part("low", key, _text("name"))]),
        _material(high, [
          _part("high", key, _text("sibling", field: "sibling")),
        ]),
      ],
    );
    final selected = catalog.partPresentation(
      _selection(_child),
      key,
      skir.PresentationRole.inspector,
    ) as SelectedEditorPartPresentation;
    expect(selected.material.provider, high.id);
    expect(selected.editedFields, {"sibling"});
    expect(selected.fallbackFields, {"sibling"});
    final left = _descriptor("left", _left, priority: 100);
    final right = _descriptor("right", _right, priority: 1);
    final conflict = _catalog(
      [left, right],
      [
        _material(left, [_part("left", key, _text("name"))]),
        _material(right, [
          _part("right", key, _text("sibling", field: "sibling")),
        ]),
      ],
    );
    expect(
      conflict.partPresentation(
        _selection(_child),
        key,
        skir.PresentationRole.inspector,
      ),
      isA<ConflictingEditorPartPresentation>(),
    );
  });

  test("part footprints reject owner remainders and accept scoped descendant remainders", () {
    final key = skir.PresentationPartId(owner: _base, name: "details");
    final descriptor = _descriptor("base", _base);
    final remainder = presentationNode(
      "remaining",
      skir.PresentationElement.createRemainingFields(
        excluded: const [],
        excludedParts: const [],
      ),
    );
    final invalid = _catalog(
      [descriptor],
      [
        _material(descriptor, [_part("details", key, remainder)]),
      ],
    );
    expect(
      invalid.partPresentation(
        _selection(_child),
        key,
        skir.PresentationRole.inspector,
      ),
      isA<InvalidEditorPartPresentation>(),
    );
    expect(
      invalid.fieldPresentation(
        _selection(_child),
        "name",
        skir.PresentationRole.inspector,
      ),
      isA<MissingEditorFieldPresentation>(),
    );
    final scoped = presentationNode(
      "scope",
      skir.PresentationElement.createScopedBinding(
        binding: _control("nested").binding,
        scopeBindingId: skir.ExpressionBindingId(value: "configured_value"),
        child: remainder,
      ),
    );
    final valid = _catalog(
      [descriptor],
      [
        _material(descriptor, [_part("details", key, scoped)]),
      ],
    );
    expect(
      (valid.partPresentation(
        _selection(_child),
        key,
        skir.PresentationRole.inspector,
      ) as SelectedEditorPartPresentation).editedFields,
      {"nested"},
    );
  });

  test(
    "nested record reuse reserves its containing field without a false cycle",
    () {
      final key = skir.PresentationPartId(owner: _base, name: "details");
      final descriptor = _descriptor("base", _base);
      final body = presentationNode(
        "nested.scope",
        skir.PresentationElement.createScopedBinding(
          binding: _control("nested").binding,
          scopeBindingId: skir.ExpressionBindingId(value: "configured_value"),
          child: _part("nested.call", key, null),
        ),
      );
      final catalog = _catalog(
        [descriptor],
        [
          _material(descriptor, [_part("details", key, body)]),
        ],
      );
      final selected = catalog.partPresentation(
        _selection(_child),
        key,
        skir.PresentationRole.inspector,
      ) as SelectedEditorPartPresentation;
      expect(selected.editedFields, {"nested"});
      expect(selected.fallbackFields, {"nested"});
    },
  );

  test("ancestor layout skips equivalent target alternatives and preserves members", () {
    final family = _descriptor("family", _base);
    final alternative = _descriptor("alternative", _child, priority: -1);
    final remainder = presentationNode(
      "remainder",
      skir.PresentationElement.createRemainingFields(
        excluded: const [],
        excludedParts: const [],
      ),
    );
    final catalog = _catalog(
      [family, alternative],
      [
        _material(
          family,
          [_text("name"), remainder],
          references: ["root", "name", "remainder"],
        ),
        _material(alternative, [remainder], references: ["root", "remainder"]),
      ],
    );
    final selected = catalog.nextInspectorLayout(
      actualOwner: _selection(_child),
      below: alternative.target,
    ) as SelectedEditorInspectorLayout;
    expect(selected.descriptor.id, family.id);
    expect(selected.inheritableNodes, {"root", "name", "remainder"});
  });

  for (final count in [0, 2]) {
    test(
      "a source with $count remainders still contributes field behavior",
      () {
        final family = _descriptor("family", _base);
        final child = _descriptor("child", _child);
        final nodes = [
          _text("name"),
          for (var i = 0; i < count; i++)
            presentationNode(
              "remaining.$i",
              skir.PresentationElement.createRemainingFields(
                excluded: const [],
                excludedParts: const [],
              ),
            ),
        ];
        final catalog = _catalog([family], [_material(family, nodes)]);
        expect(
          catalog.nextInspectorLayout(
            actualOwner: _selection(_child),
            below: child.target,
          ),
          isA<MissingEditorInspectorLayout>(),
        );
        expect(
          catalog.fieldPresentation(
            _selection(_child),
            "name",
            skir.PresentationRole.inspector,
          ),
          isA<SelectedEditorFieldPresentation>(),
        );
      },
    );
  }

  test("placeholder positions do not compete with concrete field behavior", () {
    final base = _descriptor("base", _base);
    final child = _descriptor("child", _child);
    final request = presentationNode(
      "request",
      skir.PresentationElement.createDefaultPresentation(
        control: _control("name"),
        presentationId: null,
      ),
    );
    final catalog = _catalog(
      [base, child],
      [
        _material(base, [_text("name")]),
        _material(child, [request]),
      ],
    );
    final selected = catalog.fieldPresentation(
      _selection(_child),
      "name",
      skir.PresentationRole.inspector,
    ) as SelectedEditorFieldPresentation;
    expect(selected.identity.provider, base.id);
  });

  test("part replacement keeps ancestor fallback suppression separate from live editors", () {
    final key = skir.PresentationPartId(owner: _base, name: "details");
    final base = _descriptor("base", _base);
    final child = _descriptor("child", _child);
    final baseBody = _text("name");
    final childBody = presentationNode(
      "display",
      skir.PresentationElement.createSpacer(width: null, height: null),
    );
    final baseMaterial = _material(base, [_part("base.part", key, baseBody)]);
    final childMaterial = _material(child, [
      _part("child.part", key, childBody),
    ]);
    final catalog = _catalog([base, child], [baseMaterial, childMaterial]);
    final selected = catalog.partPresentation(
      _selection(_child),
      key,
      skir.PresentationRole.inspector,
    ) as SelectedEditorPartPresentation;
    expect(selected.body, childBody);
    expect(selected.editedFields, isEmpty);
    expect(selected.fallbackFields, {"name"});
    final local = catalog.partPresentation(
      _selection(_child),
      key,
      skir.PresentationRole.inspector,
      local: EditorPartDeclaration(
        material: childMaterial,
        body: _text("sibling", field: "sibling"),
      ),
    ) as SelectedEditorPartPresentation;
    expect(local.editedFields, {"sibling"});
    expect(local.fallbackFields, {"name", "sibling"});
  });

  test(
    "part calls resolve transitive editors and same owner cycles diagnose",
    () {
      final first = skir.PresentationPartId(owner: _base, name: "first");
      final second = skir.PresentationPartId(owner: _base, name: "second");
      final descriptor = _descriptor("parts", _base);
      final material = _material(descriptor, [
        _part("first", first, _part("second.call", second, null)),
        _part("second", second, _text("name")),
      ]);
      final catalog = _catalog([descriptor], [material]);
      final selected = catalog.partPresentation(
        _selection(_child),
        first,
        skir.PresentationRole.inspector,
      ) as SelectedEditorPartPresentation;
      expect(selected.editedFields, {"name"});
      expect(selected.claimedParts, {first, second});
      final cycle = _material(descriptor, [
        _part("first", first, _part("second.call", second, null)),
        _part("second", second, _part("first.call", first, null)),
      ]);
      expect(
        (_catalog([descriptor], [cycle]).partPresentation(
          _selection(_child),
          first,
          skir.PresentationRole.inspector,
        ) as InvalidEditorPartPresentation).diagnostic,
        contains("recursive"),
      );
      expect(
        catalog.partPresentation(
          _selection(_child),
          skir.PresentationPartId(owner: _base, name: "missing"),
          skir.PresentationRole.inspector,
        ),
        isA<MissingEditorPartPresentation>(),
      );
    },
  );

  test("sibling expression reads and scoped editors of the same field are reusable", () {
    final descriptor = _descriptor("child", _child);
    final alias = skir.ExpressionBindingId(value: "owned");
    final nested = presentationNode(
      "nested",
      skir.PresentationElement.wrapTextInput(
        (skir.TextControl.defaultInstance.toMutable()
              ..control = (skir.BoundControl.defaultInstance.toMutable()
                ..binding = skir.BindingRef(
                  bindingId: alias,
                  path: skir.ValuePath.defaultInstance,
                )))
            .toFrozen(),
      ),
    );
    final control =
        (_control("name").toMutable()
              ..label = skir.ExpressionNode.createInput(
                binding: skir.ExpressionBindingId(value: "configured_value"),
                path: _control("sibling").binding.path,
              )
              ..prefix = presentationNode(
                "scope",
                skir.PresentationElement.createScopedBinding(
                  binding: _control("name").binding,
                  scopeBindingId: alias,
                  child: nested,
                ),
              ))
            .toFrozen();
    final source = presentationNode(
      "name",
      skir.PresentationElement.wrapTextInput(
        (skir.TextControl.defaultInstance.toMutable()..control = control)
            .toFrozen(),
      ),
    );
    final catalog = _catalog(
      [descriptor],
      [
        _material(descriptor, [source]),
      ],
    );
    expect(
      catalog.fieldPresentation(
        _selection(_child),
        "name",
        skir.PresentationRole.inspector,
      ),
      isA<SelectedEditorFieldPresentation>(),
    );
  });

  for (final placement in [
    "prefix",
    "header",
    "leading",
    "hidden",
    "unknown_scope",
    "foreign_scope",
    "remaining",
    "invocation",
    "custom_invocation",
    "part_request",
    "part_definition",
  ]) {
    test(
      "a source with $placement sibling editors is not an inherited field",
      () {
        final descriptor = _descriptor("child", _child);
        final sibling = _text("foreign", field: "sibling");
        final alias = skir.ExpressionBindingId(value: "local");
        final local = presentationNode(
          "local",
          skir.PresentationElement.wrapTextInput(
            (skir.TextControl.defaultInstance.toMutable()
                  ..control = (skir.BoundControl.defaultInstance.toMutable()
                    ..binding = skir.BindingRef(
                      bindingId: alias,
                      path: skir.ValuePath.defaultInstance,
                    )))
                .toFrozen(),
          ),
        );
        final decoration = switch (placement) {
          "part_request" || "part_definition" => _part(
            "part",
            skir.PresentationPartId(owner: _base, name: "heading"),
            placement == "part_definition" ? _text("owned") : null,
          ),
          "hidden" => presentationNode(
            "hidden",
            skir.PresentationElement.createConditional(
              condition: skir.ExpressionNode.wrapLiteral(
                skir.DataValue.wrapBoolean(false),
              ),
              whenTrue: sibling,
              whenFalse: null,
            ),
          ),
          "unknown_scope" || "foreign_scope" => presentationNode(
            "scope",
            skir.PresentationElement.createScopedBinding(
              binding: placement == "foreign_scope"
                  ? _control("sibling").binding
                  : skir.BindingRef(
                      bindingId: skir.ExpressionBindingId(value: "unknown"),
                      path: skir.ValuePath.defaultInstance,
                    ),
              scopeBindingId: alias,
              child: local,
            ),
          ),
          "remaining" => presentationNode(
            "remaining",
            skir.PresentationElement.createRemainingFields(
              excluded: const [],
              excludedParts: const [],
            ),
          ),
          "invocation" || "custom_invocation" => presentationNode(
            "invocation",
            skir.PresentationElement.wrapInvocation(
              skir.PresentationInvocation(
                presentationId: descriptor.id,
                arguments: [
                  skir.PresentationArgument(
                    input: alias,
                    binding: _control(
                      placement == "custom_invocation" ? "name" : "sibling",
                    ).binding,
                  ),
                ],
              ),
            ),
          ),
          _ => sibling,
        };
        final source = _text("name").toMutable();
        if (placement == "header") {
          source.header =
              (skir.PresentationHeader.defaultInstance.toMutable()
                    ..title = skir.PresentationHeaderTitle.wrapPresentation(
                      decoration,
                    ))
                  .toFrozen();
        } else {
          final input =
              (source.element! as skir.PresentationElement_textInputWrapper)
                  .value
                  .toMutable();
          if (placement == "leading") {
            input.content =
                (skir.InputContent.defaultInstance.toMutable()
                      ..leading = skir.InputAdornment.wrapContent(decoration))
                    .toFrozen();
          } else {
            input.control =
                (input.control.toFrozen().toMutable()..prefix = decoration)
                    .toFrozen();
          }
          source.element = skir.PresentationElement.wrapTextInput(
            input.toFrozen(),
          );
        }
        final catalog = _catalog(
          [descriptor],
          [
            _material(descriptor, [source.toFrozen()]),
          ],
        );
        final selected = catalog.fieldPresentation(
          _selection(_child),
          "name",
          skir.PresentationRole.inspector,
        ) as InvalidEditorFieldPresentation;
        expect(
          selected.diagnostic,
          contains(
            placement == "part_definition"
                ? "part declaration"
                : placement == "part_request"
                ? "unresolved editable part"
                : placement == "unknown_scope"
                ? "unresolved editable binding"
                : "outside its field subtree",
          ),
        );
      },
    );
  }

  test(
    "representation providers use only the exact owner's compiled subject",
    () {
      final descriptor =
          (_descriptor("record", _base).toMutable()
                ..target = skir.PresentationTarget.wrapRepresentation(
                  skir.RepresentationKind.record,
                ))
              .toFrozen();
      skir.PresentationMaterial material(skir.TypeDefinitionId subject) =>
          (_material(_descriptor("record", subject), [
            _text("name"),
          ]).toMutable()..target = descriptor.target).toFrozen();
      final baseMaterial = material(_base);
      final childMaterial = material(_child);
      final catalog = _catalog([descriptor], [baseMaterial, childMaterial]);

      final selected = catalog.fieldPresentation(
        _selection(_child),
        "name",
        skir.PresentationRole.inspector,
      ) as SelectedEditorFieldPresentation;
      expect(selected.material, same(childMaterial));
      expect(
        catalog.fieldPresentation(
          _selection(_left),
          "name",
          skir.PresentationRole.inspector,
        ),
        isA<MissingEditorFieldPresentation>(),
      );
    },
  );

  test(
    "an inherited field retains its source node and material dependencies",
    () {
      final base = _descriptor("base", _base, priority: 100);
      final material = _material(base, [_text("base.name")]);
      final catalog = _catalog([base], [material]);

      final selected = catalog.fieldPresentation(
        _selection(_child),
        "name",
        skir.PresentationRole.inspector,
      ) as SelectedEditorFieldPresentation;

      expect(selected.material, same(material));
      expect(selected.node.nodeId, "base.name");
      expect(selected.identity.provider, base.id);
      expect(selected.identity.subject, material.subject);
      expect(
        catalog.fieldPresentation(
          _selection(_child),
          "other",
          skir.PresentationRole.inspector,
        ),
        isA<MissingEditorFieldPresentation>(),
      );
      expect(
        catalog.fieldPresentation(
          _selection(_child),
          "name",
          skir.PresentationRole.workspace,
        ),
        isA<MissingEditorFieldPresentation>(),
      );
    },
  );

  test(
    "specificity precedes priority and a child resolves competing parents",
    () {
      final base = _descriptor("base", _base, priority: 1000);
      final left = _descriptor("left", _left, priority: 100);
      final right = _descriptor("right", _right, priority: 1);
      final child = _descriptor("child", _child);
      final descriptors = [base, left, right, child];
      final materials = [
        for (final descriptor in descriptors)
          _material(descriptor, [_text("${descriptor.id.name}.name")]),
      ];

      final parents = _catalog(
        descriptors.take(3).toList(),
        materials.take(3).toList(),
      );
      final conflict = parents.fieldPresentation(
        _selection(_child),
        "name",
        skir.PresentationRole.inspector,
      ) as ConflictingEditorFieldPresentation;
      expect(
        conflict.candidates.map((candidate) => candidate.provider),
        containsAll([left.id, right.id]),
      );
      expect(conflict.candidates.length, 2);

      final resolved = _catalog(descriptors, materials).fieldPresentation(
        _selection(_child),
        "name",
        skir.PresentationRole.inspector,
      ) as SelectedEditorFieldPresentation;
      expect(resolved.identity.provider, child.id);
    },
  );

  test("equivalent target priority chooses a provider without collapsing its nodes", () {
    final low = _descriptor("low", _base, priority: 1);
    final high = _descriptor("high", _base, priority: 2);
    final lowMaterial = _material(low, [_text("low.name")]);
    final highMaterial = _material(high, [
      _text("high.first"),
      _text("high.second"),
    ]);
    final catalog = _catalog([low, high], [lowMaterial, highMaterial]);

    final conflict = catalog.fieldPresentation(
      _selection(_child),
      "name",
      skir.PresentationRole.inspector,
    ) as ConflictingEditorFieldPresentation;
    expect(conflict.candidates.map((candidate) => candidate.nodeId), [
      "high.first",
      "high.second",
    ]);

    final single =
        _catalog(
              [low, high],
              [
                lowMaterial,
                _material(high, [_text("high.only")]),
              ],
            ).fieldPresentation(
              _selection(_child),
              "name",
              skir.PresentationRole.inspector,
            )
            as SelectedEditorFieldPresentation;
    expect(single.identity.provider, high.id);
  });

  test("a more specific placeholder contributes no candidate and keeps inheritance", () {
    final base = _descriptor("base", _base);
    final child = _descriptor("child", _child, priority: 100);
    final catalog = _catalog(
      [base, child],
      [
        _material(base, [_text("base.name")]),
        _material(child, [
          presentationNode(
            "child.name",
            skir.PresentationElement.createDefaultPresentation(
              control: _control("name"),
              presentationId: null,
            ),
          ),
        ], references: const []),
      ],
    );
    final selected = catalog.fieldPresentation(
      _selection(_child),
      "name",
      skir.PresentationRole.inspector,
    ) as SelectedEditorFieldPresentation;
    expect(selected.identity.provider, base.id);
  });

  for (final problem in [
    "missing",
    "duplicate",
    "unknown_field",
    "wrong_type",
  ]) {
    test(
      "a malformed $problem reference diagnoses instead of falling back",
      () {
        final base = _descriptor("base", _base);
        final child = _descriptor("child", _child);
        final nodes = switch (problem) {
          "missing" => [_text("other")],
          "duplicate" => [_text("bad"), _text("bad")],
          "unknown_field" => [_text("bad", field: "other")],
          "wrong_type" => [
            presentationNode(
              "bad",
              skir.PresentationElement.wrapToggleInput(
                (skir.ToggleControl.defaultInstance.toMutable()
                      ..control = _control("name"))
                    .toFrozen(),
              ),
            ),
          ],
          _ => throw StateError(problem),
        };
        final material = _material(child, nodes, references: ["bad"]);
        final catalog = _catalog(
          [base, child],
          [
            _material(base, [_text("base.name")]),
            material,
          ],
        );
        final selection = catalog.fieldPresentation(
          _selection(_child),
          problem == "unknown_field" ? "other" : "name",
          skir.PresentationRole.inspector,
        );
        expect(selection, isA<InvalidEditorFieldPresentation>());
        final invalid = selection as InvalidEditorFieldPresentation;
        expect(invalid.identity.provider, child.id);
        expect(invalid.diagnostic, contains("child"));
        expect(invalid.diagnostic, contains("bad"));
      },
    );
  }

  test(
    "equal node ids in different materials retain independent identities",
    () {
      final left = _descriptor("left", _left);
      final right = _descriptor("right", _right);
      final catalog = _catalog(
        [left, right],
        [
          _material(left, [_text("same")]),
          _material(right, [_text("same")]),
        ],
      );
      final leftChoice = catalog.fieldPresentation(
        _selection(_left),
        "name",
        skir.PresentationRole.inspector,
      ) as SelectedEditorFieldPresentation;
      final rightChoice = catalog.fieldPresentation(
        _selection(_right),
        "name",
        skir.PresentationRole.inspector,
      ) as SelectedEditorFieldPresentation;
      expect(leftChoice.identity, isNot(rightChoice.identity));
      expect(leftChoice.node.nodeId, rightChoice.node.nodeId);
    },
  );

  test(
    "structural indexing visits control prefixes once alongside choice content",
    () {
      final prefix = _text("prefix");
      final option = _text("option");
      final node = presentationNode(
        "choice",
        skir.PresentationElement.wrapSelectInput(
          (skir.SelectControl.defaultInstance.toMutable()
                ..control = (_control("name").toMutable()..prefix = prefix)
                ..options = [
                  (skir.SelectOption.defaultInstance.toMutable()
                        ..content = option)
                      .toFrozen(),
                ])
              .toFrozen(),
        ),
      );
      expect(node.nestedPresentationNodes.map((child) => child.nodeId), [
        "prefix",
        "option",
      ]);
    },
  );

  test("whole selection still reports an unavailable winning material", () {
    final base = _descriptor("base", _base);
    final child = _descriptor("child", _child);
    final catalog = _catalog(
      [base, child],
      [
        _material(base, [_text("base.name")]),
      ],
    );
    expect(
      catalog.selectPresentation(
        _selection(_child),
        skir.PresentationRole.inspector,
      ),
      isA<UnavailableEditorPresentation>(),
    );
  });

  test("display icon descendants participate in source node uniqueness", () {
    final descriptor = _descriptor("child", _child);
    final appearance =
        (skir.DisplayAppearance.defaultInstance.toMutable()
              ..icon = skir.InputAdornment.wrapContent(
                _text("name", field: "sibling"),
              ))
            .toFrozen();
    final statusAppearance =
        (skir.StatusAppearance.defaultInstance.toMutable()
              ..options = appearance)
            .toFrozen();
    final displays = [
      skir.PresentationElement.wrapBadge(
        (skir.BadgeContent.defaultInstance.toMutable()..options = appearance)
            .toFrozen(),
      ),
      skir.PresentationElement.wrapChip(
        (skir.ChipContent.defaultInstance.toMutable()..options = appearance)
            .toFrozen(),
      ),
      skir.PresentationElement.wrapDateTime(
        (skir.DateTimeContent.defaultInstance.toMutable()..options = appearance)
            .toFrozen(),
      ),
      skir.PresentationElement.wrapRelativeTime(
        (skir.RelativeTimeContent.defaultInstance.toMutable()
              ..options = appearance)
            .toFrozen(),
      ),
      skir.PresentationElement.wrapStatus(
        (skir.StatusContent.defaultInstance.toMutable()
              ..fallback = statusAppearance)
            .toFrozen(),
      ),
      skir.PresentationElement.wrapStatus(
        (skir.StatusContent.defaultInstance.toMutable()
              ..cases = [
                (skir.StatusCase.defaultInstance.toMutable()
                      ..appearance = statusAppearance)
                    .toFrozen(),
              ])
            .toFrozen(),
      ),
    ];
    for (final display in displays) {
      final catalog = _catalog(
        [descriptor],
        [
          _material(
            descriptor,
            [_text("name"), presentationNode("display", display)],
            references: ["name"],
          ),
        ],
      );
      final invalid = catalog.fieldPresentation(
        _selection(_child),
        "name",
        skir.PresentationRole.inspector,
      ) as InvalidEditorFieldPresentation;
      expect(
        invalid.diagnostic,
        contains("ambiguous"),
        reason: display.runtimeType.toString(),
      );
    }
  });
}

final _base = _definition("Base");
final _left = _definition("Left");
final _right = _definition("Right");
final _child = _definition("Child");

skir.TypeDefinitionId _definition(String name) => skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "field_test", name: name),
  revision: 1,
);

skir.TypeSelection _selection(skir.TypeDefinitionId definition) =>
    skir.TypeSelection.createComplete(
      definition: definition,
      arguments: const [],
    );

skir.PresentationDescriptor _descriptor(
  String name,
  skir.TypeDefinitionId owner, {
  int priority = 0,
}) => skir.PresentationDescriptor(
  id: skir.PresentationId(namespace: "field_test", name: name),
  owner: skir.DeclarationOwner.defaultInstance,
  target: skir.PresentationTarget.createNamed(
    definition: owner,
    arguments: const [],
  ),
  roles: [skir.PresentationRole.inspector],
  priority: priority,
);

skir.PresentationMaterial _material(
  skir.PresentationDescriptor descriptor,
  List<skir.PresentationNode> nodes, {
  List<String>? references,
}) => skir.PresentationMaterial(
  provider: descriptor.id,
  target: descriptor.target,
  role: skir.PresentationRole.inspector,
  subject: skir.TypeTemplate.wrapNamed(
    (descriptor.target as skir.PresentationTarget_namedWrapper).value,
  ),
  layout: presentationColumn("root", nodes),
  dependencies: skir.PresentationDependencies.defaultInstance,
  inheritableNodes: references ?? [for (final node in nodes) node.nodeId],
);

CheckedEditorCatalog _catalog(
  List<skir.PresentationDescriptor> descriptors,
  List<skir.PresentationMaterial> materials,
) => testCheckedCatalog(
  types: [
    _type(_base, const []),
    _type(_left, [_base]),
    _type(_right, [_base]),
    _type(_child, [_left, _right, _base]),
  ],
  presentations: descriptors,
  presentationMaterials: materials,
);

skir.PublishedType _type(
  skir.TypeDefinitionId definition,
  List<skir.TypeDefinitionId> ancestors,
) => skir.PublishedType(
  searchKey: null,
  placementField: null,
  definition: skir.TypeDefinition(
    id: definition,
    parameters: const [],
    representation: skir.RepresentationTemplate.createRecord(
      fields: const [],
      abstract_: false,
    ),
    parents: [
      for (final ancestor in ancestors)
        skir.NamedTypeTemplate(definition: ancestor, arguments: const []),
    ],
  ),
  status: skir.DeclarationStatus.ready,
  effectiveFields: [
    skir.EffectiveFieldTemplate(
      key: "nested",
      owner: skir.FieldOwner(definition: _base, name: "nested"),
      type: skir.TypeTemplate.createNamed(
        definition: _child,
        arguments: const [],
      ),
      rules: const [],
    ),
    skir.EffectiveFieldTemplate(
      key: "name",
      owner: skir.FieldOwner(definition: _base, name: "name"),
      type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      rules: const [],
    ),
    skir.EffectiveFieldTemplate(
      key: "sibling",
      owner: skir.FieldOwner(definition: _base, name: "sibling"),
      type: skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      rules: const [],
    ),
  ],
  ancestorTemplates: [
    for (final ancestor in ancestors)
      skir.NamedTypeTemplate(definition: ancestor, arguments: const []),
  ],
  display: defaultTypeDisplay(""),
);

skir.BoundControl _control(String field) =>
    (skir.BoundControl.defaultInstance.toMutable()
          ..binding = skir.BindingRef(
            bindingId: skir.ExpressionBindingId(value: "configured_value"),
            path: skir.ValuePath(
              segments: [skir.PathSegment.createField(name: field)],
            ),
          ))
        .toFrozen();

skir.PresentationNode _text(String id, {String field = "name"}) =>
    presentationNode(
      id,
      skir.PresentationElement.wrapTextInput(
        (skir.TextControl.defaultInstance.toMutable()
              ..control = _control(field))
            .toFrozen(),
      ),
    );

skir.PresentationNode _part(
  String id,
  skir.PresentationPartId key,
  skir.PresentationNode? body,
) => presentationNode(
  id,
  skir.PresentationElement.createPart(key: key, body: body),
);
