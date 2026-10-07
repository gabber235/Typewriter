package com.typewritermc.realm.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.DiagnosticId
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.boundPath
import com.typewritermc.checking.CheckEvaluation
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckInputs
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.DiagnosticSeverity
import com.typewritermc.configuration.FieldPatternSegment
import com.typewritermc.configuration.RelativeFieldPattern
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.types.DataValue
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import java.util.concurrent.CancellationException
import java.util.concurrent.atomic.AtomicLong

class RealmCheckInputs(
    private val ids: () -> DiagnosticId = defaultDiagnosticIdFactory(),
) : CheckInputs {
    context(reads: com.typewritermc.authoring.AuthoredReads)
    override fun evaluate(
        recipe: CheckRecipe,
        subject: DraftBinding,
    ): CheckEvaluation {
        val snapshotReads =
            reads as? CapturedAuthoringReads
                ?: return failed(
                    recipe,
                    EvaluationDiagnostic(
                        "untracked_reads",
                        "Check inputs require Realm snapshot reads.",
                        listOf(subject.location),
                    ),
                )
        val candidates =
            recipe.inputs.map { input ->
                val expected =
                    expectedType(subject, input.path, snapshotReads.view.original.catalog.checked)
                        ?: return CheckEvaluation(CheckOutcome.NeedsInput(listOf(subject.location)), emptyList())
                snapshotReads.expand(subject.location, input.path).map { location ->
                    InputCandidate(input, location, occurrenceBindings(subject.location, input.path, location), expected)
                }
            }
        if (candidates.any { it.isEmpty() }) return CheckEvaluation(CheckOutcome.Finished, emptyList())
        val tuples =
            candidates.fold(listOf(InputTuple())) { tuples, inputCandidates ->
                tuples.flatMap { tuple ->
                    inputCandidates.mapNotNull { candidate ->
                        if (snapshotReads.admitCheckTuple()) tuple.merge(candidate) else null
                    }
                }
            }
        val missing = linkedSetOf<ValueLocation>()
        val findings = mutableListOf<Diagnostic>()
        tuples.forEach { tuple ->
            val values =
                tuple.candidates.map { candidate ->
                    snapshotReads.portable(boundPath<Any?>(candidate.location, candidate.expected))
                }
            values.filterIsInstance<Availability.Unavailable>().flatMapTo(missing, Availability.Unavailable::locations)
            val failure = values.filterIsInstance<Availability.Failed>().firstOrNull()
            if (failure != null) return failed(recipe, failure.diagnostic)
            if (values.any { it !is Availability.Available }) return@forEach
            val complete = values.map { (it as Availability.Available).value }
            if (tuple.candidates.zip(complete).any { (candidate, value) -> candidate.input.skipNull && value.value == DataValue.Null }) {
                return@forEach
            }
            try {
                if (!recipe.predicate.invoke(complete)) {
                    findings += finding(recipe, subject, tuple, snapshotReads)
                }
            } catch (cancellation: CancellationException) {
                throw cancellation
            } catch (failure: Exception) {
                return failed(
                    recipe,
                    EvaluationDiagnostic(
                        code = "check_callback_failed",
                        message = failure.message ?: failure::class.simpleName.orEmpty(),
                        locations = tuple.candidates.map(InputCandidate::location),
                    ),
                )
            }
        }
        if (missing.isNotEmpty()) return CheckEvaluation(CheckOutcome.NeedsInput(missing.toList()), findings)
        return CheckEvaluation(CheckOutcome.Finished, findings)
    }

    private fun finding(
        recipe: CheckRecipe,
        subject: DraftBinding,
        tuple: InputTuple,
        reads: CapturedAuthoringReads,
    ): Diagnostic {
        val targets =
            recipe.diagnostic.targets
                .flatMap { pattern ->
                    reads.expand(subject.location, pattern).mapNotNull { location ->
                        val bindings = occurrenceBindings(subject.location, pattern, location)
                        location.takeIf { compatible(tuple.bindings, bindings) }
                    }
                }.distinct()
        return Diagnostic(
            id = ids(),
            origin = recipe.owner,
            code = recipe.diagnostic.code,
            message = recipe.diagnostic.message,
            severity = recipe.diagnostic.severity,
            primary = targets.firstOrNull() ?: tuple.candidates.firstOrNull()?.location ?: subject.location,
            related = targets.drop(1),
        )
    }

    private fun failed(
        recipe: CheckRecipe,
        failure: EvaluationDiagnostic,
    ): CheckEvaluation {
        val diagnostic =
            Diagnostic(
                id = ids(),
                origin = recipe.owner,
                code = failure.code,
                message = failure.message,
                severity = DiagnosticSeverity.Error,
                primary = failure.locations.firstOrNull(),
                related = failure.locations.drop(1),
            )
        return CheckEvaluation(CheckOutcome.Failed(listOf(diagnostic)), emptyList())
    }
}

