package com.typewritermc.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.configuration.ruleProfileViolations
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.expression.MissingPolicy
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeDefinitionId

sealed interface ResourceTypeMatch {
    data object AnyResource : ResourceTypeMatch

    data class Definition(
        val id: TypeDefinitionId,
    ) : ResourceTypeMatch

    /** Matches only this exact applied type. Definition represents nominal subtype and broader generic views. */
    data class Application(
        val use: NamedTypeUse,
    ) : ResourceTypeMatch
}

interface DraftType<D> {
    val match: ResourceTypeMatch

    fun bind(binding: DraftBinding): D
}

data class TypedSelection<D>(
    val type: DraftType<D>,
    val predicate: ExpressionNode? = null,
)

fun <D> TypedSelection<D>.where(predicate: ExpressionNode): TypedSelection<D> = copy(predicate = predicate)

@GeneratedSdkApi
fun <D, S : Any> compileSelection(
    type: DraftType<D>,
    factory: ExpressionFactory<S>,
    predicate: S.() -> Expr<Boolean, out MissingPolicy>,
): TypedSelection<D> {
    val configured =
        com.typewritermc.expression.input<Any?>(ExpressionBindingId(value = "configured_value"))
    val node = factory.create(configured).predicate().toNode()
    val violations = node.ruleProfileViolations()
    require(violations.isEmpty()) { "Selection predicates use the rule profile: ${violations.joinToString { it.value }}." }
    return TypedSelection(type, node)
}

/**
 * Preserves known matches alongside candidates blocked on authored inputs and an inspection completion marker.
 * Exact aggregates require [complete], while existence and threshold checks can answer from sufficient known
 * matches. An interrupted inspection can remain unavailable even when it has no specific missing input locations.
 */
data class PartialSelection<D>(
    val knownMatches: List<D>,
    val undecided: List<UndecidedCandidate>,
    val completion: InspectionCompletion,
    val failures: List<EvaluationDiagnostic>,
) {
    fun complete(): Availability<List<D>> =
        when {
            failures.isNotEmpty() -> Availability.Failed(failures.first())
            completion is InspectionCompletion.Complete && undecided.isEmpty() -> Availability.Available(knownMatches)
            else -> Availability.Unavailable(undecided.flatMap(UndecidedCandidate::inputs))
        }

    fun count(): Availability<Long> = complete().map { it.size.toLong() }

    fun exists(): Availability<Boolean> =
        if (knownMatches.isNotEmpty()) Availability.Available(true) else complete().map(List<D>::isNotEmpty)

    fun atMost(limit: Long): Availability<Boolean> =
        if (knownMatches.size > limit) Availability.Available(false) else count().map { it <= limit }

    fun atLeast(limit: Long): Availability<Boolean> =
        if (knownMatches.size >= limit) Availability.Available(true) else count().map { it >= limit }
}

private inline fun <T, R> Availability<T>.map(transform: (T) -> R): Availability<R> =
    when (this) {
        is Availability.Available -> Availability.Available(transform(value))
        is Availability.Unavailable -> this
        is Availability.Failed -> this
    }
