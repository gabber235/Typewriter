package com.typewritermc.presentation

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.RepresentationKind
import com.typewritermc.types.PresentationId
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import com.typewritermc.types.catalog.toWire
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.AxisChildrenElement
import skirout.editor.v1.presentation.BoundControl
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationDependencies
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationProperties
import skirout.editor.v1.presentation.TextControl
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ValuePath

val FieldPresentationInferenceTest by testSuite {
    test("infers complete root controls and direct named choices including positioning placeholders") {
        val concrete = fieldNode("name")
        concrete.inferInheritableNodes() shouldBe listOf("name")
        val named =
            concrete.copy(
                element =
                    PresentationElement.createDefaultPresentation(
                        control = fieldControl("name"),
                        presentationId =
                            skirout.editor.v1.type_catalog
                                .PresentationId(namespace = "test", name = "text"),
                    ),
            )
        named.inferInheritableNodes() shouldBe concrete.inferInheritableNodes()
        named
            .copy(
                element = PresentationElement.createDefaultPresentation(control = fieldControl("name"), presentationId = null),
            ).inferInheritableNodes() shouldBe listOf("name")
        concrete
            .copy(properties = PresentationProperties(readOnly = true, enabledIf = null))
            .inferInheritableNodes() shouldBe concrete.inferInheritableNodes()
    }

    test("neutral spatial nesting preserves all declarations and stops at behavioral boundaries") {
        val first = fieldNode("name")
        val duplicate = first.copy(nodeId = "second name")
        val spatial = column("root", column("nested", first), duplicate)
        spatial.inferInheritableNodes() shouldBe
            listOf("root", "nested", "name", "second name")
        spatial
            .copy(properties = PresentationProperties(readOnly = true, enabledIf = null))
            .inferInheritableNodes() shouldBe emptyList()
        val condition =
            skirout.editor.v1.expression.ExpressionNode.LiteralWrapper(
                skirout.editor.v1.type_catalog.DataValue
                    .BooleanWrapper(true),
            )
        spatial
            .copy(properties = PresentationProperties(readOnly = false, enabledIf = condition))
            .inferInheritableNodes() shouldBe emptyList()
        spatial
            .copy(
                header =
                    skirout.editor.v1.presentation.PresentationHeader
                        .partial(),
            ).inferInheritableNodes() shouldBe emptyList()
        val placements =
            listOf(
                ChildrenElement.RowWrapper(AxisChildrenElement.partial(children = listOf(AxisChild.FixedWrapper(first)))),
                ChildrenElement.WrapWrapper(
                    skirout.editor.v1.presentation.WrapChildrenElement
                        .partial(children = listOf(first)),
                ),
                ChildrenElement.GridWrapper(
                    skirout.editor.v1.presentation.GridChildrenElement
                        .partial(children = listOf(first)),
                ),
                ChildrenElement.StackWrapper(
                    skirout.editor.v1.presentation.StackChildrenElement
                        .partial(children = listOf(first)),
                ),
            )
        placements.forEach { placement ->
            first
                .copy(nodeId = "placement", element = PresentationElement.ChildrenWrapper(placement))
                .inferInheritableNodes() shouldBe listOf("placement", "name")
        }
        val boundaries =
            listOf(
                PresentationElement.RepeatedWrapper(
                    skirout.editor.v1.presentation.RepeatedElement.partial(
                        presentation =
                            skirout.editor.v1.presentation.SequencePresentation
                                .partial(item = first),
                    ),
                ),
                PresentationElement.AppearanceDefaultsWrapper(
                    skirout.editor.v1.presentation.AppearanceDefaultsElement
                        .partial(child = first),
                ),
                PresentationElement.PolymorphicMatchWrapper(
                    skirout.editor.v1.presentation.PolymorphicMatchElement
                        .partial(fallback = first),
                ),
                PresentationElement.CollectionLookupWrapper(
                    skirout.editor.v1.presentation.CollectionLookupElement
                        .partial(found = first, missing = first),
                ),
                PresentationElement.createConditional(
                    condition =
                        skirout.editor.v1.expression.ExpressionNode.LiteralWrapper(
                            skirout.editor.v1.type_catalog.DataValue
                                .BooleanWrapper(true),
                        ),
                    whenTrue = first,
                    whenFalse = null,
                ),
                PresentationElement.createScopedBinding(
                    binding = fieldControl("name").binding,
                    scopeBindingId = ExpressionBindingId(value = "scope"),
                    child = first,
                ),
                PresentationElement.createTypedField(
                    binding = fieldControl("name").binding,
                    expectedType =
                        skirout.editor.v1.type_catalog.TypeTemplate
                            .ScalarWrapper(skirout.editor.v1.type_catalog.ScalarKind.TEXT),
                    presentation = first,
                ),
                PresentationElement.createPadding(
                    child = first,
                    top = 0.0,
                    start = 0.0,
                    end = 0.0,
                    bottom = 0.0,
                ),
            )
        boundaries.forEach { element ->
            first.copy(nodeId = "boundary", element = element).inferInheritableNodes() shouldBe emptyList()
        }
    }

    test("hidden sibling editors remain local while sibling expressions are allowed") {
        val hidden =
            fieldNode("message").copy(
                nodeId = "hidden",
                element =
                    PresentationElement.createConditional(
                        condition =
                            skirout.editor.v1.expression.ExpressionNode.LiteralWrapper(
                                skirout.editor.v1.type_catalog.DataValue
                                    .BooleanWrapper(false),
                            ),
                        whenTrue = fieldNode("message"),
                        whenFalse = null,
                    ),
            )
        val name =
            fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(control = fieldControl("name").copy(prefix = hidden)),
                    ),
            )
        name.inferInheritableNodes() shouldBe emptyList()
        name
            .copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control =
                                fieldControl("name").copy(
                                    label =
                                        skirout.editor.v1.expression.ExpressionNode.createInput(
                                            binding = ExpressionBindingId(value = "configured_value"),
                                            path = fieldControl("message").binding.path,
                                        ),
                                ),
                        ),
                    ),
            ).inferInheritableNodes() shouldBe listOf("name")
    }

    test("scoped aliases preserve field ownership and reject foreign or unknown writes") {
        val editor =
            fieldNode("name").copy(
                nodeId = "aliased editor",
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control =
                                fieldControl("name").copy(
                                    binding =
                                        BindingRef(
                                            bindingId = ExpressionBindingId(value = "alias"),
                                            path = ValuePath(segments = emptyList()),
                                        ),
                                ),
                        ),
                    ),
            )

        fun withScope(source: BindingRef) =
            fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control =
                                fieldControl("name").copy(
                                    prefix =
                                        PresentationNode.partial(
                                            nodeId = "scope",
                                            element =
                                                PresentationElement.createScopedBinding(
                                                    binding = source,
                                                    scopeBindingId = ExpressionBindingId(value = "alias"),
                                                    child = editor,
                                                ),
                                        ),
                                ),
                        ),
                    ),
            )
        withScope(fieldControl("name").binding).inferInheritableNodes() shouldBe listOf("name")
        withScope(fieldControl("message").binding).inferInheritableNodes() shouldBe emptyList()
        withScope(fieldControl("name").binding.copy(bindingId = ExpressionBindingId(value = "foreign")))
            .inferInheritableNodes() shouldBe emptyList()
        fieldNode("name")
            .copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control = fieldControl("name").copy(prefix = editor),
                        ),
                    ),
            ).inferInheritableNodes() shouldBe emptyList()
    }

    test("an alias to the owner record can still select the owned field") {
        val rootBinding = BindingRef(bindingId = ExpressionBindingId(value = "configured_value"), path = ValuePath(segments = emptyList()))
        val aliased =
            fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control =
                                fieldControl(
                                    "name",
                                ).copy(binding = fieldControl("name").binding.copy(bindingId = ExpressionBindingId(value = "record"))),
                        ),
                    ),
            )
        val prefix =
            PresentationNode.partial(
                nodeId = "record scope",
                element =
                    PresentationElement.createScopedBinding(
                        binding = rootBinding,
                        scopeBindingId = ExpressionBindingId(value = "record"),
                        child = aliased.copy(nodeId = "aliased name"),
                    ),
            )
        fieldNode("name")
            .copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control = fieldControl("name").copy(prefix = prefix),
                        ),
                    ),
            ).inferInheritableNodes() shouldBe listOf("name")
    }

    test("nested record and collection editors remain within their owning field") {
        val item =
            fieldNode("title").copy(
                nodeId = "item title",
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control =
                                fieldControl("title").copy(
                                    binding = fieldControl("title").binding.copy(bindingId = ExpressionBindingId(value = "item")),
                                ),
                        ),
                    ),
            )
        val list =
            PresentationNode.partial(
                nodeId = "items",
                element =
                    PresentationElement.ListInputWrapper(
                        skirout.editor.v1.presentation.ListControl.partial(
                            control = fieldControl("items"),
                            itemBindingId = ExpressionBindingId(value = "item"),
                            indexBindingId = ExpressionBindingId(value = "index"),
                            itemPresentation = item,
                        ),
                    ),
            )
        list.inferInheritableNodes() shouldBe listOf("items")
        val nested =
            fieldNode("details").copy(
                element =
                    PresentationElement.RecordInputWrapper(
                        skirout.editor.v1.presentation.RecordControl.partial(
                            control = fieldControl("details"),
                            fieldPresentation =
                                fieldNode("title").copy(
                                    element =
                                        PresentationElement.TextInputWrapper(
                                            TextControl.partial(
                                                control =
                                                    fieldControl("title").copy(
                                                        binding =
                                                            fieldControl("title").binding.copy(
                                                                path =
                                                                    ValuePath(
                                                                        segments =
                                                                            listOf(
                                                                                PathSegment.createField(name = "details"),
                                                                                PathSegment.createField(name = "title"),
                                                                            ),
                                                                    ),
                                                            ),
                                                    ),
                                            ),
                                        ),
                                ),
                        ),
                    ),
            )
        nested.inferInheritableNodes() shouldBe listOf("details")
        val foreign =
            list.copy(
                element =
                    PresentationElement.ListInputWrapper(
                        (list.element as PresentationElement.ListInputWrapper).value.copy(itemPresentation = fieldNode("message")),
                    ),
            )
        foreign.inferInheritableNodes() shouldBe emptyList()
    }

    test("implicit editable layouts require a proven field scope") {
        val remaining =
            PresentationNode.partial(
                nodeId = "remaining",
                element = PresentationElement.createRemainingFields(excluded = emptyList(), excludedParts = emptyList()),
            )
        val root =
            fieldNode("details").copy(
                element =
                    PresentationElement.RecordInputWrapper(
                        skirout.editor.v1.presentation.RecordControl
                            .partial(control = fieldControl("details"), fieldPresentation = remaining),
                    ),
            )
        root.inferInheritableNodes() shouldBe emptyList()
        val scoped =
            remaining.copy(
                nodeId = "scoped",
                element =
                    PresentationElement.createScopedBinding(
                        binding = fieldControl("details").binding,
                        scopeBindingId = ExpressionBindingId(value = "configured_value"),
                        child = remaining,
                    ),
            )
        root
            .copy(
                element =
                    PresentationElement.RecordInputWrapper(
                        (root.element as PresentationElement.RecordInputWrapper).value.copy(fieldPresentation = scoped),
                    ),
            ).inferInheritableNodes() shouldBe listOf("details")
    }

    test("rendering invocation cannot hide the owner record behind a custom input") {
        fun withArgument(input: String): PresentationNode {
            val invocation =
                PresentationNode.partial(
                    nodeId = "invoked",
                    element =
                        PresentationElement.createInvocation(
                            presentationId =
                                skirout.editor.v1.type_catalog
                                    .PresentationId(namespace = "test", name = "input"),
                            arguments =
                                listOf(
                                    skirout.editor.v1.presentation.PresentationArgument(
                                        input = ExpressionBindingId(value = input),
                                        binding = fieldControl("name").binding,
                                    ),
                                ),
                        ),
                )
            return fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control = fieldControl("name").copy(prefix = invocation),
                        ),
                    ),
            )
        }
        withArgument("custom").inferInheritableNodes() shouldBe emptyList()
        withArgument("configured_value").inferInheritableNodes() shouldBe listOf("name")
    }

    test("external collection row bindings shadow owned aliases") {
        val row =
            fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control =
                                fieldControl("name").copy(
                                    binding =
                                        BindingRef(
                                            bindingId = ExpressionBindingId(value = "owned"),
                                            path = ValuePath(segments = emptyList()),
                                        ),
                                ),
                        ),
                    ),
            )
        val lookup =
            PresentationNode.partial(
                nodeId = "lookup",
                element =
                    PresentationElement.CollectionLookupWrapper(
                        skirout.editor.v1.presentation.CollectionLookupElement
                            .partial(sourceId = "external", found = row),
                    ),
            )
        val scope =
            PresentationNode.partial(
                nodeId = "scope",
                element =
                    PresentationElement.createScopedBinding(
                        binding = fieldControl("name").binding,
                        scopeBindingId = ExpressionBindingId(value = "owned"),
                        child = lookup,
                    ),
            )
        val name =
            fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control = fieldControl("name").copy(prefix = scope),
                        ),
                    ),
            )
        val dependencies =
            PresentationDependencies.partial(
                collections =
                    listOf(
                        skirout.editor.v1.presentation.PresentationCollectionDefinition.partial(
                            sourceId = "external",
                            rowBindingId = ExpressionBindingId(value = "owned"),
                        ),
                    ),
            )
        name.inferInheritableNodes(dependencies) shouldBe emptyList()
    }

    test("search result aliases remain foreign through provider composition") {
        val result =
            skirout.editor.v1.presentation.SearchResultMapping.partial(
                bindingId = ExpressionBindingId(value = "configured_value"),
                presentation = fieldNode("name"),
            )
        val source =
            skirout.editor.v1.presentation.SearchProvider.StaticValuesWrapper(
                skirout.editor.v1.presentation.StaticSearchProvider
                    .partial(result = result),
            )
        val merged =
            skirout.editor.v1.presentation.SearchProvider.MergeWrapper(
                skirout.editor.v1.presentation.MergedSearchProvider
                    .partial(children = listOf(source)),
            )
        val name =
            fieldNode("name").copy(
                element =
                    PresentationElement.SearchInputWrapper(
                        skirout.editor.v1.presentation.SearchControl.partial(
                            control = fieldControl("name"),
                            provider = merged,
                        ),
                    ),
            )
        name.inferInheritableNodes() shouldBe emptyList()
    }

    test("only direct configured owner fields qualify") {
        val node = fieldNode("name")
        val control = fieldControl("name")
        listOf(
            control.binding.copy(bindingId = ExpressionBindingId(value = "list_item")),
            control.binding.copy(path = ValuePath(segments = emptyList())),
            control.binding.copy(
                path = ValuePath(segments = listOf(PathSegment.createField(name = "nested"), PathSegment.createField(name = "name"))),
            ),
        ).forEach { binding ->
            node
                .copy(element = PresentationElement.TextInputWrapper(TextControl.partial(control = control.copy(binding = binding))))
                .inferInheritableNodes() shouldBe emptyList()
        }
    }

    test("named parts keep complete bodies atomic and publish the owner remainder") {
        val part = partNode("details", column("body", fieldNode("name"), fieldNode("message")))
        val layout = column("root", part, remainder("rest"))
        layout.inferInheritableNodes() shouldBe listOf("root", "details", "rest")
        layout.validateInheritableNodes(layout.inferInheritableNodes()) { true }
    }

    test("explicit definitions reject unsafe ancestry and duplicate keys rather than silently staying local") {
        val part = partNode("details", fieldNode("name"))
        val conditional =
            PresentationNode.partial(
                nodeId = "condition",
                element =
                    skirout.editor.v1.presentation.PresentationElement.createConditional(
                        condition =
                            skirout.editor.v1.expression.ExpressionNode.LiteralWrapper(
                                skirout.editor.v1.type_catalog.DataValue
                                    .BooleanWrapper(true),
                            ),
                        whenTrue = part,
                        whenFalse = null,
                    ),
            )
        shouldThrow<IllegalArgumentException> {
            conditional.validateInheritableNodes(conditional.inferInheritableNodes()) { true }
        }
        val duplicate =
            column(
                "root",
                part,
                part.copy(
                    nodeId = "second",
                    element =
                        PresentationElement.createPart(
                            key = (part.element as PresentationElement.PartWrapper).value.key,
                            body = fieldNode("other"),
                        ),
                ),
            )
        shouldThrow<IllegalArgumentException> {
            duplicate.validateInheritableNodes(duplicate.inferInheritableNodes()) { true }
        }
        shouldThrow<IllegalArgumentException> {
            part.validateInheritableNodes(part.inferInheritableNodes(), partOwnerCompatible = { false }) { true }
        }
    }

    test("part bodies permit hidden owner editors and nested record remainders but reject foreign or whole owner writes") {
        val nested =
            PresentationNode.partial(
                nodeId = "scope",
                element =
                    PresentationElement.createScopedBinding(
                        binding = fieldControl("details").binding,
                        scopeBindingId = ExpressionBindingId(value = "configured_value"),
                        child = remainder("nested remainder"),
                    ),
            )
        partNode("details", nested).let { it.validateInheritableNodes(it.inferInheritableNodes()) { true } }
        listOf(
            remainder("owner remainder"),
            fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control =
                                fieldControl(
                                    "name",
                                ).copy(binding = BindingRef.partial(bindingId = ExpressionBindingId(value = "foreign"))),
                        ),
                    ),
            ),
            fieldNode("name").copy(
                element =
                    PresentationElement.TextInputWrapper(
                        TextControl.partial(
                            control = fieldControl("name").copy(binding = fieldControl("name").binding.copy(path = ValuePath.partial())),
                        ),
                    ),
            ),
        ).forEach { body ->
            val part = partNode("details", body)
            shouldThrow<IllegalArgumentException> { part.validateInheritableNodes(part.inferInheritableNodes()) { true } }
        }
    }

    test("dynamic part calls stay out of field defaults while bounded part composition remains valid") {
        val request = partNode("heading", null)
        listOf(request, partNode("heading", fieldNode("message"))).forEach { nestedPart ->
            val control = fieldControl("name").copy(prefix = nestedPart)
            val field = fieldNode("name").copy(element = PresentationElement.TextInputWrapper(TextControl.partial(control = control)))
            field.inferInheritableNodes() shouldBe emptyList()
        }
        val parent = partNode("details", column("body", fieldNode("name"), request))
        parent.inferInheritableNodes() shouldBe listOf("details")
        parent.validateInheritableNodes(parent.inferInheritableNodes()) { true }
        shouldThrow<IllegalArgumentException> {
            parent.validateInheritableNodes(parent.inferInheritableNodes(), partOwnerCompatible = { it.name != "heading" }) { true }
        }
    }

    test("reference admission rejects duplicate node identities and nonexistent owner fields") {
        val field = fieldNode("name")
        val duplicate = column("root", field, field)
        shouldThrow<IllegalArgumentException> {
            duplicate.validateInheritableNodes(duplicate.inferInheritableNodes()) { true }
        }
        val separateDuplicate = column("root", field, field.copy(nodeId = "other name"))
        separateDuplicate.validateInheritableNodes(separateDuplicate.inferInheritableNodes()) { true }
        val unequalCollision = column("root", field, fieldNode("message").copy(nodeId = "name"))
        shouldThrow<IllegalArgumentException> {
            unequalCollision.validateInheritableNodes(unequalCollision.inferInheritableNodes()) { true }
        }
        val sharedLocal =
            column(
                "root",
                partNode("details", field),
                PresentationNode.partial(
                    nodeId = "local",
                    element =
                        PresentationElement.createScopedBinding(
                            binding = fieldControl("details").binding,
                            scopeBindingId = ExpressionBindingId(value = "local scope"),
                            child = field,
                        ),
                ),
            )
        sharedLocal.validateInheritableNodes(sharedLocal.inferInheritableNodes()) { true }
        shouldThrow<IllegalArgumentException> {
            field.validateInheritableNodes(field.inferInheritableNodes()) { false }
        }
        shouldThrow<IllegalArgumentException> {
            field.validateInheritableNodes(listOf("other")) { true }
        }
        field.validateInheritableNodes(field.inferInheritableNodes()) { it == "name" }
    }

    test("catalog wire roundtrip retains inferred node references without duplicating controls") {
        val layout = column("root", fieldNode("name"), partNode("details", fieldNode("message")), remainder("rest"))
        val material =
            PresentationMaterial(
                provider = PresentationId("test", "fields"),
                target = PresentationTarget.Representation(RepresentationKind.Record),
                subject = TypeTemplate.Scalar(ScalarKind.Text),
                role = PresentationRole.INSPECTOR,
                layout = layout,
                dependencies = PresentationDependencies.partial(),
                inheritableNodes = layout.inferInheritableNodes(),
            )
        val wire =
            EditorCatalogSnapshot(
                generation = CatalogGeneration("field defaults"),
                types = emptyList(),
                relations = emptyList(),
                resourceDisplays = emptyList(),
                realmRoot =
                    com.typewritermc.types.TypeDefinitionId(
                        com.typewritermc.types.TypeId
                            .Qualified("test", "realm.root"),
                        1,
                    ),
                presentations = emptyList(),
                presentationMaterials = listOf(material),
                configuration = emptyList(),
                diagnostics = emptyList(),
            ).toWire()
        val decoded =
            skirout.editor.v1.catalog.EditorCatalogWireSnapshot.serializer
                .fromBytes(
                    skirout.editor.v1.catalog.EditorCatalogWireSnapshot.serializer
                        .toBytes(wire),
                ).presentationMaterials
                .single()
        decoded.inheritableNodes shouldBe listOf("root", "name", "details", "rest")
        decoded.layout shouldBe layout
    }
}

