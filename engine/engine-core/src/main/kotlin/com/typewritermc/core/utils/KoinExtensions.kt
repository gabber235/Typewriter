package com.typewritermc.core.utils

import org.koin.core.Koin
import org.koin.core.annotation.KoinInternalApi
import org.koin.core.instance.ResolutionContext
import org.koin.core.parameter.ParametersHolder
import org.koin.core.registry.InstanceRegistry
import java.lang.invoke.MethodHandles
import java.lang.invoke.MethodType
import kotlin.reflect.KClass

private val lookup = MethodHandles.lookup()

private val getAllMethodType =
    MethodType.methodType(List::class.java, KClass::class.java, ResolutionContext::class.java)
private val getAllMethodHandle = lookup.findVirtual(InstanceRegistry::class.java, "getAll\$koin_core", getAllMethodType)

fun <T : Any> InstanceRegistry.getAll(clazz: KClass<T>, context: ResolutionContext): List<T> {
    return getAllMethodHandle.invoke(this, clazz, context) as List<T>
}

@OptIn(KoinInternalApi::class)
inline fun <reified T : Any> Koin.getAll(context: ResolutionContext): List<T> =
    instanceRegistry.getAll(T::class, context)

@OptIn(KoinInternalApi::class)
inline fun <reified T : Any> Koin.getAll(vararg parameters: Any?): List<T> {
    return getAll(
        ResolutionContext(
            logger,
            scopeRegistry.rootScope,
            T::class,
            parameters = ParametersHolder(parameters.toMutableList())
        )
    )
}