private data class InputCandidate(
    val input: CheckInput,
    val location: ValueLocation,
    val bindings: Map<OccurrenceSlot, List<PathSegment>>,
    val expected: TypeUse,
)

private data class InputTuple(
    val candidates: List<InputCandidate> = emptyList(),
    val bindings: Map<OccurrenceSlot, List<PathSegment>> = emptyMap(),
) {
    fun merge(candidate: InputCandidate): InputTuple? {
        if (!compatible(bindings, candidate.bindings)) return null
        return InputTuple(candidates + candidate, bindings + candidate.bindings)
    }
}

private data class OccurrenceSlot(
    val prefix: List<FieldPatternSegment>,
)

private fun compatible(
    first: Map<OccurrenceSlot, List<PathSegment>>,
    second: Map<OccurrenceSlot, List<PathSegment>>,
): Boolean = first.keys.intersect(second.keys).all { first[it] == second[it] }

private fun occurrenceBindings(
    subject: ValueLocation,
    pattern: RelativeFieldPattern,
    location: ValueLocation,
): Map<OccurrenceSlot, List<PathSegment>> {
    val concrete = location.path.segments.drop(subject.path.segments.size)
    var index = 0
    val prefix = mutableListOf<FieldPatternSegment>()
    val bindings = linkedMapOf<OccurrenceSlot, List<PathSegment>>()
    pattern.segments.forEach { segment ->
        when (segment) {
            is FieldPatternSegment.Field -> {
                index += 1
            }

            FieldPatternSegment.Items,
            FieldPatternSegment.Keys,
            FieldPatternSegment.Values,
            -> {
                val item = concrete.getOrNull(index)
                val start = index
                if (item is PathSegment.Item) index += 1
                if (concrete.getOrNull(index) == PathSegment.MapKey || concrete.getOrNull(index) == PathSegment.MapValue) index += 1
                bindings[OccurrenceSlot(prefix.toList())] = concrete.subList(start, (start + 1).coerceAtMost(concrete.size))
            }
        }
        prefix += segment
    }
    return bindings
}

internal fun expectedType(
    subject: DraftBinding,
    path: RelativeFieldPattern,
    catalog: CheckedCatalog,
): TypeUse? {
    var cursor: TypeCursor =
        when (val expected = subject.expected) {
            is DraftExpectation.Complete -> TypeCursor.Checked(expected.type)
            is DraftExpectation.PartialRoot -> TypeCursor.Partial(expected.schema)
        }
    path.segments.forEach { segment ->
        cursor =
            when (segment) {
                is FieldPatternSegment.Field -> cursor.field(segment.name, catalog) ?: return null
                FieldPatternSegment.Items -> cursor.item(catalog) ?: return null
                FieldPatternSegment.Keys -> cursor.key(catalog) ?: return null
                FieldPatternSegment.Values -> cursor.value(catalog) ?: return null
            }
    }
    return cursor.use
}

private sealed interface TypeCursor {
    val use: TypeUse?

    data class Checked(
        val checked: CheckedType,
    ) : TypeCursor {
        override val use: TypeUse = checked.use
    }

    data class Applied(
        override val use: TypeUse,
    ) : TypeCursor

    data class Partial(
        val schema: com.typewritermc.authoring.PartialSchema,
    ) : TypeCursor {
        override val use: TypeUse? = null
    }
}

private fun TypeCursor.field(
    name: String,
    catalog: CheckedCatalog,
): TypeCursor? =
    when (this) {
        is TypeCursor.Partial -> {
            schema.knownFields
                .singleOrNull { it.key == name }
                ?.type
                ?.let(TypeCursor::Applied)
        }

        else -> {
            resolve(catalog)
                ?.schema
                ?.fields
                ?.singleOrNull { it.key == name }
                ?.type
                ?.let(TypeCursor::Applied)
        }
    }

private fun TypeCursor.item(catalog: CheckedCatalog): TypeCursor? =
    when (val representation = resolve(catalog)?.schema?.representation) {
        is ResolvedRepresentation.Sequence -> TypeCursor.Applied(representation.item)
        else -> null
    }

private fun TypeCursor.key(catalog: CheckedCatalog): TypeCursor? =
    (resolve(catalog)?.schema?.representation as? ResolvedRepresentation.Mapping)?.key?.let(TypeCursor::Applied)

private fun TypeCursor.value(catalog: CheckedCatalog): TypeCursor? =
    (resolve(catalog)?.schema?.representation as? ResolvedRepresentation.Mapping)?.value?.let(TypeCursor::Applied)

private fun TypeCursor.resolve(catalog: CheckedCatalog): CheckedType? =
    when (this) {
        is TypeCursor.Checked -> checked
        is TypeCursor.Applied -> (catalog.resolve(use) as? Resolution.Ready)?.value
        is TypeCursor.Partial -> null
    }

private fun defaultDiagnosticIdFactory(): () -> DiagnosticId {
    val next = AtomicLong()
    return { DiagnosticId("realm:${next.getAndIncrement()}") }
}
