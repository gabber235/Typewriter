package com.typewritermc.discovery

import com.typewritermc.authoring.DraftBinding
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.formula.DynamicProvider
import com.typewritermc.formula.Dynamics
import com.typewritermc.testkit.origin
import com.typewritermc.types.catalog.BindKey
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.qualified
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

private val BOARD = TypeDefinitionId.qualified("bind", "Board")
private val NOTE = TypeDefinitionId.qualified("bind", "Note")
private val BOARD_ARTIFACT = origin("board types", artifact = "test:board")
private val OTHER_ARTIFACT = origin("other types", artifact = "test:other")

val BindRegistrationTest by testSuite {
    test("a registered bind makes its parameter computed in the catalog editors and engines read") {
        val assembly = assembleBoard(binder(BOARD_ARTIFACT) { bind(BindKey(BOARD, "V"), draftOf(BOARD)) {} })

        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to true)
        assembly.publishedParameters() shouldBe listOf("T" to false, "V" to true)
        assembly.dynamics.failures shouldBe emptyList()
    }

    test("a bind on a type another artifact declares is rejected at load and leaves the parameter chosen") {
        val assembly = assembleBoard(binder(OTHER_ARTIFACT) { bind(BindKey(BOARD, "V"), draftOf(BOARD)) {} })

        assembly.dynamics.failures.map { it.code } shouldBe listOf("bind_foreign_type")
        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to false)
    }

    test("a bind whose draft type reads another type than its key names is rejected at load") {
        val assembly = assembleBoard(binder(BOARD_ARTIFACT) { bind(BindKey(BOARD, "V"), draftOf(NOTE)) {} })

        assembly.dynamics.failures.map { it.code } shouldBe listOf("bind_type_mismatch")
        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to false)
    }

    test("a bind for a parameter its type does not have is rejected at load") {
        val assembly = assembleBoard(binder(BOARD_ARTIFACT) { bind(BindKey(BOARD, "W"), draftOf(BOARD)) {} })

        assembly.dynamics.failures.map { it.code } shouldBe listOf("bind_unknown_parameter")
        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to false)
    }

    test("registration runs at load, so a provider whose register throws is known with the catalog") {
        val assembly = assembleBoard(binder(BOARD_ARTIFACT) { error("broken provider") })

        assembly.dynamics.failures.map { it.code } shouldBe listOf("dynamic_registration_failed")
        assembly.checkedParameters() shouldBe listOf("T" to false, "V" to false)
    }
}

private fun assembleBoard(vararg dynamics: OwnedDynamic): CatalogAssembly =
    CatalogContributions(
        declarations = listOf(OwnedTypeDeclaration(BOARD_ARTIFACT, board()), OwnedTypeDeclaration(BOARD_ARTIFACT, record(NOTE))),
        dynamics = dynamics.toList(),
    ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "binds")))

private fun binder(
    origin: ProviderOrigin,
    register: Dynamics.() -> Unit,
) = OwnedDynamic(
    origin = origin,
    ruleOrigin = RuleOrigin(owner = TypeDefinitionId.qualified("dynamic", origin.sourcePart), ordinal = 0),
    provider =
        object : DynamicProvider {
            override fun Dynamics.register() = register()
        },
)

private fun draftOf(definition: TypeDefinitionId) =
    object : DraftType<DraftBinding> {
        override val match = ResourceTypeMatch.Definition(definition)

        override fun bind(binding: DraftBinding) = binding
    }

private fun CatalogAssembly.checkedParameters(): List<Pair<String, Boolean>> =
    (checked.declaration(BOARD) as Resolution.Ready).value.parameters.map { it.name to it.derived }

private fun CatalogAssembly.publishedParameters(): List<Pair<String, Boolean>> =
    editorCatalog.types
        .single { it.definition.id == BOARD }
        .definition.parameters
        .map { it.name to it.derived }

/** A board with a creator chosen `T` and a `V` a bind may compute. */
private fun board(): TypeDefinition =
    record(BOARD).copy(
        parameters =
            listOf("T", "V").mapIndexed { index, name ->
                TypeParameter(key = ParameterKey(owner = BOARD, index = index), name = name, bounds = emptyList(), derived = false)
            },
    )

private fun record(id: TypeDefinitionId): TypeDefinition =
    TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE))
