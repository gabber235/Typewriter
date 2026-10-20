package com.typewritermc.operations

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.complete
import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.affected
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.presentation.matches
import com.typewritermc.types.DataValue
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingRegistry
import com.typewritermc.types.PresentationId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationOrigin
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import com.typewritermc.types.catalog.resolve
import kotlinx.coroutines.CancellationException

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
            TypeUse.Scalar(ScalarKind.Text),
            OperationResourceOptionDefinition.use,
        )
}

/** A published operation together with its executable callbacks and bound input. */
class BoundResourceOperation internal constructor(
    val origin: ProviderOrigin,
    val definition: ResourceOperationDefinition,
    val input: BoundOperationInput,
    private val collected: CollectedOperation,
    resourceFields: Set<ValuePath>,
) {
    val capability: RealmCapabilityDescriptor.Authoring =
        RealmCapabilityDescriptor.Authoring(
            definition.capability,
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
                    require(catalog.resolve(target.template.asClosedUse()) is Resolution.Ready) {
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
                        val resource = type.withoutNullable() == ResourceIdDefinition.use
                        require(field.drop == null || resource) { "Only resource identity fields can be filled on drop." }
                        resource
                    }.mapTo(hashSetOf()) { it.path }
            val definition =
                ResourceOperationDefinition(
                    declaration.id,
                    collected.presentation,
                    OperationTargets(declaration.target, collected.cardinality),
                    collected.fields.singleOrNull { it.drop != null }?.let { field ->
                        OperationDrop(field.path, requireNotNull(field.drop))
                    },
                )
            operations += BoundResourceOperation(declaration.origin, definition, input, collected, resourceFields)
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
            val checked = (catalog.resolve(use) as? Resolution.Ready)?.value ?: error("Operation input type is unavailable: $use.")
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
        val name = (segment as? PathSegment.Field)?.name ?: return null
        val record = current.schema.representation as? ResolvedRepresentation.Record ?: return null
        type = record.fields.singleOrNull { it.key == name }?.type ?: return null
        if (index < path.segments.lastIndex) {
            current = (current.resolve(requireNotNull(type).withoutNullable()) as? Resolution.Ready)?.value ?: return null
        }
    }
    return type
}

private fun TypeUse.withoutNullable(): TypeUse = if (this is TypeUse.Nullable) value.withoutNullable() else this

private fun TypeUse.definitionOrNull() = (this as? TypeUse.Named)?.definition

private fun CheckedCatalog.isOwnedBy(
    input: CheckedType,
    owner: com.typewritermc.types.TypeDefinitionId,
): Boolean = input.use.definitionOrNull()?.let { isNominalSubtype(it, owner) } == true

fun TypeTemplate.Named.asClosedUse(): TypeUse.Named = TypeUse.Named(definition, arguments.map { it.asClosedUse() })

private fun TypeTemplate.asClosedUse(): TypeUse =
    when (this) {
        is TypeTemplate.Named -> asClosedUse()
        is TypeTemplate.Nullable -> TypeUse.Nullable(value.asClosedUse())
        is TypeTemplate.Scalar -> TypeUse.Scalar(kind)
        is TypeTemplate.Parameter -> error("Resource operations require closed type applications.")
    }
