package com.typewritermc.types.catalog

import com.typewritermc.authoring.of
import com.typewritermc.types.TEXT
import com.typewritermc.types.catalog
import com.typewritermc.types.closedCases
import com.typewritermc.types.id
import com.typewritermc.types.listDefinition
import com.typewritermc.types.member
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.template
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.type_catalog.ArgumentLocation
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

private val BOARD = ResourceId(value = "board")

/** The type `V` [BOARD] derives. */
private val DERIVED_V = TypeDefinitionId.derived(BOARD, "V")

val DerivedTypesTest by testSuite {
    test("a derived parameter's argument is the type its resource derives") {
        val board = boardDefinition()
        val catalog = catalog(board).withContent(derives(DerivedTarget.Declared(derivedRecord("gold" to TEXT))))

        val type = (catalog.typeOf(BOARD, TypeSelection.of(board.id)) as Resolution.Ready).value

        (type as ResourceType.Complete).checked.use shouldBe board.id.use(listOf(DERIVED_V.use()))
        catalog.fieldsOf(DERIVED_V.use()) shouldContainExactly listOf("gold")
    }

    test("the authored type leaves a derived parameter open, so what a resource derives never changes which definition it is") {
        val board = boardDefinition()
        val catalog = catalog(board).withContent(derives(DerivedTarget.Declared(derivedRecord("gold" to TEXT))))

        val type = (catalog.authoredTypeOf(TypeSelection.of(board.id)) as Resolution.Ready).value

        (type as ResourceType.Partial).schema.pendingArguments shouldContainExactly listOf(ArgumentLocation(index = 0))
        type.knownFields.map { it.key } shouldContainExactly listOf("name")
    }

    test("editing what a resource derives changes the type behind the same id") {
        val board = boardDefinition()
        val before = catalog(board).withContent(derives(DerivedTarget.Declared(derivedRecord("gold" to TEXT))))
        val after = catalog(board).withContent(derives(DerivedTarget.Declared(derivedRecord("gold" to TEXT, "silver" to TEXT))))
        val selection = TypeSelection.of(board.id)

        before.completeTypeOf(BOARD, selection)?.use shouldBe after.completeTypeOf(BOARD, selection)?.use
        before.fieldsOf(DERIVED_V.use()) shouldContainExactly listOf("gold")
        after.fieldsOf(DERIVED_V.use()) shouldContainExactly listOf("gold", "silver")
    }

    test("a derived alias means the type it names") {
        val board = boardDefinition()
        val catalog = catalog(board).withContent(derives(DerivedTarget.Plain(TEXT)))

        catalog.definition(DERIVED_V) shouldBe DeclarationStatus.READY
        catalog.completeTypeOf(BOARD, TypeSelection.of(board.id))?.use shouldBe board.id.use(listOf(TEXT))
    }

    test("a derived union's cases are members of the derived id") {
        val red = DERIVED_V.member("Red")
        val union =
            TypeDefinition.partial(
                id = DERIVED_V,
                representation =
                    RepresentationTemplate.createRecord(
                        fields = emptyList(),
                        form = RecordForm.createClosed(cases = listOf(red.namedTemplate())),
                    ),
            )
        val case =
            TypeDefinition.partial(
                id = red,
                parents = listOf(DERIVED_V.namedTemplate()),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
            )
        val catalog = catalog(boardDefinition()).withContent(derives(DerivedTarget.Declared(union, listOf(case))))

        catalog.definition(red) shouldBe DeclarationStatus.READY
        catalog.isNominalSubtype(red, DERIVED_V) shouldBe true
        (catalog.declaration(DERIVED_V) as Resolution.Ready).value.representation.closedCases()?.map { it.definition } shouldBe listOf(red)
    }

    test("a resource that derives nothing for a derived parameter has a missing derived type") {
        val board = boardDefinition()
        val catalog = catalog(board).withContent(derives(DerivedTarget.Missing(DerivedFailure.NoBlock)))
        val record = AuthoringRecord.partial(configuration = TypeSelection.of(board.id))

        catalog.unavailableCode(DERIVED_V) shouldBe "derived_type_missing"
        record.missingContent(BOARD, catalog).map { it.problem.code to it.type } shouldContain ("derived_type_missing" to DERIVED_V)
    }

    val origin = RuleOrigin(owner = id("board"), ordinal = 0)
    listOf(
        DerivedFailure.Conflict(listOf(origin, origin.copy(ordinal = 1))) to "derived_type_conflict",
        DerivedFailure.Loop(listOf(BOARD)) to "derived_type_loop",
        DerivedFailure.Failed(origin, "boom") to "derived_type_failed",
    ).forEach { (failure, code) ->
        test("a derived type that fails as ${failure::class.simpleName} reports $code") {
            val catalog = catalog(boardDefinition()).withContent(derives(DerivedTarget.Missing(failure)))

            catalog.unavailableCode(DERIVED_V) shouldBe code
        }
    }

    test("a derived declaration obeys the structural rules but not the creator rules") {
        val defaulted =
            derivedRecord("gold" to TEXT).let { record ->
                val shape = (record.representation as RepresentationTemplate.RecordWrapper).value
                record.copy(
                    representation =
                        RepresentationTemplate.createRecord(
                            fields = shape.fields.map { it.copy(hasConstructorDefault = true) },
                            form = shape.form,
                        ),
                )
            }
        val duplicated = derivedRecord("gold" to TEXT, "gold" to TEXT)

        catalog(boardDefinition()).withContent(derives(DerivedTarget.Declared(defaulted))).definition(DERIVED_V) shouldBe
            DeclarationStatus.READY
        catalog(boardDefinition()).withContent(derives(DerivedTarget.Declared(duplicated))).unavailableCode(DERIVED_V) shouldBe
            "duplicate_field"
    }

    test("a derived alias that contains itself is an alias loop") {
        val list = listDefinition()
        val catalog = catalog(boardDefinition(), list).withContent(derives(DerivedTarget.Plain(list.id.use(listOf(DERIVED_V.use())))))

        catalog.unavailableCode(DERIVED_V) shouldBe "content_alias_loop"
    }

    test("a stored choice for a derived parameter is refused") {
        val board = boardDefinition()
        val catalog = catalog(board).withContent(derives(DerivedTarget.Declared(derivedRecord("gold" to TEXT))))
        val chosen = TypeSelection.of(board.id, mapOf(0 to TEXT))

        (catalog.typeOf(BOARD, chosen) as Resolution.Invalid).diagnostics.map { it.code } shouldBe listOf("derived_argument_chosen")
        (catalog.authoredTypeOf(chosen) as Resolution.Invalid).diagnostics.map { it.code } shouldBe listOf("derived_argument_chosen")
    }

    test("a written declaration may not take a derived key") {
        val written = derivedRecord("gold" to TEXT)

        listOf(written).declarationProblems(BOARD)[DERIVED_V].orEmpty() shouldContain "declaration_key"
        AuthoringRecord.partial(types = listOf(written)).misfiledDeclarations(BOARD).map { it.code } shouldContain "declaration_key"
    }
}

