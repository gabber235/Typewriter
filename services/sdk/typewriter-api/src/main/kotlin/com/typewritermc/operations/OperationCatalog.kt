package com.typewritermc.operations

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.name
import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.affected
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.matches
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationOrigin
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.fields
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.requireValid
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.operation.OperationAvailability
import skirout.editor.v1.operation.OperationDrop
import skirout.editor.v1.operation.OperationTargets
import skirout.editor.v1.operation.ResourceOperationDefinition
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import skirout.editor.v1.type_catalog.CapabilityId as SkirCapabilityId

class BoundOperationInput internal constructor(
    val schema: CheckedType?,
    val binding: NativeBinding<*>?,
    val presentation: PresentationId?,
) {
    fun decode(value: DataValue?): Any? {
        if (schema == null) return Unit
        requireNotNull(value) { "Operation input is required." }
        return when (val result = schema.complete(value)) {
            is CompletenessResult.Complete -> requireNotNull(binding).decode(result.value)
            is CompletenessResult.Unfinished -> throw UnfinishedOperationInput(result.locations.map { it.path })
            is CompletenessResult.Invalid -> throw IllegalArgumentException(result.problems.joinToString())
        }
    }
}

/** An input field whose declared candidates back a search in generated forms. */
class CandidateSearch internal constructor(
    val operation: BoundResourceOperation,
    val field: OperationInputField,
) {
    val descriptor: RealmCapabilityDescriptor.Search =
        RealmCapabilityDescriptor.Search(
            operation.definition.id.candidateSearch(field.path),
            ScalarKind.TEXT.use,
            OperationResourceOptionDefinition.use.use,
        )
}

/**
 * A published operation together with its executable callbacks and bound input. [target] is the resource target the
 * published [definition] carries in its wire form.
 */
class BoundResourceOperation internal constructor(
    val origin: ProviderOrigin,
    val target: ResourceTarget,
    val definition: ResourceOperationDefinition,
    val input: BoundOperationInput,
    private val collected: CollectedOperation,
    resourceFields: Set<ValuePath>,
) {
    val capability: RealmCapabilityDescriptor.Authoring =
        RealmCapabilityDescriptor.Authoring(
            definition.id.capability,
            input.schema?.use,
            definition.targets,
            input.presentation,
        )

    /** The field drops fill, when the operation declares one. */
    val dropField: OperationInputField? = collected.fields.singleOrNull { it.drop != null }

    /** Searches over the declared candidates of each resource identity field. */
    val candidateSearches: List<CandidateSearch> =
        collected.fields.filter { it.hasCandidates && it.path in resourceFields }.map { CandidateSearch(this, it) }

    fun availability(
        subjects: List<com.typewritermc.types.ResourceId>,
        reads: OperationReads,
    ): OperationAvailability = collected.availability(subjects, reads)

    suspend fun prepare(
        subjects: List<com.typewritermc.types.ResourceId>,
        input: DataValue?,
        session: OperationPreparation,
    ) = collected.prepare(subjects, this.input.decode(input), session)
}

data class OperationBindingFailure(
    val origin: ProviderOrigin,
    val cause: Throwable,
)

data class OperationCatalog(
    val operations: List<BoundResourceOperation> = emptyList(),
    val diagnostics: List<DeclarationDiagnostic> = emptyList(),
    val failures: List<OperationBindingFailure> = emptyList(),
) {
    val definitions: List<ResourceOperationDefinition> get() = operations.map { it.definition }

    /** The authoring capability of every operation and the candidate search of every searchable field. */
    val capabilities: List<RealmCapabilityDescriptor>
        get() = operations.flatMap { operation -> listOf(operation.capability) + operation.candidateSearches.map { it.descriptor } }

    fun requireAuthoring(id: CapabilityId): BoundResourceOperation =
        requireNotNull(operations.singleOrNull { it.capability.id == id }) { "Authoring operation is unavailable: ${id.value}" }

    /** The operation field whose candidates back the search capability [id], or null for any other capability. */
    fun candidateSearch(id: CapabilityId): CandidateSearch? =
        operations.firstNotNullOfOrNull { operation -> operation.candidateSearches.singleOrNull { it.descriptor.id == id } }
}

/**
 * Assembles published operation definitions together with executable callbacks after checked types and bindings exist.
 *
 * A declaration that failed to collect or bind publishes nothing; its origin and cause remain available as a diagnostic
 * (`invalid_resource_operation`) and a failure. Binding checks the target and input against the checked catalog, the
 * declared fields against the input type, and resolves an explicit input form uniquely.
 */