private fun fieldControl(field: String): BoundControl =
    BoundControl.partial(
        binding =
            BindingRef(
                bindingId = ExpressionBindingId(value = "configured_value"),
                path = ValuePath(segments = listOf(PathSegment.createField(name = field))),
            ),
    )

private fun fieldNode(field: String): PresentationNode =
    PresentationNode.partial(
        nodeId = field,
        element = PresentationElement.TextInputWrapper(TextControl.partial(control = fieldControl(field))),
    )

private fun column(
    id: String,
    vararg children: PresentationNode,
): PresentationNode =
    PresentationNode.partial(
        nodeId = id,
        element =
            PresentationElement.ChildrenWrapper(
                ChildrenElement.ColumnWrapper(AxisChildrenElement.partial(children = children.map { AxisChild.FixedWrapper(it) })),
            ),
    )

private fun partNode(
    name: String,
    body: PresentationNode?,
): PresentationNode =
    PresentationNode.partial(
        nodeId = name,
        element =
            PresentationElement.createPart(
                key =
                    skirout.editor.v1.presentation.PresentationPartId(
                        owner =
                            com.typewritermc.types.skir.SkirTypeCodec
                                .encode(
                                    com.typewritermc.types.TypeDefinitionId(
                                        com.typewritermc.types.TypeId
                                            .Qualified("test", "PartOwner"),
                                        1,
                                    ),
                                ).getOrThrow(),
                        name = name,
                    ),
                body = body,
            ),
    )

private fun remainder(id: String): PresentationNode =
    PresentationNode.partial(
        nodeId = id,
        element = PresentationElement.createRemainingFields(excluded = emptyList(), excludedParts = emptyList()),
    )
