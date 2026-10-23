@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.discovery.contributionKey
import com.typewritermc.expression.Handled
import com.typewritermc.expression.field
import com.typewritermc.expression.input
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.floatScalar
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.presentation.ChoicePresentation
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate

val TypedLoweringTest by testSuite {
    test("a generic material that holds for every argument builds once for all of them") {
        val assembly = weightedAssembly { scope -> weighted(scope) { weight -> weight { numericInput() } } }

        assembly.editorCatalog.presentationMaterials.size shouldBe 1
        assembly.editorCatalog.diagnostics.map { it.code } shouldBe emptyList()
    }

    test("a generic material that puts a number control on a bare parameter is dropped and reported") {
        val assembly = weightedAssembly { scope -> weighted(scope) { _ -> value { numericInput() } } }

        assembly.editorCatalog.presentationMaterials shouldBe emptyList()
        assembly.editorCatalog.diagnostics.map { it.affected to it.code } shouldBe
            listOf(WEIGHTED to "presentation_material_build_failed")
        assembly.editorCatalog.types
            .single { it.definition.id == WEIGHTED }
            .status shouldBe DeclarationStatus.READY
        assembly.callbackFailures
            .single()
            .cause.message shouldContain "numeric input needs a number"
    }

    test("an expression that holds only for some arguments fails the generic material") {
        val assembly =
            weightedAssembly { scope ->
                scope.text(input<String>(CONFIGURED_VALUE).field<String>("value").orElse(literal("none")))
            }

        assembly.editorCatalog.presentationMaterials shouldBe emptyList()
        assembly.callbackFailures
            .single()
            .cause.message shouldContain "incompatible_expression_types"
    }

    test("repeated items, aliases, rows and search bindings carry their types to the wire") {
        val text = ScalarKind.TEXT.template
        val rows =
            collectionSource<String, String>("tags", text) {
                key(row)
            }
        val layout =
            build { scope ->
                with(scope) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    repeated<String, String>(
                        input<List<String>>(
                            CONFIGURED_VALUE,
                        ).field<List<String>>("tags").orElse(com.typewritermc.expression.emptyListExpression()),
                    ) {
                        text(item.orElse(literal("")))
                    }
                    scoped(title.input) { textInput() }
                    collectionLookup(rows, title.input) {
                        found { text(row.orElse(literal(""))) }
                        missing { text(literal("missing")) }
                    }
                    title {
                        searchInput<String> {
                            selectors { selector("tag", "tag") }
                            provider(
                                sources.staticValues(
                                    input<List<String>>(
                                        CONFIGURED_VALUE,
                                    ).field<List<String>>("tags").orElse(com.typewritermc.expression.emptyListExpression()),
                                ),
                            )
                            result {
                                key(row)
                                selectedValue(row)
                                presentation { text(row) }
                            }
                        }
                    }
                }
            }

        val elements = layout.layout.fixedChildren().map(PresentationNode::element)
        elements[0]
            .shouldBeInstanceOf<PresentationElement.RepeatedWrapper>()
            .value.itemBinding.type shouldBe text
        elements[1]
            .shouldBeInstanceOf<PresentationElement.ScopedBindingWrapper>()
            .value.scopeBinding.type shouldBe text
        layout.dependencies.collections
            .single()
            .rowBinding.type shouldBe text
        val search = elements[3].shouldBeInstanceOf<PresentationElement.SearchInputWrapper>().value
        search.queryBinding.type shouldBe text
        search.summaryBinding.type shouldBe text
        val provider = search.provider.shouldBeInstanceOf<skirout.editor.v1.presentation.SearchProvider.StaticValuesWrapper>().value
        provider.result.binding.type shouldBe text
        provider.selectors
            .single()
            .valueBinding.type shouldBe text
    }

    test("a dropdown accepts a custom value parsed from its typed query") {
        val layout =
            build { scope ->
                with(scope) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    title {
                        selectInput(listOf(SelectOption("one", literal("One"), literal("one")))) {
                            dropdown { customValue { this } }
                        }
                    }
                }
            }

        val select =
            layout.layout
                .singleFixed()
                .element
                .shouldBeInstanceOf<PresentationElement.SelectInputWrapper>()
                .value
        select.allowCustomValue shouldBe true
        select.optionsConfig?.presentation shouldBe ChoicePresentation.DROPDOWN
        select.optionsConfig?.queryBinding?.type shouldBe ScalarKind.TEXT.template
    }

    test("invalid layout values cannot be constructed") {
        shouldThrow<IllegalArgumentException> { Spacing(-1.0) }
        shouldThrow<IllegalArgumentException> { Spacing(Double.NaN) }
        shouldThrow<IllegalArgumentException> { Spacing(Double.POSITIVE_INFINITY) }
        shouldThrow<IllegalArgumentException> { FontWeight(0) }
        shouldThrow<IllegalArgumentException> { FontWeight(1001) }
        shouldThrow<IllegalArgumentException> { DisplayDelay(-1) }
        Spacing.NONE.pixels shouldBe 0.0
        FontWeight(700).value shouldBe 700
    }

    test("a slot rejects an expression of another type") {
        shouldThrow<IllegalArgumentException> {
            build { scope -> scope.text(literal(true).uncheckedText()) }
        }.message shouldContain "incompatible_expression_result_type"
    }
}

