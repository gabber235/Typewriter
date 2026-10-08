package com.typewritermc.presentation

import java.lang.reflect.InvocationHandler
import java.lang.reflect.Method
import java.lang.reflect.Proxy
import kotlin.reflect.KClass

internal fun Method.presentationOperationName(): String = name.substringBefore('-')

@Suppress("UNCHECKED_CAST")
internal fun <T : Any> proxy(
    type: KClass<T>,
    handler: InvocationHandler,
): T = Proxy.newProxyInstance(type.java.classLoader, arrayOf(type.java), handler) as T

@Suppress("UNCHECKED_CAST")
internal fun invokeBlock(
    block: Any?,
    receiver: Any,
) {
    (block as? Function1<Any, Unit>)?.invoke(receiver)
}
