package com.typewritermc.core.utils

import com.google.gson.Gson
import org.koin.core.qualifier.named
import org.koin.java.KoinJavaComponent
import kotlin.contracts.ExperimentalContracts
import kotlin.contracts.contract
import kotlin.reflect.KClass
import kotlin.reflect.cast
import kotlin.reflect.safeCast

fun <T : Any> KClass<T>.ultraCast(value: Any): T =
    ultraSafeCast(value) ?: throw ClassCastException("Could not cast $this to $qualifiedName")

@OptIn(ExperimentalContracts::class)
fun <T : Any> KClass<T>.ultraSafeCast(value: Any?): T? {
    contract {
        returns() implies (value != null)
    }
    if (value == null) return null
    if (isInstance(value)) {
        return cast(value)
    }
    when (this) {
        String::class -> return safeCast(value.toString())
        Int::class -> return safeCast(intCast(value))
        Long::class -> return safeCast(longCast(value))
        Double::class -> return safeCast(doubleCast(value))
        Float::class -> return safeCast(floatCast(value))
        Generic::class -> return cast(genericCast(value))
    }
    return null
}


fun intCast(value: Any): Int? = when (value) {
    is Int -> value
    is Long -> value.toInt()
    is Double -> value.toInt()
    is Float -> value.toInt()
    is Short -> value.toInt()
    is String -> value.toIntOrNull()
    else -> null
}

fun longCast(value: Any): Long? = when (value) {
    is Int -> value.toLong()
    is Long -> value
    is Double -> value.toLong()
    is Float -> value.toLong()
    is Short -> value.toLong()
    is String -> value.toLongOrNull()
    else -> null
}

fun doubleCast(value: Any): Double? = when (value) {
    is Int -> value.toDouble()
    is Long -> value.toDouble()
    is Double -> value
    is Float -> value.toDouble()
    is Short -> value.toDouble()
    is String -> value.toDoubleOrNull()
    else -> null
}

fun floatCast(value: Any): Float? = when (value) {
    is Int -> value.toFloat()
    is Long -> value.toFloat()
    is Double -> value.toFloat()
    is Float -> value
    is Short -> value.toFloat()
    is String -> value.toFloatOrNull()
    else -> null
}

fun genericCast(value: Any): Generic {
    val gson = KoinJavaComponent.get<Gson>(Gson::class.java, named("dataSerializer"))
    return Generic(gson.toJsonTree(value))
}