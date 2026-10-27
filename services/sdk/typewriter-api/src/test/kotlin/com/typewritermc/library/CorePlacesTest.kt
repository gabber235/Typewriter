@file:OptIn(com.typewritermc.authoring.GeneratedSdkApi::class)

package com.typewritermc.library

import com.typewritermc.authoring.HierarchyGroupDefinition
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.discovery.CatalogAssembly
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.assemble
import com.typewritermc.expression.Handled
import com.typewritermc.expression.inputExpression
import com.typewritermc.expression.listExpr
import com.typewritermc.expression.literal
import com.typewritermc.expression.name
import com.typewritermc.expression.orElse
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.allNodes
import com.typewritermc.presentation.createResource
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.presentation.resource
import com.typewritermc.testkit.actions
import com.typewritermc.testkit.appearanceReads
import com.typewritermc.testkit.ready
import com.typewritermc.testkit.resourcesElement
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.fields
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationMaterial
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.presentation.GraphDirection
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationNumber
import skirout.editor.v1.presentation.ResourcesElement
import skirout.editor.v1.presentation.ResourcesLayout
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.catalog.PresentationTarget as WirePresentationTarget

val CorePlacesTest by testSuite {
    val assembly = frameworkContributions().assemble(CatalogAssemblyContext(CatalogGeneration(value = "core places")))

    test("the core catalog publishes its realm root and keeps every core resource type owned") {
        assembly.editorCatalog.realmRoot shouldBe RealmRootDefinition.id
        assembly.editorCatalog.diagnostics.filter { it.code in setOf("unowned_resource_type", "generic_realm_section") } shouldBe
            emptyList()
        listOf(RealmRootDefinition.id, LibraryDefinition.id, TaxonomyDefinition.id, BookDefinition.id, TagDefinition.id).forEach {
            assembly.checked.definition(it) shouldBe DeclarationStatus.READY
        }
    }

    test("the realm navigator lists the sections of the root without letting anyone unlink them") {
        val layout = assembly.material(RealmRootDefinition.id, PresentationRole.NAVIGATOR).layout
        val node = layout.allNodes().single { it.element is PresentationElement.ResourcesWrapper }
        node.resourcesElement().layout shouldBe ResourcesLayout.LIST
        node.properties.readOnly shouldBe true
    }

    test("the library workspace shows every book as a card") {
        val books = assembly.material(LibraryDefinition.id, PresentationRole.WORKSPACE).layout.resourcesElement()

        books.control.binding.path.segments shouldBe listOf(PathSegment.createField(name = "books"))
        books.layout.shouldBeInstanceOf<ResourcesLayout.GridWrapper>()
        assembly
            .material(BookDefinition.id, PresentationRole.ITEM)
            .layout
            .allNodes()
            .flatMap { it.appearanceReads() }
            .toSet() shouldBe
            setOf("label", "accent", "icon")
    }

    test("deleting either end of an unannotated link clears it, while an annotated owner cascades to its pages") {
        fun deletePolicies(id: skirout.editor.v1.type_catalog.RelationId) =
            assembly.relations.single { it.id == id }.let { listOf(it.first.onDelete, it.second.onDelete) }

        deletePolicies(BookTags.contract.id) shouldBe listOf(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR)
        deletePolicies(TagParents.contract.id) shouldBe listOf(RelationDeletePolicy.CLEAR, RelationDeletePolicy.CLEAR)
        deletePolicies(BookPages.contract.id) shouldBe listOf(RelationDeletePolicy.CASCADE, RelationDeletePolicy.CLEAR)
    }

    test("an element name must be present and on one line") {
        val rules =
            assembly.configuration
                .filter { it.origin.owner == com.typewritermc.elements.ElementDefinition.id }
                .flatMap { it.rules }
                .map { it.descriptor.predicate }

        fun accepted(name: String) =
            rules.all {
                com.typewritermc.expression.evaluate(it, "configured_value" to DataValue.StringValueWrapper(name)) ==
                    com.typewritermc.authoring.Availability
                        .Available(DataValue.BooleanWrapper(true))
            }

        listOf("Intro", "", "first\nsecond").map(::accepted) shouldBe listOf(true, false, false)
    }

    test("the taxonomy workspace places tags on a graph from top to bottom and renders them as items") {
        val graph =
            assembly
                .resources(
                    TaxonomyDefinition.id,
                    PresentationRole.WORKSPACE,
                ).layout
                .shouldBeInstanceOf<ResourcesLayout.GraphWrapper>()
        graph.value.direction shouldBe GraphDirection.TOP_TO_BOTTOM
        assembly
            .material(TagDefinition.id, PresentationRole.ITEM)
            .layout
            .allNodes()
            .flatMap { it.appearanceReads() }
            .toSet() shouldBe
            setOf("label", "icon")
    }

    test("a book stands in the library as a stacked card built from its appearance") {
        val material = assembly.material(BookDefinition.id, PresentationRole.ITEM)
        val nodes = material.layout.allNodes()
        val transforms = nodes.mapNotNull { (it.element as? PresentationElement.TransformWrapper)?.value }

        nodes.flatMap { it.appearanceReads() }.toSet() shouldBe setOf("label", "accent", "icon")
        transforms
            .first()
            .scale
            .shouldBeInstanceOf<PresentationNumber.StatesWrapper>()
            .value.rules
            .single()
            .match.required shouldBe listOf(PresentationInteractionState.HOVERED)
        transforms
            .single { it.rotateY != null }
            .transition
            ?.rules
            ?.single()
            ?.match
            ?.required shouldBe listOf(PresentationInteractionState.SELECTED)
    }

    test("the book outline groups pages by chapter and creates a page into the book from each group") {
        val material = assembly.material(BookDefinition.id, PresentationRole.NAVIGATOR)
        val resources = material.layout.resourcesElement()
        resources.control.binding.path.segments shouldBe listOf(PathSegment.createField(name = "pages"))
        (resources.order != null) shouldBe true
        val tree = resources.layout.shouldBeInstanceOf<ResourcesLayout.TreeWrapper>().value
        tree.path.segments shouldBe listOf(PathSegment.createField(name = "chapter"))
        material.dependencies.types shouldContain HierarchyGroupDefinition.id.use()

        val create =
            requireNotNull(tree.group)
                .actions()
                .single()
                .shouldBeInstanceOf<EditorAction.CreateWrapper>()
                .value
        create.type shouldBe PageDefinition.id
        requireNotNull(create.owner).path.segments shouldBe listOf(PathSegment.createField(name = "pages"))
        create.fields
            .single()
            .path.segments shouldBe listOf(PathSegment.createField(name = "chapter"))
    }

    test("a resources order reads each member's link and only layouts that list members accept one") {
        val build = assembly.bookPresentation()

        build {
            pages {
                order { resource.fields.name.orElse(literal("")) }
                list()
            }
        }
        shouldThrow<IllegalArgumentException> {
            build {
                pages {
                    order { inputExpression<String, Handled>(ExpressionBindingId(value = "unbound")) }
                    list()
                }
            }
        }.message shouldContain "Invalid resources order"
        shouldThrow<IllegalArgumentException> {
            build {
                pages {
                    order { listExpr(resource.fields.name.orElse(literal(""))) }
                    list()
                }
            }
        }.message shouldContain "not of an ordered type"
        shouldThrow<IllegalArgumentException> {
            build {
                pages {
                    order { resource.fields.name.orElse(literal("")) }
                    graph(GraphDirection.TOP_TO_BOTTOM)
                }
            }
        }.message shouldContain "cannot declare an order"
    }

    test("a create action must join an owning link field of the subject that accepts the created type") {
        val build = assembly.bookBuild()

        build { createResource(type = PageDefinition.id, owner = BookFields.pages) { PageFields.name(literal("Intro")) } }
        shouldThrow<IllegalArgumentException> { build { createResource(type = TagDefinition.id, owner = BookFields.tags) } }
            .message shouldContain "ownership relation"
        shouldThrow<IllegalArgumentException> { build { createResource(type = TagDefinition.id, owner = BookFields.pages) } }
            .message shouldContain "does not accept"
        shouldThrow<IllegalArgumentException> { build { createResource(type = PageDefinition.id, owner = PageFields.elements) } }
            .message shouldContain "link field of the presentation subject"
    }

    test("create action presets must be fields of the created type with matching values") {
        val build = assembly.bookBuild()

        shouldThrow<IllegalArgumentException> {
            build { createResource(type = TagDefinition.id, owner = null) { PageFields.priority(literal(1)) } }
        }.message shouldContain "is not a field of"
    }

    test("a create action preset whose value does not match its field is refused") {
        val build = assembly.bookBuild()

        @Suppress("UNCHECKED_CAST")
        val wrongPriority = literal("high") as com.typewritermc.expression.Expr<Int, Handled>
        shouldThrow<IllegalArgumentException> {
            build { createResource(type = PageDefinition.id, owner = BookFields.pages) { PageFields.priority(wrongPriority) } }
        }.message shouldBe "Invalid [4,[5,[3]]] expression: incompatible_expression_result_type."
    }
}
