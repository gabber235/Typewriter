package com.typewritermc.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.ValuePath
import com.typewritermc.configuration.generatedExpressionScope
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.expression.Expr
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.portableExpression
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse

sealed interface ResourceTypeMatch {
    data object AnyResource : ResourceTypeMatch

    data class Definition(
        val id: TypeDefinitionId,
    ) : ResourceTypeMatch

    /** Matches only this exact applied type. Definition represents nominal subtype and broader generic views. */
    data class Application(
        val use: TypeUse.Named,
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

fun <D, S : Any> compileSelection(
    type: DraftType<D>,
    scope: kotlin.reflect.KClass<S>,
    predicate: S.() -> Expr<Boolean, out MissingPolicy>,
): TypedSelection<D> {
    val configured =
        portableExpression<Any?>(
            ExpressionNode.Read(ExpressionBindingId("configured_value"), ValuePath()),
        )
    return TypedSelection(type, generatedExpressionScope(scope, configured).predicate().node)
}

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
