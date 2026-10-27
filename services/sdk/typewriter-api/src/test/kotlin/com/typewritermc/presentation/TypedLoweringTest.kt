@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.Availability
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
import com.typewritermc.testkit.elementsOf
import com.typewritermc.testkit.ready
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.floatScalar
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.presentation.ChoicePresentation
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
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

val TypedLoweringTest by testSuite {
    test("a generic material that holds for every argument builds once against the open type") {
        val assembly = weightedAssembly { scope -> weighted(scope) { weight -> weight { numericInput() } } }

        assembly.editorCatalog.presentationMaterials.map { it.target } shouldBe
            listOf(PresentationTarget.NamedWrapper(WEIGHTED.namedTemplate(listOf(WEIGHTED_VALUE.template))))
        assembly.editorCatalog.presentationMaterials
            .single()
            .layout
            .elementsOf<PresentationElement.NumericInputWrapper>()
            .size shouldBe 1
        assembly.editorCatalog.diagnostics shouldBe emptyList()
        assembly.callbackFailures shouldBe emptyList()
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

    val tags = input<List<String>>(CONFIGURED_VALUE).field<List<String>>("tags").orElse(com.typewritermc.expression.emptyListExpression())

    test("a repeated element binds each item with the list's item type") {
        val layout = build { scope -> scope.repeated<String, String>(tags) { text(item.orElse(literal(""))) } }

        layout.layout
            .elementsOf<PresentationElement.RepeatedWrapper>()
            .single()
            .value.itemBinding.type shouldBe ScalarKind.TEXT.template
    }

    test("a scoped alias binds the type of the field it names") {
        val layout =
            build { scope ->
                with(scope) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    scoped(title.input) { textInput() }
                }
            }

        layout.layout
            .elementsOf<PresentationElement.ScopedBindingWrapper>()
            .single()
            .value.scopeBinding.type shouldBe
            ScalarKind.TEXT.template
    }

    test("a collection lookup binds its rows with the row type of its source") {
        val rows = collectionSource<String, String>("tags", ScalarKind.TEXT.template) { key(row) }
        val layout =
            build { scope ->
                with(scope) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    collectionLookup(rows, title.input) {
                        found { text(row.orElse(literal(""))) }
                        missing { text(literal("missing")) }
                    }
                }
            }

        layout.dependencies.collections
            .single()
            .rowBinding.type shouldBe ScalarKind.TEXT.template
    }

    test("a search input binds its query, summary, results and selector values with their types") {
        val layout =
            build { scope ->
                with(scope) {
                    val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                    title {
                        searchInput<String> {
                            selectors { selector("tag", "tag") }
                            provider(sources.staticValues(tags))
                            result {
                                key(row)
                                selectedValue(row)
                                presentation { text(row) }
                            }
                        }
                    }
                }
            }
        val search =
            layout.layout
                .elementsOf<PresentationElement.SearchInputWrapper>()
                .single()
                .value
        val provider = search.provider.shouldBeInstanceOf<skirout.editor.v1.presentation.SearchProvider.StaticValuesWrapper>().value

        listOf(
            search.queryBinding.type,
            search.summaryBinding.type,
            provider.result.binding.type,
            provider.selectors
                .single()
                .valueBinding.type,
        ) shouldBe
            List(4) { ScalarKind.TEXT.template }
    }

    test("a dropdown turns the typed query into the custom value it stores") {
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
                .elementsOf<PresentationElement.SelectInputWrapper>()
                .single()
                .value
        val options = select.optionsConfig.shouldNotBeNull()
        val query = options.queryBinding.shouldNotBeNull()

        select.allowCustomValue shouldBe true
        options.presentation shouldBe ChoicePresentation.DROPDOWN
        query.type shouldBe ScalarKind.TEXT.template
        com.typewritermc.expression.evaluate(
            options.customValue.shouldNotBeNull(),
            query.id.value to DataValue.StringValueWrapper("typed"),
        ) shouldBe
            Availability.Available(DataValue.StringValueWrapper("typed"))
    }

    mapOf<String, Pair<() -> Any, String>>(
        "a negative spacing" to ({ Spacing(-1.0) } to "Spacing must be finite and nonnegative."),
        "a spacing that is not a number" to ({ Spacing(Double.NaN) } to "Spacing must be finite and nonnegative."),
        "an infinite spacing" to ({ Spacing(Double.POSITIVE_INFINITY) } to "Spacing must be finite and nonnegative."),
        "a font weight of zero" to ({ FontWeight(0) } to "Font weight must be between 1 and 1000."),
        "a font weight above 1000" to ({ FontWeight(1001) } to "Font weight must be between 1 and 1000."),
        "a negative display delay" to ({ DisplayDelay(-1) } to "Display delays must be nonnegative."),
    ).forEach { (case, rejection) ->
        test("$case cannot be constructed") {
            shouldThrow<IllegalArgumentException> { rejection.first() }.message shouldBe rejection.second
        }
    }

    test("a slot rejects an expression of another type") {
        shouldThrow<IllegalArgumentException> {
            build { scope -> scope.text(literal(true).uncheckedText()) }
        }.message shouldContain "incompatible_expression_result_type"
    }
}
