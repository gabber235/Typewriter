package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.expression.EvaluationDiagnostic

sealed interface Availability<out T> {
    data class Available<T>(
        val value: T,
    ) : Availability<T>

    data class Unavailable(
        val locations: List<ValueLocation>,
    ) : Availability<Nothing>

    data class Failed(
        val diagnostic: EvaluationDiagnostic,
    ) : Availability<Nothing>
}

interface AuthoredReads {
    val catalog: CatalogGeneration
    val readContext: ReadContext

    fun <T> read(path: BoundPath<T>): Availability<T>

    fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: com.typewritermc.types.TypeUse,
    ): Availability<T>

    fun presence(path: BoundPath<*>): Availability<Boolean>

    fun binding(path: BoundPath<*>): Availability<DraftBinding>

    fun canonicalValueKey(path: BoundPath<*>): Availability<String>

    fun members(path: BoundCollectionPath): List<ItemId>

    fun <D> select(query: TypedSelection<D>): PartialSelection<D>
}

inline fun <T, R> Availability<T>.map(transform: (T) -> R): Availability<R> =
    when (this) {
        is Availability.Available -> Availability.Available(transform(value))
        is Availability.Unavailable -> this
        is Availability.Failed -> this
    }

inline fun <T, R> Availability<T>.flatMap(transform: (T) -> Availability<R>): Availability<R> =
    when (this) {
        is Availability.Available -> transform(value)
        is Availability.Unavailable -> this
        is Availability.Failed -> this
    }
