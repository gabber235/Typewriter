import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The inspector of the base type, named base.
final _baseInspector = inspectorDescriptor(
  "base",
  _base,
  namespace: "field_test",
);

/// The inspector of the base type, named family.
final _familyInspector = inspectorDescriptor(
  "family",
  _base,
  namespace: "field_test",
);

/// The inspector of the child type.
final _childInspector = inspectorDescriptor(
  "child",
  _child,
  namespace: "field_test",
);

/// An inspector of the base type at priority 1.
final _lowInspector = inspectorDescriptor(
  "low",
  _base,
  namespace: "field_test",
  priority: 1,
);

/// The inspector of the left parent at priority 100.
final _leftInspector = inspectorDescriptor(
  "left",
  _left,
  namespace: "field_test",
  priority: 100,
);

/// The inspector of the right parent at priority 1.
final _rightInspector = inspectorDescriptor(
  "right",
  _right,
  namespace: "field_test",
  priority: 1,
);

void main() {
  test(
    "equal canonical nodes reused in local decoration remain unambiguous",
    () {
      final descriptor = _baseInspector;
      final source = textFieldNode("name");
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
      final catalog = testCheckedCatalog(
        types: _types,
        presentations: [descriptor],
        presentationMaterials: [
          inspectorMaterial(
            descriptor,
            [source, display],
            references: ["name"],
          ),
        ],
      );
      expect(
        catalog.inspectorField(_child, "name"),
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
        final descriptor = _baseInspector;
        final call = presentationPart("inner.call", inner, null);
        final direct = textFieldNode("direct");
        final body = presentationColumn(
          "outer.body",
          nestedFirst ? [call, direct] : [direct, call],
        );
        final catalog = testCheckedCatalog(
          types: _types,
          presentations: [descriptor],
          presentationMaterials: [
            inspectorMaterial(descriptor, [
              presentationPart("outer", outer, body),
              presentationPart("inner", inner, textFieldNode("inner.name")),
            ]),
          ],
        );
        expect(
          catalog.partPresentation(
            completeSelection(_child),
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
    final base = _baseInspector;
    final child = _childInspector;
    final hidden = presentationNode(
      "conditional",
      skir.PresentationElement.createConditional(
        condition: skir.ExpressionNode.wrapLiteral(
          skir.DataValue.wrapBoolean(false),
        ),
        whenTrue: presentationPart("hidden", key, textFieldNode("name")),
        whenFalse: null,
      ),
    );
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [base, child],
      presentationMaterials: [
        inspectorMaterial(base, [
          presentationPart("base.heading", key, textFieldNode("base.name")),
        ]),
        inspectorMaterial(child, [hidden], references: const []),
      ],
    );
    expect(
      catalog.partPresentation(
        completeSelection(_child),
        key,
        skir.PresentationRole.inspector,
      ),
      isA<InvalidEditorPartPresentation>(),
    );
  });

  test("a malformed name member leaves a valid sibling member available", () {
    final descriptor = _baseInspector;
    final invalid = presentationNode(
      "name",
      skir.PresentationElement.wrapToggleInput(
        (skir.ToggleControl.defaultInstance.toMutable()
              ..control = fieldControl("name"))
            .toFrozen(),
      ),
    );
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [descriptor],
      presentationMaterials: [
        inspectorMaterial(descriptor, [
          invalid,
          textFieldNode("sibling", field: "sibling"),
        ]),
      ],
    );
    expect(
      catalog.inspectorField(_child, "name"),
      isA<InvalidEditorFieldPresentation>(),
    );
    expect(
      catalog.inspectorField(_child, "sibling"),
      isA<SelectedEditorFieldPresentation>(),
    );
  });

  test(
    "an invalid field only source never becomes an inspector continuation",
    () {
      final family = _familyInspector;
      final child = _childInspector;
      final source = presentationNode(
        "wrong",
        skir.PresentationElement.wrapToggleInput(
          (skir.ToggleControl.defaultInstance.toMutable()
                ..control = fieldControl("name"))
              .toFrozen(),
        ),
      );
      final catalog = testCheckedCatalog(
        types: _types,
        presentations: [family],
        presentationMaterials: [
          inspectorMaterial(family, [source]),
        ],
      );
      expect(
        catalog.nextInspectorLayout(
          actualOwner: completeSelection(_child),
          below: child.target,
        ),
        isA<MissingEditorInspectorLayout>(),
      );
      expect(
        catalog.inspectorField(_child, "name"),
        isA<InvalidEditorFieldPresentation>(),
      );
      expect(
        catalog.partPresentation(
          completeSelection(_child),
          skir.PresentationPartId(owner: _base, name: "heading"),
          skir.PresentationRole.inspector,
        ),
        isA<MissingEditorPartPresentation>(),
      );
    },
  );

  test("a structural source cannot omit the canonical neutral root", () {
    final family = _familyInspector;
    final child = _childInspector;
    final remainder = presentationNode(
      "remaining",
      skir.PresentationElement.createRemainingFields(
        excluded: const [],
        excludedParts: const [],
      ),
    );
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [family],
      presentationMaterials: [
        inspectorMaterial(
          family,
          [textFieldNode("name"), remainder],
          references: ["name", "remaining"],
        ),
      ],
    );
    expect(
      (catalog.nextInspectorLayout(
        actualOwner: completeSelection(_child),
        below: child.target,
      ) as InvalidEditorInspectorLayout).diagnostic,
      contains("neutral ancestor"),
    );
  });

  test("part alternatives rank independently and losing bodies add no fallback fields", () {
    final key = skir.PresentationPartId(owner: _base, name: "details");
    final low = _lowInspector;
    final high = inspectorDescriptor(
      "high",
      _base,
      namespace: "field_test",
      priority: 10,
    );
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [low, high],
      presentationMaterials: [
        inspectorMaterial(low, [
          presentationPart("low", key, textFieldNode("name")),
        ]),
        inspectorMaterial(high, [
          presentationPart(
            "high",
            key,
            textFieldNode("sibling", field: "sibling"),
          ),
        ]),
      ],
    );
    final selected = catalog.partPresentation(
      completeSelection(_child),
      key,
      skir.PresentationRole.inspector,
    ) as SelectedEditorPartPresentation;
    expect(selected.material.provider, high.id);
    expect(selected.editedFields, {"sibling"});
    expect(selected.fallbackFields, {"sibling"});
    final left = _leftInspector;
    final right = _rightInspector;
    final conflict = testCheckedCatalog(
      types: _types,
      presentations: [left, right],
      presentationMaterials: [
        inspectorMaterial(left, [
          presentationPart("left", key, textFieldNode("name")),
        ]),
        inspectorMaterial(right, [
          presentationPart(
            "right",
            key,
            textFieldNode("sibling", field: "sibling"),
          ),
        ]),
      ],
    );
    expect(
      conflict.partPresentation(
        completeSelection(_child),
        key,
        skir.PresentationRole.inspector,
      ),
      isA<ConflictingEditorPartPresentation>(),
    );
  });

  test("part footprints reject owner remainders and accept scoped descendant remainders", () {
    final key = skir.PresentationPartId(owner: _base, name: "details");
    final descriptor = _baseInspector;
    final remainder = presentationNode(
      "remaining",
      skir.PresentationElement.createRemainingFields(
        excluded: const [],
        excludedParts: const [],
      ),
    );
    final invalid = testCheckedCatalog(
      types: _types,
      presentations: [descriptor],
      presentationMaterials: [
        inspectorMaterial(descriptor, [
          presentationPart("details", key, remainder),
        ]),
      ],
    );
    expect(
      invalid.partPresentation(
        completeSelection(_child),
        key,
        skir.PresentationRole.inspector,
      ),
      isA<InvalidEditorPartPresentation>(),
    );
    expect(
      invalid.inspectorField(_child, "name"),
      isA<MissingEditorFieldPresentation>(),
    );
    final scoped = presentationNode(
      "scope",
      skir.PresentationElement.createScopedBinding(
        binding: fieldControl("nested").binding,
        scopeBinding: declareNamedBinding(
          "configured_value",
          skir.TypeTemplate.createNamed(
            definition: _child,
            arguments: const [],
          ),
        ),
        child: remainder,
      ),
    );
    final valid = testCheckedCatalog(
      types: _types,
      presentations: [descriptor],
      presentationMaterials: [
        inspectorMaterial(descriptor, [
          presentationPart("details", key, scoped),
        ]),
      ],
    );
    expect(
      (valid.partPresentation(
        completeSelection(_child),
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
      final descriptor = _baseInspector;
      final body = presentationNode(
        "nested.scope",
        skir.PresentationElement.createScopedBinding(
          binding: fieldControl("nested").binding,
          scopeBinding: declareNamedBinding(
            "configured_value",
            skir.TypeTemplate.createNamed(
              definition: _child,
              arguments: const [],
            ),
          ),
          child: presentationPart("nested.call", key, null),
        ),
      );
      final catalog = testCheckedCatalog(
        types: _types,
        presentations: [descriptor],
        presentationMaterials: [
          inspectorMaterial(descriptor, [
            presentationPart("details", key, body),
          ]),
        ],
      );
      final selected = catalog.partPresentation(
        completeSelection(_child),
        key,
        skir.PresentationRole.inspector,
      ) as SelectedEditorPartPresentation;
      expect(selected.editedFields, {"nested"});
      expect(selected.fallbackFields, {"nested"});
    },
  );

  test("ancestor layout skips equivalent target alternatives and preserves members", () {
    final family = _familyInspector;
    final alternative = inspectorDescriptor(
      "alternative",
      _child,
      namespace: "field_test",
      priority: -1,
    );
    final remainder = presentationNode(
      "remainder",
      skir.PresentationElement.createRemainingFields(
        excluded: const [],
        excludedParts: const [],
      ),
    );
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [family, alternative],
      presentationMaterials: [
        inspectorMaterial(
          family,
          [textFieldNode("name"), remainder],
          references: ["root", "name", "remainder"],
        ),
        inspectorMaterial(
          alternative,
          [remainder],
          references: ["root", "remainder"],
        ),
      ],
    );
    final selected = catalog.nextInspectorLayout(
      actualOwner: completeSelection(_child),
      below: alternative.target,
    ) as SelectedEditorInspectorLayout;
    expect(selected.descriptor.id, family.id);
    expect(selected.inheritableNodes, {"root", "name", "remainder"});
  });

  for (final count in [0, 2]) {
    test(
      "a source with $count remainders still contributes field behavior",
      () {
        final family = _familyInspector;
        final child = _childInspector;
        final nodes = [
          textFieldNode("name"),
          for (var i = 0; i < count; i++)
            presentationNode(
              "remaining.$i",
              skir.PresentationElement.createRemainingFields(
                excluded: const [],
                excludedParts: const [],
              ),
            ),
        ];
        final catalog = testCheckedCatalog(
          types: _types,
          presentations: [family],
          presentationMaterials: [inspectorMaterial(family, nodes)],
        );
        expect(
          catalog.nextInspectorLayout(
            actualOwner: completeSelection(_child),
            below: child.target,
          ),
          isA<MissingEditorInspectorLayout>(),
        );
        expect(
          catalog.inspectorField(_child, "name"),
          isA<SelectedEditorFieldPresentation>(),
        );
      },
    );
  }

  test("placeholder positions do not compete with concrete field behavior", () {
    final base = _baseInspector;
    final child = _childInspector;
    final request = presentationNode(
      "request",
      skir.PresentationElement.createDefaultPresentation(
        control: fieldControl("name"),
        presentationId: null,
      ),
    );
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [base, child],
      presentationMaterials: [
        inspectorMaterial(base, [textFieldNode("name")]),
        inspectorMaterial(child, [request]),
      ],
    );
    final selected = catalog.inspectorField(
      _child,
      "name",
    ) as SelectedEditorFieldPresentation;
    expect(selected.identity.provider, base.id);
  });

  test("part replacement keeps ancestor fallback suppression separate from live editors", () {
    final key = skir.PresentationPartId(owner: _base, name: "details");
    final base = _baseInspector;
    final child = _childInspector;
    final baseBody = textFieldNode("name");
    final childBody = presentationNode(
      "display",
      skir.PresentationElement.createSpacer(width: null, height: null),
    );
    final baseMaterial = inspectorMaterial(base, [
      presentationPart("base.part", key, baseBody),
    ]);
    final childMaterial = inspectorMaterial(child, [
      presentationPart("child.part", key, childBody),
    ]);
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [base, child],
      presentationMaterials: [baseMaterial, childMaterial],
    );
    final selected = catalog.partPresentation(
      completeSelection(_child),
      key,
      skir.PresentationRole.inspector,
    ) as SelectedEditorPartPresentation;
    expect(selected.body, childBody);
    expect(selected.editedFields, isEmpty);
    expect(selected.fallbackFields, {"name"});
    final local = catalog.partPresentation(
      completeSelection(_child),
      key,
      skir.PresentationRole.inspector,
      local: EditorPartDeclaration(
        material: childMaterial,
        body: textFieldNode("sibling", field: "sibling"),
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
      final descriptor = inspectorDescriptor(
        "parts",
        _base,
        namespace: "field_test",
      );
      final material = inspectorMaterial(descriptor, [
        presentationPart(
          "first",
          first,
          presentationPart("second.call", second, null),
        ),
        presentationPart("second", second, textFieldNode("name")),
      ]);
      final catalog = testCheckedCatalog(
        types: _types,
        presentations: [descriptor],
        presentationMaterials: [material],
      );
      final selected = catalog.partPresentation(
        completeSelection(_child),
        first,
        skir.PresentationRole.inspector,
      ) as SelectedEditorPartPresentation;
      expect(selected.editedFields, {"name"});
      expect(selected.claimedParts, {first, second});
      final cycle = inspectorMaterial(descriptor, [
        presentationPart(
          "first",
          first,
          presentationPart("second.call", second, null),
        ),
        presentationPart(
          "second",
          second,
          presentationPart("first.call", first, null),
        ),
      ]);
      expect(
        (testCheckedCatalog(
                  types: _types,
                  presentations: [descriptor],
                  presentationMaterials: [cycle],
                ).partPresentation(
                  completeSelection(_child),
                  first,
                  skir.PresentationRole.inspector,
                )
                as InvalidEditorPartPresentation)
            .diagnostic,
        contains("recursive"),
      );
      expect(
        catalog.partPresentation(
          completeSelection(_child),
          skir.PresentationPartId(owner: _base, name: "missing"),
          skir.PresentationRole.inspector,
        ),
        isA<MissingEditorPartPresentation>(),
      );
    },
  );

  test("sibling expression reads and scoped editors of the same field are reusable", () {
    final descriptor = _childInspector;
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
        (fieldControl("name").toMutable()
              ..label = skir.ExpressionNode.createInput(
                binding: skir.ExpressionBindingId(value: "configured_value"),
                path: fieldControl("sibling").binding.path,
              )
              ..prefix = presentationNode(
                "scope",
                skir.PresentationElement.createScopedBinding(
                  binding: fieldControl("name").binding,
                  scopeBinding: declareBinding(alias, textTemplate),
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
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [descriptor],
      presentationMaterials: [
        inspectorMaterial(descriptor, [source]),
      ],
    );
    final selected = catalog.inspectorField(
      _child,
      "name",
    ) as SelectedEditorFieldPresentation;
    expect(selected.identity.provider, descriptor.id);
    expect(selected.identity.field, "name");
    expect(selected.node, source);
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
        final descriptor = _childInspector;
        final sibling = textFieldNode("foreign", field: "sibling");
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
          "part_request" || "part_definition" => presentationPart(
            "part",
            skir.PresentationPartId(owner: _base, name: "heading"),
            placement == "part_definition" ? textFieldNode("owned") : null,
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
                  ? fieldControl("sibling").binding
                  : skir.BindingRef(
                      bindingId: skir.ExpressionBindingId(value: "unknown"),
                      path: skir.ValuePath.defaultInstance,
                    ),
              scopeBinding: declareBinding(alias, textTemplate),
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
                    binding: fieldControl(
                      placement == "custom_invocation" ? "name" : "sibling",
                    ).binding,
                  ),
                ],
              ),
            ),
          ),
          _ => sibling,
        };
        final source = textFieldNode("name").toMutable();
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
        final catalog = testCheckedCatalog(
          types: _types,
          presentations: [descriptor],
          presentationMaterials: [
            inspectorMaterial(descriptor, [source.toFrozen()]),
          ],
        );
        final selected = catalog.inspectorField(
          _child,
          "name",
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
          (inspectorDescriptor(
                  "record",
                  _base,
                  namespace: "field_test",
                ).toMutable()
                ..target = skir.PresentationTarget.wrapRepresentation(
                  skir.RepresentationKind.record,
                ))
              .toFrozen();
      skir.PresentationMaterial material(skir.TypeDefinitionId subject) =>
          (inspectorMaterial(
            inspectorDescriptor("record", subject, namespace: "field_test"),
            [textFieldNode("name")],
          ).toMutable()..target = descriptor.target).toFrozen();
      final baseMaterial = material(_base);
      final childMaterial = material(_child);
      final catalog = testCheckedCatalog(
        types: _types,
        presentations: [descriptor],
        presentationMaterials: [baseMaterial, childMaterial],
      );

      final selected = catalog.inspectorField(
        _child,
        "name",
      ) as SelectedEditorFieldPresentation;
      expect(selected.material, same(childMaterial));
      expect(
        catalog.inspectorField(_left, "name"),
        isA<MissingEditorFieldPresentation>(),
      );
    },
  );

  test(
    "an inherited field retains its source node and material dependencies",
    () {
      final base = inspectorDescriptor(
        "base",
        _base,
        namespace: "field_test",
        priority: 100,
      );
      final material = inspectorMaterial(base, [textFieldNode("base.name")]);
      final catalog = testCheckedCatalog(
        types: _types,
        presentations: [base],
        presentationMaterials: [material],
      );

      final selected = catalog.inspectorField(
        _child,
        "name",
      ) as SelectedEditorFieldPresentation;

      expect(selected.material, same(material));
      expect(selected.node.nodeId, "base.name");
      expect(selected.identity.provider, base.id);
      expect(selected.identity.subject, material.subject);
      expect(
        catalog.inspectorField(_child, "other"),
        isA<MissingEditorFieldPresentation>(),
      );
      expect(
        catalog.fieldPresentation(
          completeSelection(_child),
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
      final base = inspectorDescriptor(
        "base",
        _base,
        namespace: "field_test",
        priority: 1000,
      );
      final left = _leftInspector;
      final right = _rightInspector;
      final child = _childInspector;
      final descriptors = [base, left, right, child];
      final materials = [
        for (final descriptor in descriptors)
          inspectorMaterial(descriptor, [
            textFieldNode("${descriptor.id.name}.name"),
          ]),
      ];

      final parents = testCheckedCatalog(
        types: _types,
        presentations: descriptors.take(3).toList(),
        presentationMaterials: materials.take(3).toList(),
      );
      final conflict = parents.inspectorField(
        _child,
        "name",
      ) as ConflictingEditorFieldPresentation;
      expect(
        conflict.candidates.map((candidate) => candidate.provider),
        containsAll([left.id, right.id]),
      );
      expect(conflict.candidates.length, 2);

      final resolved =
          testCheckedCatalog(
                types: _types,
                presentations: descriptors,
                presentationMaterials: materials,
              ).fieldPresentation(
                completeSelection(_child),
                "name",
                skir.PresentationRole.inspector,
              )
              as SelectedEditorFieldPresentation;
      expect(resolved.identity.provider, child.id);
    },
  );

  test("equivalent target priority chooses a provider without collapsing its nodes", () {
    final low = _lowInspector;
    final high = inspectorDescriptor(
      "high",
      _base,
      namespace: "field_test",
      priority: 2,
    );
    final lowMaterial = inspectorMaterial(low, [textFieldNode("low.name")]);
    final highMaterial = inspectorMaterial(high, [
      textFieldNode("high.first"),
      textFieldNode("high.second"),
    ]);
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [low, high],
      presentationMaterials: [lowMaterial, highMaterial],
    );

    final conflict = catalog.inspectorField(
      _child,
      "name",
    ) as ConflictingEditorFieldPresentation;
    expect(conflict.candidates.map((candidate) => candidate.nodeId), [
      "high.first",
      "high.second",
    ]);

    final single =
        testCheckedCatalog(
              types: _types,
              presentations: [low, high],
              presentationMaterials: [
                lowMaterial,
                inspectorMaterial(high, [textFieldNode("high.only")]),
              ],
            ).fieldPresentation(
              completeSelection(_child),
              "name",
              skir.PresentationRole.inspector,
            )
            as SelectedEditorFieldPresentation;
    expect(single.identity.provider, high.id);
  });

  test("a more specific placeholder contributes no candidate and keeps inheritance", () {
    final base = _baseInspector;
    final child = inspectorDescriptor(
      "child",
      _child,
      namespace: "field_test",
      priority: 100,
    );
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [base, child],
      presentationMaterials: [
        inspectorMaterial(base, [textFieldNode("base.name")]),
        inspectorMaterial(child, [
          presentationNode(
            "child.name",
            skir.PresentationElement.createDefaultPresentation(
              control: fieldControl("name"),
              presentationId: null,
            ),
          ),
        ], references: const []),
      ],
    );
    final selected = catalog.inspectorField(
      _child,
      "name",
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
        final base = _baseInspector;
        final child = _childInspector;
        final nodes = switch (problem) {
          "missing" => [textFieldNode("other")],
          "duplicate" => [textFieldNode("bad"), textFieldNode("bad")],
          "unknown_field" => [textFieldNode("bad", field: "other")],
          "wrong_type" => [
            presentationNode(
              "bad",
              skir.PresentationElement.wrapToggleInput(
                (skir.ToggleControl.defaultInstance.toMutable()
                      ..control = fieldControl("name"))
                    .toFrozen(),
              ),
            ),
          ],
          _ => throw StateError(problem),
        };
        final material = inspectorMaterial(child, nodes, references: ["bad"]);
        final catalog = testCheckedCatalog(
          types: _types,
          presentations: [base, child],
          presentationMaterials: [
            inspectorMaterial(base, [textFieldNode("base.name")]),
            material,
          ],
        );
        final selection = catalog.fieldPresentation(
          completeSelection(_child),
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
      final left = inspectorDescriptor("left", _left, namespace: "field_test");
      final right = inspectorDescriptor(
        "right",
        _right,
        namespace: "field_test",
      );
      final catalog = testCheckedCatalog(
        types: _types,
        presentations: [left, right],
        presentationMaterials: [
          inspectorMaterial(left, [textFieldNode("same")]),
          inspectorMaterial(right, [textFieldNode("same")]),
        ],
      );
      final leftChoice = catalog.inspectorField(
        _left,
        "name",
      ) as SelectedEditorFieldPresentation;
      final rightChoice = catalog.inspectorField(
        _right,
        "name",
      ) as SelectedEditorFieldPresentation;
      expect(leftChoice.identity, isNot(rightChoice.identity));
      expect(leftChoice.node.nodeId, rightChoice.node.nodeId);
    },
  );

  test(
    "structural indexing visits control prefixes once alongside choice content",
    () {
      final prefix = textFieldNode("prefix");
      final option = textFieldNode("option");
      final node = presentationNode(
        "choice",
        skir.PresentationElement.wrapSelectInput(
          (skir.SelectControl.defaultInstance.toMutable()
                ..control = (fieldControl("name").toMutable()..prefix = prefix)
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
    final base = _baseInspector;
    final child = _childInspector;
    final catalog = testCheckedCatalog(
      types: _types,
      presentations: [base, child],
      presentationMaterials: [
        inspectorMaterial(base, [textFieldNode("base.name")]),
      ],
    );
    expect(
      catalog.selectPresentation(
        completeSelection(_child),
        skir.PresentationRole.inspector,
      ),
      isA<UnavailableEditorPresentation>(),
    );
  });

  test("display icon descendants participate in source node uniqueness", () {
    final descriptor = _childInspector;
    final appearance =
        (skir.DisplayAppearance.defaultInstance.toMutable()
              ..icon = skir.InputAdornment.wrapContent(
                textFieldNode("name", field: "sibling"),
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
      final catalog = testCheckedCatalog(
        types: _types,
        presentations: [descriptor],
        presentationMaterials: [
          inspectorMaterial(
            descriptor,
            [textFieldNode("name"), presentationNode("display", display)],
            references: ["name"],
          ),
        ],
      );
      final invalid = catalog.inspectorField(
        _child,
        "name",
      ) as InvalidEditorFieldPresentation;
      expect(
        invalid.diagnostic,
        contains("ambiguous"),
        reason: display.runtimeType.toString(),
      );
    }
  });
}

final _base = typeDefinition("Base", namespace: "field_test");
final _left = typeDefinition("Left", namespace: "field_test");
final _right = typeDefinition("Right", namespace: "field_test");
final _child = typeDefinition("Child", namespace: "field_test");

final _fields = {
  "nested": skir.TypeTemplate.createNamed(
    definition: _child,
    arguments: const [],
  ),
  "name": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
  "sibling": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
};

/// A diamond: Left and Right refine Base, Child refines all three; every
/// type has Base's fields.
final _types = [
  for (final (definition, ancestors) in [
    (_base, <skir.TypeDefinitionId>[]),
    (_left, [_base]),
    (_right, [_base]),
    (_child, [_left, _right, _base]),
  ])
    declaredRecord(
      definition,
      fields: _fields,
      inheritedFrom: definition == _base ? null : _base,
      parents: ancestors,
    ),
];
