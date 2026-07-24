package com.typewritermc.services.libs.utils

import kotlinx.coroutines.CancellationException
import java.util.Collections
import java.util.IdentityHashMap

fun findExceptionalThrowable(throwable: Throwable): Throwable? {
    val visited = Collections.newSetFromMap(IdentityHashMap<Throwable, Boolean>())
    val pending = ArrayDeque<Throwable>().apply { add(throwable) }
    while (pending.isNotEmpty()) {
        val current = pending.removeFirst()
        if (!visited.add(current)) continue
        if (current.isExceptional()) return current
        current.cause?.let(pending::addLast)
        current.suppressed.forEach(pending::addLast)
    }
    return null
}

fun rethrowExceptionalThrowable(throwable: Throwable) {
    findExceptionalThrowable(throwable)?.let { throw it }
}

@Suppress("DEPRECATION")
private fun Throwable.isExceptional(): Boolean =
    this is CancellationException || this is VirtualMachineError || this is ThreadDeath || this is LinkageError
