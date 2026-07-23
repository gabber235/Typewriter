package com.typewritermc.services.libs.utils

import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first

/**
 * Thread-safe mutable state holder for values that change over time.
 *
 * Unlike DeferredProvider (set once), StateProvider can be updated.
 * Use for states that transition (e.g., Initializing → Pending → Bound).
 */
class StateProvider<T>(initial: T) {
    private val flow = MutableStateFlow(initial)

    val state: StateFlow<T> = flow

    fun get(): T = flow.value

    fun set(value: T) {
        flow.value = value
    }

    suspend fun awaitValue(predicate: (T) -> Boolean): T = flow.first(predicate)
}

/**
 * Suspends until the value becomes non-null and returns it.
 */
suspend fun <T : Any> StateProvider<T?>.awaitNonNull(): T = awaitValue { it != null }!!

/**
 * Returns the current value if non-null, otherwise throws IllegalStateException.
 */
fun <T : Any> StateProvider<T?>.require(): T =
    get() ?: throw IllegalStateException("StateProvider value is null")
