package com.typewritermc.checking

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.flatMap
import com.typewritermc.authoring.map
import java.math.BigInteger

fun <D> PartialSelection<D>.singleOrNone(): Availability<D?> =
    when {
        knownMatches.size > 1 -> Availability.Failed(selectionFailure("selection.multiple", "More than one value matched"))
        else -> complete().map(List<D>::singleOrNull)
    }

fun <D> PartialSelection<D>.all(predicate: (D) -> Availability<Boolean>): Availability<Boolean> =
    aggregateBoolean(identity = true, decisive = false, predicate = predicate)

fun <D> PartialSelection<D>.any(predicate: (D) -> Availability<Boolean>): Availability<Boolean> =
    aggregateBoolean(identity = false, decisive = true, predicate = predicate)

fun <D> PartialSelection<D>.sum(value: (D) -> Availability<BigInteger>): Availability<BigInteger> =
    complete().flatMap { values -> values.foldAvailability(BigInteger.ZERO) { total, item -> value(item).map(total::add) } }

fun <D> PartialSelection<D>.minimum(value: (D) -> Availability<BigInteger>): Availability<BigInteger?> =
    complete().flatMap { values ->
        values.foldAvailability(null as BigInteger?) { current, item ->
            value(item).map { next -> current?.min(next) ?: next }
        }
    }

fun <D> PartialSelection<D>.maximum(value: (D) -> Availability<BigInteger>): Availability<BigInteger?> =
    complete().flatMap { values ->
        values.foldAvailability(null as BigInteger?) { current, item ->
            value(item).map { next -> current?.max(next) ?: next }
        }
    }

private fun <D> PartialSelection<D>.aggregateBoolean(
    identity: Boolean,
    decisive: Boolean,
    predicate: (D) -> Availability<Boolean>,
): Availability<Boolean> {
    for (item in knownMatches) {
        when (val result = predicate(item)) {
            is Availability.Available -> if (result.value == decisive) return result
            is Availability.Failed -> return result
            is Availability.Unavailable -> return result
        }
    }
    return complete().map { identity }
}

private inline fun <T, R> Iterable<T>.foldAvailability(
    initial: R,
    operation: (R, T) -> Availability<R>,
): Availability<R> {
    var current = initial
    for (item in this) {
        when (val next = operation(current, item)) {
            is Availability.Available -> current = next.value
            is Availability.Unavailable -> return next
            is Availability.Failed -> return next
        }
    }
    return Availability.Available(current)
}

private fun selectionFailure(
    code: String,
    message: String,
) = com.typewritermc.expression.EvaluationDiagnostic(code, message, emptyList())
