@file:OptIn(com.typewritermc.authoring.GeneratedSdkApi::class)

package com.typewritermc.library

import com.typewritermc.authoring.HierarchyGroupDefinition
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.CatalogAssembly
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.assemble
import com.typewritermc.expression.literal
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationMaterial
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.createResource
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.GraphDirection
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.ResourcesElement
import skirout.editor.v1.presentation.ResourcesLayout
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.PathSegment

val CorePlacesTest by testSuite {
    val assembly = frameworkContributions().assemble(CatalogAssemblyContext(CatalogGeneration("core places")))

    test("the core catalog publishes its realm root and keeps every core resource type owned") {
        assembly.snapshot.realmRoot shouldBe RealmRootDefinition.id
        assembly.snapshot.diagnostics.filter { it.code in setOf("unowned_resource_type", "generic_realm_section") } shouldBe emptyList()
        listOf(RealmRootDefinition.id, LibraryDefinition.id, TaxonomyDefinition.id, BookDefinition.id, TagDefinition.id).forEach {
            assembly.checked.definition(it) shouldBe DeclarationStatus.Ready
        }
    }

    test("the realm navigator lists the sections of the root without letting anyone unlink them") {
        val layout = assembly.material(RealmRootDefinition.id, PresentationRole.NAVIGATOR).layout
        val node = layout.nodes().single { it.element is PresentationElement.ResourcesWrapper }
        node.resourcesElement().layout shouldBe ResourcesLayout.LIST
        node.properties.readOnly shouldBe true
    }

    test("the library workspace shows every book as a card") {
        val grid =
            assembly
                .resources(
                    LibraryDefinition.id,
                    PresentationRole.WORKSPACE,
                ).layout
                .shouldBeInstanceOf<ResourcesLayout.GridWrapper>()
        listOf(grid.value.itemExtent, grid.value.aspectRatio, grid.value.spacing).map { it.literal() } shouldBe listOf(240.0, 0.72, 16.0)
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
        assembly.material(TagDefinition.id, PresentationRole.ITEM).provider.name shouldContain "TagGraphNodePresentation"
    }

    test("the book outline groups pages by chapter and creates a page into the book from each group") {
        val material = assembly.material(BookDefinition.id, PresentationRole.NAVIGATOR)
        val resources = material.layout.resourcesElement()
        resources.control.binding.path.segments shouldBe listOf(PathSegment.createField(name = "pages"))
        (resources.order != null) shouldBe true
        val tree = resources.layout.shouldBeInstanceOf<ResourcesLayout.TreeWrapper>().value
        tree.path.segments shouldBe listOf(PathSegment.createField(name = "chapter"))
        material.dependencies.types shouldContain SkirTypeCodec.encode(TypeUse.Named(HierarchyGroupDefinition.id)).getOrThrow()

        val create =
            requireNotNull(tree.group)
                .actions()
                .single()
                .shouldBeInstanceOf<EditorAction.CreateWrapper>()
                .value
        create.type shouldBe SkirTypeCodec.encode(PageDefinition.id).getOrThrow()
        requireNotNull(create.owner).path.segments shouldBe listOf(PathSegment.createField(name = "pages"))
        create.fields
            .single()
            .path.segments shouldBe listOf(PathSegment.createField(name = "chapter"))
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
}

/** Builds a Book workspace whose only content is a button running the action [action] creates. */
private fun CatalogAssembly.bookBuild(): (() -> EditorAction) -> Unit {
    val checked = (checked.resolve(BookDefinition.use) as Resolution.Ready).value
    val ownership =
        snapshot.relations
            .filter { relation -> relation.families.any { it.value == RESOURCE_OWNERSHIP_FAMILY_ID } }
            .mapTo(hashSetOf()) { it.first.id }
    val binding = PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE, ownershipEndpoints = ownership)
    return { action -> DefaultPresentationRuntime().build(binding) { scope -> scope.button(literal("Create"), action()) } }
}

private fun CatalogAssembly.material(
    type: TypeDefinitionId,
    role: PresentationRole,
): PresentationMaterial =
    snapshot.presentationMaterials.single {
        it.role == role && (it.target as? PresentationTarget.Named)?.type?.definition == type
    }

private fun CatalogAssembly.resources(
    type: TypeDefinitionId,
    role: PresentationRole,
): ResourcesElement = material(type, role).layout.resourcesElement()

private fun PresentationNode.resourcesElement(): ResourcesElement =
    nodes().firstNotNullOf { (it.element as? PresentationElement.ResourcesWrapper)?.value }

private fun PresentationNode.actions(): List<EditorAction> =
    nodes().mapNotNull { (it.element as? PresentationElement.ButtonWrapper)?.value?.action }

/** This node and every node beneath it, depth first. */
private fun PresentationNode.nodes(): List<PresentationNode> =
    listOf(this) +
        when (val element = element) {
            is PresentationElement.ChildrenWrapper -> element.value.childNodes()
            else -> emptyList()
        }.flatMap { it.nodes() }

private fun skirout.editor.v1.presentation.ChildrenElement.childNodes(): List<PresentationNode> =
    when (this) {
        is skirout.editor.v1.presentation.ChildrenElement.ColumnWrapper -> value.children.map { it.node() }
        is skirout.editor.v1.presentation.ChildrenElement.RowWrapper -> value.children.map { it.node() }
        else -> emptyList()
    }

private fun skirout.editor.v1.presentation.AxisChild.node(): PresentationNode =
    when (this) {
        is skirout.editor.v1.presentation.AxisChild.FixedWrapper -> value
        is skirout.editor.v1.presentation.AxisChild.FlexibleWrapper -> value.child
        else -> error("Unknown axis child")
    }

private fun ExpressionNode.literal(): Double = ((this as ExpressionNode.LiteralWrapper).value as DataValue.FloatWrapper).value