/** A board whose `value` field holds its derived parameter `V`, next to a plain `name`. */
private fun boardDefinition(): TypeDefinition {
    val id = id("board")
    val parameter = ParameterKey(owner = id, index = 0)
    return TypeDefinition.partial(
        id = id,
        parameters = listOf(TypeParameter(key = parameter, name = "V", bounds = emptyList(), derived = true)),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "name"), type = TEXT.toTemplate()),
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = "value"), type = parameter.template),
                    ),
                form = RecordForm.CONCRETE,
            ),
    )
}

/** The record [BOARD] derives as `V`, with one field per pair. */
private fun derivedRecord(vararg fields: Pair<String, TypeUse>): TypeDefinition =
    TypeDefinition.partial(
        id = DERIVED_V,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    fields.map { (name, type) ->
                        FieldDeclaration.partial(owner = FieldOwner(definition = DERIVED_V, name = name), type = type.toTemplate())
                    },
                form = RecordForm.CONCRETE,
            ),
    )

/** Content in which [BOARD] derives [target] as `V` and declares nothing written. */
private fun derives(target: DerivedTarget): ContentTypes =
    object : ContentTypes {
        override fun written(owner: ResourceId): List<TypeDefinition> = emptyList()

        override fun heldType(
            owner: ResourceId,
            field: String,
        ): TypeUse? = null

        override fun derived(
            owner: ResourceId,
            key: String,
        ): DerivedTarget = if (owner == BOARD && key == "V") target else DerivedTarget.Missing(DerivedFailure.NoBlock)
    }

private fun CheckedCatalog.fieldsOf(use: TypeUse): List<String> =
    (resolve(use) as Resolution.Ready).value.schema.fields.map { it.key }
