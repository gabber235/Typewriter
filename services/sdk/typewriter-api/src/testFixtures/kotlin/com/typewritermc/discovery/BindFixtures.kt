package com.typewritermc.discovery

import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.formula.BindParameter
import com.typewritermc.formula.DynamicProvider
import com.typewritermc.formula.Dynamics
import com.typewritermc.testkit.origin
import com.typewritermc.types.catalog.BindKey
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.qualified
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

/** A generic resource type with a creator chosen `T` and a `V` a bind may compute. */
val BIND_BOARD = TypeDefinitionId.qualified("bind", "Board")

/** The artifact that declares [BIND_BOARD]. */
val BOARD_ARTIFACT = origin("board types", artifact = "test:board")

/** An artifact that does not declare [BIND_BOARD]. */
val OTHER_ARTIFACT = origin("other types", artifact = "test:other")

/** The catalog assembled from [BIND_BOARD] and [dynamics]. */
fun assembleBoard(vararg dynamics: OwnedDynamic): CatalogAssembly =
    CatalogContributions(
        declarations = listOf(OwnedTypeDeclaration(BOARD_ARTIFACT, boardDeclaration())),
        dynamics = dynamics.toList(),
    ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "binds")))

/** A dynamic provider owned by [origin] that registers [register]. */
fun binder(
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

/** The board's parameter [name] as codegen would hand it out, reading the board as its bare binding. */
@OptIn(GeneratedSdkApi::class)
fun boardParameter(name: String) =
    BindParameter(
        BindKey(BIND_BOARD, name),
        object : DraftType<DraftBinding> {
            override val match = ResourceTypeMatch.Definition(BIND_BOARD)

            override fun bind(binding: DraftBinding) = binding
        },
    )

/** Each parameter of [BIND_BOARD] in the checked catalog, with whether a bind computes it. */
fun CatalogAssembly.checkedParameters(): List<Pair<String, Boolean>> =
    (checked.declaration(BIND_BOARD) as Resolution.Ready).value.parameters.map { it.name to it.derived }

/** Each parameter of [BIND_BOARD] in the catalog editors and engines read, with whether a bind computes it. */
fun CatalogAssembly.publishedParameters(): List<Pair<String, Boolean>> =
    editorCatalog.types
        .single { it.definition.id == BIND_BOARD }
        .definition.parameters
        .map { it.name to it.derived }

/** A board with a creator chosen `T` and a `V` a bind may compute. */
fun boardDeclaration(): TypeDefinition =
    emptyRecord(BIND_BOARD).copy(
        parameters =
            listOf("T", "V").mapIndexed { index, name ->
                TypeParameter(key = ParameterKey(owner = BIND_BOARD, index = index), name = name, bounds = emptyList(), derived = false)
            },
    )

/** A concrete record type [id] without fields or parameters. */
fun emptyRecord(id: TypeDefinitionId): TypeDefinition =
    TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE))
