package com.typewritermc.elements

import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DataValue
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.TypeId
import java.util.UUID

/**
 * Allocates identities for newly decomposed reference occurrences.
 *
 * Supply a deterministic allocator in tests. Production allocators must avoid duplicate slots within the stored
 * value.
 */
fun interface ReferenceSlotAllocator {
    fun allocate(): ReferenceSlotId
}

/**
 * Projects logical resource references into stored markers and separate edges using a type graph.
 *
 * Each occurrence gets a fresh slot, even when targets repeat. Malformed values or reference shapes throw;
 * decomposition does not look up target resources.
 */
class ReferenceDecomposer(
    private val slotAllocator: ReferenceSlotAllocator = ReferenceSlotAllocator { ReferenceSlotId(UUID.randomUUID().toString()) },
) {
    fun decompose(
        graph: TypeGraph,
        logicalValue: DataValue,
    ): StoredElementValue = decompose(graph, graph.root, logicalValue)

    fun decompose(
        graph: TypeGraph,
        expression: TypeExpression,
        logicalValue: DataValue,
    ): StoredElementValue {
        val context = ProjectionContext(graph)
        val references = mutableListOf<StoredReference>()
        val valueWithSlots =
            context.transform(expression, logicalValue, reference = { expectedType, value ->
                val reference = value.requireStringReference()
                val slot = slotAllocator.allocate()
                references += StoredReference(slot, reference, expectedType)
                slot.marker()
            })
        return StoredElementValue(valueWithSlots, references)
    }
}

/**
 * Reconstructs logical references from stored slot markers and edges.
 *
 * Assembly checks marker shape, slot uniqueness, missing or unused edges, and expected types. It returns
 * diagnostics with a best effort value on failure, so callers must inspect the result before compiling or
 * executing it.
 */
class ReferenceAssembler {
    fun assemble(
        graph: TypeGraph,
        stored: StoredElementValue,
    ): ReferenceAssemblyResult {
        val references = stored.references.associateBy(StoredReference::slot)
        val usedSlots = mutableSetOf<ReferenceSlotId>()
        val diagnostics = mutableListOf<ReferenceDiagnostic>()
        val context = ProjectionContext(graph)
        val logicalValue =
            runCatching {
                context.transform(graph.root, stored.valueWithSlots, reference = { expectedType, value ->
                    val slot = value.referenceSlot()
                    if (slot == null) {
                        diagnostics += ReferenceDiagnostic(ReferenceDiagnosticCode.INVALID_SLOT_MARKER)
                        return@transform value
                    }
                    if (!usedSlots.add(slot)) {
                        diagnostics += ReferenceDiagnostic(ReferenceDiagnosticCode.DUPLICATE_SLOT, slot)
                    }
                    val reference = references[slot]
                    if (reference == null) {
                        diagnostics += ReferenceDiagnostic(ReferenceDiagnosticCode.SLOT_WITHOUT_EDGE, slot)
                        return@transform value
                    }
                    if (reference.expectedType != expectedType) {
                        diagnostics +=
                            ReferenceDiagnostic(
                                code = ReferenceDiagnosticCode.EXPECTED_TYPE_MISMATCH,
                                slot = slot,
                                target = reference.target,
                            )
                    }
                    DataValue.StringValue(reference.target.referenceString())
                })
            }.getOrElse {
                diagnostics += ReferenceDiagnostic(ReferenceDiagnosticCode.VALUE_SHAPE_MISMATCH)
                stored.valueWithSlots
            }
        stored.references
            .filterNot { it.slot in usedSlots }
            .forEach {
                diagnostics +=
                    ReferenceDiagnostic(
                        code = ReferenceDiagnosticCode.EDGE_WITHOUT_SLOT,
                        slot = it.slot,
                        target = it.target,
                    )
            }
        return if (diagnostics.isEmpty()) {
            ReferenceAssemblyResult.Success(logicalValue)
        } else {
            ReferenceAssemblyResult.Failure(logicalValue, diagnostics)
        }
    }
}

/**
 * Carries the reconstructed value and whether reference projection was internally consistent.
 *
 * The value in a failure is diagnostic output and may still contain unresolved slot markers; it is not validated
 * runtime content.
 */
sealed interface ReferenceAssemblyResult {
    val value: DataValue

    data class Success(
        override val value: DataValue,
    ) : ReferenceAssemblyResult

    data class Failure(
        override val value: DataValue,
        val diagnostics: List<ReferenceDiagnostic>,
    ) : ReferenceAssemblyResult
}

data class ReferenceDiagnostic(
    val code: ReferenceDiagnosticCode,
    val slot: ReferenceSlotId? = null,
    val target: ResourceId? = null,
)

enum class ReferenceDiagnosticCode {
    INVALID_SLOT_MARKER,
    SLOT_WITHOUT_EDGE,
    EDGE_WITHOUT_SLOT,
    DUPLICATE_SLOT,
    EXPECTED_TYPE_MISMATCH,
    VALUE_SHAPE_MISMATCH,
}

