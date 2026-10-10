package com.typewritermc.discovery

import java.lang.reflect.Modifier
import java.util.IdentityHashMap

internal class DeploymentRuntimeOwners(
    private val deploymentClassLoader: ClassLoader,
    services: Map<Class<*>, Any>,
) {
    private val instances = IdentityHashMap<Class<*>, Any>()
    private val resolving = mutableListOf<Class<*>>()

    init {
        services.forEach { (type, instance) ->
            require(type.isInstance(instance)) { "Runtime service does not implement ${type.name}." }
            instances[type] = instance
        }
    }

    @Synchronized
    fun resolve(type: Class<*>): Any {
        instances[type]?.let { return it }
        require(type !in resolving) {
            "Runtime owner constructor cycle: " + (resolving + type).joinToString(" then ", transform = Class<*>::getName)
        }
        require(!type.isInterface && !Modifier.isAbstract(type.modifiers)) {
            "No runtime service is registered for ${type.name}."
        }
        require(Class.forName(type.name, false, deploymentClassLoader) === type) {
            "Runtime owner ${type.name} belongs to a different deployment."
        }

        resolving += type
        try {
            val singleton =
                type.fields.singleOrNull { field ->
                    field.name == "INSTANCE" && Modifier.isStatic(field.modifiers) && field.type === type
                }
            val instance =
                singleton?.get(null) ?: run {
                    val constructors = type.constructors.filter { constructor -> Modifier.isPublic(constructor.modifiers) }
                    require(constructors.size == 1) {
                        "Runtime owner ${type.name} requires one public constructor."
                    }
                    val constructor = constructors.single()
                    constructor.newInstance(*constructor.parameterTypes.map(::resolve).toTypedArray())
                }
            instances[type] = instance
            return instance
        } finally {
            check(resolving.removeAt(resolving.lastIndex) === type)
        }
    }

    val instantiator = GeneratedProviderInstantiator(::resolve)
    val capabilities = CapabilityOwnerResolver { owner -> resolve(owner.java) }
}
