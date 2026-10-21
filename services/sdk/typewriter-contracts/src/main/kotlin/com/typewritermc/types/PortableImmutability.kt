package com.typewritermc.types

import java.util.Collections

inline fun <T, R> Iterable<T>.immutableListCopy(transform: (T) -> R): List<R> = Collections.unmodifiableList(mapTo(ArrayList(), transform))

fun <T> Iterable<T>.immutableListCopy(): List<T> = immutableListCopy { it }

inline fun <K, V, R> Map<K, V>.immutableMapCopy(transform: (V) -> R): Map<K, R> =
    Collections.unmodifiableMap(entries.associateTo(LinkedHashMap()) { (key, value) -> key to transform(value) })

fun <K, V> Map<K, V>.immutableMapCopy(): Map<K, V> = immutableMapCopy { it }
