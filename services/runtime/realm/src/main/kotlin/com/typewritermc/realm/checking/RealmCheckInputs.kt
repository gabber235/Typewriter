@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.DraftExpectation
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.boundPath
import com.typewritermc.checking.CheckEvaluation
import com.typewritermc.checking.CheckInput
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.configuration.name
import com.typewritermc.expression.operations.HostFailure
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.PartialSchema
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.concurrent.atomic.AtomicLong

/**
 * Evaluates declarative check inputs within the tracked captured reads of one check execution.
 *
 * Collection patterns sharing an occurrence prefix bind to the same item or map row rather than forming
 * unrelated tuples. Missing values defer the check, failures remain diagnostic outcomes, and tuple limits
 * contribute incomplete read health so publication cannot treat truncated evaluation as success.
 */
class RealmCheckInputs(
    private val ids: () -> DiagnosticId = defaultDiagnosticIdFactory(),
) {
    context(reads: CapturedAuthoringReads)
    fun evaluate(
        recipe: CheckRecipe,
        subject: DraftBinding,
    ): CheckEvaluation {
        val candidates =
            recipe.inputs.map { input ->
                val expected =
                    expectedType(subject, input.path, reads.view.original.catalog.checked)
                        ?: return CheckEvaluation(CheckOutcome.NeedsInputWrapper(listOf(subject.location)), emptyList())
                reads.expand(subject.location, input.path).map { location ->
                    InputCandidate(input, location, occurrenceBindings(subject.location, input.path, location), expected)
                }
            }
        if (candidates.any { it.isEmpty() }) return CheckEvaluation(CheckOutcome.FINISHED, emptyList())
        val tuples =
            candidates.fold(listOf(InputTuple())) { tuples, inputCandidates ->
                tuples.flatMap { tuple ->
                    inputCandidates.mapNotNull { candidate ->
                        if (reads.admitCheckTuple()) tuple.merge(candidate) else null
                    }
                }
            }
        val missing = linkedSetOf<ValueLocation>()
        val findings = mutableListOf<Diagnostic>()
        tuples.forEach { tuple ->
            val values =
                tuple.candidates.map { candidate ->
                    reads.portable(boundPath<Any?>(candidate.location, candidate.expected))
                }
            values.filterIsInstance<Availability.Unavailable>().flatMapTo(missing, Availability.Unavailable::locations)
            val failure = values.filterIsInstance<Availability.Failed>().firstOrNull()
            if (failure != null) return failed(recipe, failure.diagnostic)
            if (values.any { it !is Availability.Available }) return@forEach
            val complete = values.map { (it as Availability.Available).value }
            if (tuple.candidates.zip(complete).any { (candidate, value) -> candidate.input.skipNull && value.value == DataValue.NULL }) {
                return@forEach
            }
            try {
                if (!recipe.predicate.invoke(complete)) {
                    findings += finding(recipe, subject, tuple, reads)
                }
            } catch (failure: Exception) {
                failure.rethrowExceptional()
                return failed(
                    recipe,
                    EvaluationDiagnostic(
                        failure = HostFailure.CheckCallbackFailed,
                        message = failure.message ?: failure::class.simpleName.orEmpty(),
                        locations = tuple.candidates.map(InputCandidate::location),
                    ),
                )
            }
        }
        if (missing.isNotEmpty()) return CheckEvaluation(CheckOutcome.NeedsInputWrapper(missing.toList()), findings)
        return CheckEvaluation(CheckOutcome.FINISHED, findings)
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
                code = failure.failure.value,
                message = failure.message,
                severity = DiagnosticSeverity.ERROR,
                primary = failure.locations.firstOrNull(),
                related = failure.locations.drop(1),
            )
        return CheckEvaluation(CheckOutcome.FailedWrapper(listOf(diagnostic)), emptyList())
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
            is FieldPatternSegment.FieldWrapper -> {
                index += 1
            }

            FieldPatternSegment.ITEMS,
            FieldPatternSegment.KEYS,
            FieldPatternSegment.VALUES,
            -> {
                val item = concrete.getOrNull(index)
                val start = index
                if (item is PathSegment.ItemWrapper) index += 1
                if (concrete.getOrNull(index) == PathSegment.MAP_KEY || concrete.getOrNull(index) == PathSegment.MAP_VALUE) index += 1
                bindings[OccurrenceSlot(prefix.toList())] = concrete.subList(start, (start + 1).coerceAtMost(concrete.size))
            }

            else -> {
                unknownVariant(segment)
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
                is FieldPatternSegment.FieldWrapper -> cursor.field(segment.name, catalog) ?: return null
                FieldPatternSegment.ITEMS -> cursor.item(catalog) ?: return null
                FieldPatternSegment.KEYS -> cursor.key(catalog) ?: return null
                FieldPatternSegment.VALUES -> cursor.value(catalog) ?: return null
                else -> unknownVariant(segment)
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
        val schema: PartialSchema,
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
        is ResolvedRepresentation.SequenceWrapper -> TypeCursor.Applied(representation.value.item)
        else -> null
    }

private fun TypeCursor.key(catalog: CheckedCatalog): TypeCursor? =
    (resolve(catalog)?.schema?.representation as? ResolvedRepresentation.MappingWrapper)?.value?.key?.let(TypeCursor::Applied)

private fun TypeCursor.value(catalog: CheckedCatalog): TypeCursor? =
    (resolve(catalog)?.schema?.representation as? ResolvedRepresentation.MappingWrapper)?.value?.value?.let(TypeCursor::Applied)

private fun TypeCursor.resolve(catalog: CheckedCatalog): CheckedType? =
    when (this) {
        is TypeCursor.Checked -> checked
        is TypeCursor.Applied -> (catalog.resolve(use) as? Resolution.Ready)?.value
        is TypeCursor.Partial -> null
    }

private fun defaultDiagnosticIdFactory(): () -> DiagnosticId {
    val next = AtomicLong()
    return { DiagnosticId(value = "realm:${next.getAndIncrement()}") }
}