internal class ProjectionContext(
    graph: TypeGraph,
) {
    private val definitions = (StandardTypes.definitions + graph.definitions).associateBy { it.id.withArguments(emptyList()) }

    fun transform(
        expression: TypeExpression,
        value: DataValue,
        reference: (TypeExpression, DataValue) -> DataValue,
        parameters: Map<String, TypeExpression> = emptyMap(),
    ): DataValue =
        when (expression) {
            is TypeExpression.Parameter -> {
                transform(parameters[expression.name] ?: TypeExpression.Any, value, reference, parameters)
            }

            is TypeExpression.Named -> {
                transformNamed(expression.reference, value, reference, parameters)
            }

            is TypeExpression.ListType -> {
                DataValue.ListValue(
                    (value as DataValue.ListValue).values.map {
                        transform(expression.element, it, reference, parameters)
                    },
                )
            }

            is TypeExpression.MapType -> {
                DataValue.MapValue(
                    (value as DataValue.MapValue).entries.map {
                        DataMapEntry(
                            key = transform(expression.key, it.key, reference, parameters),
                            value = transform(expression.value, it.value, reference, parameters),
                        )
                    },
                )
            }

            is TypeExpression.Record -> {
                val record = value as DataValue.Record
                DataValue.Record(
                    record.fields.mapValues { (name, fieldValue) ->
                        val field = expression.fields.single { it.name == name }
                        transform(field.type, fieldValue, reference, parameters)
                    },
                )
            }

            else -> {
                value
            }
        }

    private fun transformNamed(
        referenceType: ResolvedTypeRef,
        value: DataValue,
        reference: (TypeExpression, DataValue) -> DataValue,
        parameters: Map<String, TypeExpression>,
    ): DataValue {
        val arguments = referenceType.arguments.map { materialize(it, parameters) }
        if (referenceType.id == REF_TYPE_ID && arguments.size == 1) return reference(arguments.single(), value)
        val resolvedReference = referenceType.withArguments(arguments)
        val definition = definitions[resolvedReference.withArguments(emptyList())] ?: return value
        if (definition.kind != NominalTypeKind.CONCRETE) {
            val polymorphic = value as DataValue.Polymorphic
            return polymorphic.copy(
                value = transformNamed(polymorphic.concreteType, polymorphic.value, reference, parameters),
            )
        }
        val bindings = definition.bind(arguments)
        return transform(definition.representation, value, reference, bindings)
    }

    fun materialize(
        expression: TypeExpression,
        parameters: Map<String, TypeExpression>,
    ): TypeExpression =
        when (expression) {
            is TypeExpression.Parameter -> {
                parameters[expression.name]?.let { materialize(it, parameters) } ?: expression
            }

            is TypeExpression.ListType -> {
                expression.copy(element = materialize(expression.element, parameters))
            }

            is TypeExpression.MapType -> {
                expression.copy(
                    key = materialize(expression.key, parameters),
                    value = materialize(expression.value, parameters),
                )
            }

            is TypeExpression.Record -> {
                expression.copy(fields = expression.fields.map { it.copy(type = materialize(it.type, parameters)) })
            }

            is TypeExpression.Named -> {
                expression.copy(
                    reference = expression.reference.withArguments(expression.reference.arguments.map { materialize(it, parameters) }),
                )
            }

            else -> {
                expression
            }
        }
}

internal fun TypeDefinition.bind(arguments: List<TypeExpression>): Map<String, TypeExpression> =
    parameters.mapIndexed { index, parameter -> parameter.name to arguments.getOrElse(index) { TypeExpression.Any } }.toMap()

private fun DataValue.requireStringReference(): ResourceId = ResourceId.parse((this as DataValue.StringValue).value)

private fun ReferenceSlotId.marker(): DataValue =
    DataValue.Record(
        mapOf(
            SLOT_MARKER_KIND_FIELD to DataValue.StringValue(SLOT_MARKER_KIND),
            SLOT_MARKER_ID_FIELD to DataValue.StringValue(value),
        ),
    )

private fun DataValue.referenceSlot(): ReferenceSlotId? {
    val fields = (this as? DataValue.Record)?.fields ?: return null
    val kind = fields[SLOT_MARKER_KIND_FIELD] as? DataValue.StringValue ?: return null
    val slot = fields[SLOT_MARKER_ID_FIELD] as? DataValue.StringValue ?: return null
    return if (kind.value == SLOT_MARKER_KIND) ReferenceSlotId(slot.value) else null
}

private val REF_TYPE_ID = TypeId.Qualified("typewriter/v1", "Ref")
private const val SLOT_MARKER_KIND_FIELD = "_kind"
private const val SLOT_MARKER_ID_FIELD = "slot"
private const val SLOT_MARKER_KIND = "ref_slot"