private val WEIGHTED = TypeDefinitionId.qualified("test", "Weighted")
private val WEIGHTED_VALUE = ParameterKey(owner = WEIGHTED, index = 0)
private val SUBJECT = TypeDefinitionId.qualified("test", "LoweringSubject")

/** Presents the weight and value fields of a Weighted<T>, configuring them through [configure]. */
private fun weighted(
    scope: PresentationBuildScope,
    configure: WeightedFields.(PresentedField<Double, NumberControl<Double>>) -> Unit,
) {
    @Suppress("UNCHECKED_CAST")
    val weight = scope.field<Double, NumberControl<*>>("weight", NumberControl::class) as PresentedField<Double, NumberControl<Double>>

    @Suppress("UNCHECKED_CAST")
    val value = scope.field<Any?, NumberControl<*>>("value", NumberControl::class) as PresentedField<Any?, NumberControl<Any?>>
    WeightedFields(value).configure(weight)
}

private class WeightedFields(
    val value: PresentedField<Any?, NumberControl<Any?>>,
)

/** A text expression the DSL would not accept, to show that lowering checks the slot type itself. */
@Suppress("UNCHECKED_CAST")
private fun com.typewritermc.expression.Expr<Boolean, Handled>.uncheckedText(): com.typewritermc.expression.Expr<String, Handled> =
    this as com.typewritermc.expression.Expr<String, Handled>

private fun weightedAssembly(present: (PresentationBuildScope) -> Unit) =
    CatalogContributions(
        declarations = listOf(OwnedTypeDeclaration(ORIGIN, weightedDefinition())),
        presentations =
            listOf(
                OwnedPresentation(
                    ORIGIN,
                    PresentationDescriptor.of(
                        id = PresentationId(namespace = "test", name = "weighted"),
                        owner = ORIGIN.owner,
                        target = PresentationTarget.NamedWrapper(WEIGHTED.namedTemplate(listOf(WEIGHTED_VALUE.template))),
                        roles = setOf(PresentationRole.INSPECTOR),
                        priority = 0,
                    ),
                    object : PresentationProvider {
                        override fun build(binding: PresentationBuildBinding) = DefaultPresentationRuntime().build(binding, present)
                    },
                ),
            ),
    ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "weighted")))

private fun weightedDefinition(): TypeDefinition =
    TypeDefinition(
        id = WEIGHTED,
        parameters = listOf(TypeParameter(key = WEIGHTED_VALUE, name = "T", bounds = emptyList())),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = WEIGHTED, name = "value"), type = WEIGHTED_VALUE.template),
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = WEIGHTED, name = "weight"),
                            type = floatScalar(FloatWidth.SIXTY_FOUR).template,
                        ),
                    ),
                abstract_ = false,
            ),
        parents = emptyList(),
    )

/** Builds [content] for a record with a text title and a list of text tags. */
private fun build(content: (PresentationBuildScope) -> Unit): PresentationBuildResult {
    val subject =
        TypeDefinition.partial(
            id = SUBJECT,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = SUBJECT, name = "title"),
                                type = ScalarKind.TEXT.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = SUBJECT, name = "tags"),
                                type = StandardTypes.list.template(listOf(ScalarKind.TEXT.template)),
                            ),
                        ),
                    abstract_ = false,
                ),
        )
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "lowering"), StandardTypes.definitions + subject)
    val checked = (catalog.resolve(SUBJECT.use()) as Resolution.Ready).value
    return DefaultPresentationRuntime().build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE), content)
}

private val ORIGIN: ProviderOrigin =
    ProviderOrigin(
        DeclarationOwner(
            source = contributionKey(ContributionSourceId("test"), "main", ProducerId("sdk"), ContributionName("lowering")),
            localIdentity = "lowering",
        ),
        ArtifactId("test:sdk"),
        "main",
    )

private fun PresentationNode.fixedChildren(): List<PresentationNode> =
    (element as PresentationElement.ChildrenWrapper)
        .value
        .let { it as skirout.editor.v1.presentation.ChildrenElement.ColumnWrapper }
        .value.children
        .map { (it as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value }

private fun PresentationNode.singleFixed(): PresentationNode =
    if (element is PresentationElement.ChildrenWrapper) fixedChildren().single() else this
