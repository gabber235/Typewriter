package com.typewritermc.presentation

import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.testkit.rejectionOf
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.binding.BindingRef
import skirout.editor.v1.presentation.PresentationDependencies
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationProperties
import skirout.editor.v1.presentation.TextControl
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.PresentationId
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
    }

    for ((name, placement) in neutralPlacements()) {
        test("a $name placement keeps its child inheritable") {
            fieldNode("name")
                .copy(nodeId = "placement", element = PresentationElement.ChildrenWrapper(placement))
                .inferInheritableNodes() shouldBe listOf("placement", "name")
        }
    }

    for ((name, element) in behavioralBoundaries()) {
        test("a $name stops inheritance") {
            fieldNode("name").copy(nodeId = "boundary", element = element).inferInheritableNodes() shouldBe emptyList()
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
                                            path = ValuePath.root,
                                        ),
                                ),
                        ),
                    ),
            )

        scopedNameNode(fieldControl("name").binding, editor).inferInheritableNodes() shouldBe listOf("name")
        scopedNameNode(fieldControl("message").binding, editor).inferInheritableNodes() shouldBe emptyList()
        scopedNameNode(fieldControl("name").binding.copy(bindingId = ExpressionBindingId(value = "foreign")), editor)
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
        val rootBinding = BindingRef(bindingId = ExpressionBindingId(value = "configured_value"), path = ValuePath.root)
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
                        scopeBinding = declared("record"),
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
                            itemBinding = declared("item"),
                            indexBinding = declared("index"),
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
                        scopeBinding = declared("configured_value"),
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
        invocationNameNode("custom").inferInheritableNodes() shouldBe emptyList()
        invocationNameNode("configured_value").inferInheritableNodes() shouldBe listOf("name")
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
                                            path = ValuePath.root,
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
                        scopeBinding = declared("owned"),
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
                            rowBinding = declared("owned"),
                        ),
                    ),
            )
        name.inferInheritableNodes(dependencies) shouldBe emptyList()
    }

    test("search result aliases remain foreign through provider composition") {
        val result =
            skirout.editor.v1.presentation.SearchResultMapping.partial(
                binding = declared("configured_value"),
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
            control.binding.copy(path = ValuePath.root),
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

    test("a part declared under a behavioral boundary is refused") {
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
        rejectionOf { conditional.validateInheritableNodes(conditional.inferInheritableNodes()) { true } } shouldBe
            "Presentation part declarations require neutral owner layout groups."
    }

    test("two definitions of one part in a material are refused") {
        val part = partNode("details", fieldNode("name"))
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
        rejectionOf { duplicate.validateInheritableNodes(duplicate.inferInheritableNodes()) { true } } shouldBe
            "Presentation part details has multiple definitions in one material."
    }

    test("a part whose declaring owner is incompatible is refused") {
        val part = partNode("details", fieldNode("name"))
        rejectionOf { part.validateInheritableNodes(part.inferInheritableNodes(), partOwnerCompatible = { false }) { true } } shouldBe
            "Presentation part details has an incompatible declaring owner."
    }

    test("a part body may hold a nested record remainder inside a scoped binding") {
        val nested =
            PresentationNode.partial(
                nodeId = "scope",
                element =
                    PresentationElement.createScopedBinding(
                        binding = fieldControl("details").binding,
                        scopeBinding = declared("configured_value"),
                        child = remainder("nested remainder"),
                    ),
            )
        partNode("details", nested).let { it.validateInheritableNodes(it.inferInheritableNodes()) { true } }
    }

    for ((name, body) in writesOutsideOwner()) {
        test("a part body with $name is refused") {
            val part = partNode("details", body)
            rejectionOf { part.validateInheritableNodes(part.inferInheritableNodes()) { true } } shouldBe
                "Presentation part details must have bounded editors within its owner record and no owner remainder."
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

    test("a node id shared by two distinct nodes is refused") {
        val field = fieldNode("name")
        val collision = column("root", field, fieldNode("message").copy(nodeId = "name"))
        rejectionOf { collision.validateInheritableNodes(collision.inferInheritableNodes()) { true } } shouldBe
            "Presentation node ids must not identify distinct nodes."
    }

    test("the same node placed twice yields one inherited reference") {
        val field = fieldNode("name")
        val duplicate = column("root", field, field)
        rejectionOf { duplicate.validateInheritableNodes(duplicate.inferInheritableNodes()) { true } } shouldBe
            "Inheritable node ids must be unique."
        val separate = column("root", field, field.copy(nodeId = "other name"))
        separate.validateInheritableNodes(separate.inferInheritableNodes()) { true }
    }

    test("a field node shared between a part and a local scope is admitted") {
        val field = fieldNode("name")
        val sharedLocal =
            column(
                "root",
                partNode("details", field),
                PresentationNode.partial(
                    nodeId = "local",
                    element =
                        PresentationElement.createScopedBinding(
                            binding = fieldControl("details").binding,
                            scopeBinding = declared("local scope"),
                            child = field,
                        ),
                ),
            )
        sharedLocal.validateInheritableNodes(sharedLocal.inferInheritableNodes()) { true }
    }

    test("an inherited field node must target an existing owner field") {
        val field = fieldNode("name")
        field.validateInheritableNodes(field.inferInheritableNodes()) { it == "name" }
        rejectionOf { field.validateInheritableNodes(field.inferInheritableNodes()) { false } } shouldBe
            "Inheritable node name must target an existing direct owner field."
    }

    test("references that differ from the inferred layout are refused") {
        val field = fieldNode("name")
        rejectionOf { field.validateInheritableNodes(listOf("other")) { true } } shouldBe
            "Inheritable nodes must match the inferred canonical layout."
    }
}