fun bindOperations(
    declarations: List<OperationDeclaration>,
    catalog: CheckedCatalog,
    bindings: NativeBindingRegistry,
    presentations: List<OwnedPresentation>,
): OperationCatalog {
    val operations = mutableListOf<BoundResourceOperation>()
    val diagnostics = mutableListOf<DeclarationDiagnostic>()
    val failures = mutableListOf<OperationBindingFailure>()
    declarations.forEach { declaration ->
        try {
            declaration.failure?.let { throw it }
            val collected = requireNotNull(declaration.collected)
            require(operations.none { it.definition.id == declaration.id }) { "Duplicate operation ${declaration.id}." }
            when (val target = declaration.target) {
                is ResourceTarget.Type -> {
                    require(catalog.resolve(target.template.asClosedUse().use) is Resolution.Ready) {
                        "Operation target is unavailable: ${target.template}."
                    }
                }

                ResourceTarget.AnyResource -> {
                    Unit
                }
            }
            val input = declaration.input.bind(collected, catalog, bindings, presentations)
            val schema = input.schema
            val resourceFields =
                collected.fields
                    .filter { field ->
                        requireNotNull(schema) { "An operation without input declares no input fields." }
                        val type = requireNotNull(schema.typeAt(field.path)) { "Unknown operation input field ${field.path}." }
                        require(
                            catalog.isOwnedBy(schema, field.owner),
                        ) { "The operation input field ${field.path} belongs to another type." }
                        val resource = type.withoutNullable() == ResourceIdDefinition.use.use
                        require(field.drop == null || resource) { "Only resource identity fields can be filled on drop." }
                        resource
                    }.mapTo(hashSetOf()) { it.path }
            val definition =
                ResourceOperationDefinition(
                    id = declaration.id,
                    presentation = collected.presentation,
                    targets =
                        OperationTargets(
                            subject = SkirTypeCodec.encode(declaration.target).getOrThrow(),
                            cardinality = collected.cardinality,
                        ),
                    capability = SkirCapabilityId(value = declaration.id.capability.value),
                    drop =
                        collected.fields.singleOrNull { it.drop != null }?.let { field ->
                            OperationDrop(
                                input = field.path,
                                hint = requireNotNull(field.drop),
                            ).requireValid()
                        },
                )
            operations += BoundResourceOperation(declaration.origin, declaration.target, definition, input, collected, resourceFields)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (failure: Exception) {
            diagnostics +=
                DeclarationDiagnostic(
                    declaration.target.affected,
                    "invalid_resource_operation",
                    listOf(DeclarationOrigin(declaration.origin.owner)),
                )
            failures += OperationBindingFailure(declaration.origin, failure)
        }
    }
    return OperationCatalog(operations.toList(), diagnostics.distinct(), failures.toList())
}

private fun OperationInput.bind(
    collected: CollectedOperation,
    catalog: CheckedCatalog,
    bindings: NativeBindingRegistry,
    presentations: List<OwnedPresentation>,
): BoundOperationInput =
    when (this) {
        OperationInput.None -> {
            require(collected.fields.isEmpty() && collected.form == null) { "An operation without input declares no input fields or form." }
            BoundOperationInput(null, null, null)
        }

        is OperationInput.Typed -> {
            val checked = (catalog.resolve(use.use) as? Resolution.Ready)?.value ?: error("Operation input type is unavailable: $use.")
            val presentation =
                collected.form?.let { reference ->
                    val matches =
                        presentations.filter {
                            it.reference === reference &&
                                (it.descriptor.target as? PresentationTarget.Named)?.matches(checked) == true
                        }
                    require(matches.size == 1) { "Operation input form must resolve uniquely for $use." }
                    matches.single().descriptor.id
                }
            BoundOperationInput(checked, bindings.bind(checked), presentation)
        }
    }

/** The declared type of the field at [path] below this record type, or null when there is no such field. */
private fun CheckedType.typeAt(path: ValuePath): TypeUse? {
    var current: CheckedType = this
    var type: TypeUse? = null
    path.segments.forEachIndexed { index, segment ->
        val name = (segment as? PathSegment.FieldWrapper)?.name ?: return null
        val record = current.schema.representation as? ResolvedRepresentation.RecordWrapper ?: return null
        type = record.value.fields
            .singleOrNull { it.key == name }
            ?.type ?: return null
        if (index < path.segments.lastIndex) {
            current = (current.resolve(requireNotNull(type).withoutNullable()) as? Resolution.Ready)?.value ?: return null
        }
    }
    return type
}

private fun TypeUse.withoutNullable(): TypeUse = if (this is TypeUse.NullableWrapper) value.value.withoutNullable() else this

private fun TypeUse.definitionOrNull() = (this as? TypeUse.NamedWrapper)?.value?.definition

private fun CheckedCatalog.isOwnedBy(
    input: CheckedType,
    owner: TypeDefinitionId,
): Boolean = input.use.definitionOrNull()?.let { isNominalSubtype(it, owner) } == true

fun NamedTypeTemplate.asClosedUse(): NamedTypeUse = definition.namedUse(arguments.map { it.asClosedUse() })

private fun TypeTemplate.asClosedUse(): TypeUse =
    when (this) {
        is TypeTemplate.NamedWrapper -> value.asClosedUse().use
        is TypeTemplate.NullableWrapper -> value.value.asClosedUse().nullable()
        is TypeTemplate.ScalarWrapper -> value.use
        is TypeTemplate.ParameterWrapper -> error("Resource operations require closed type applications.")
        else -> unknownVariant(this)
    }
