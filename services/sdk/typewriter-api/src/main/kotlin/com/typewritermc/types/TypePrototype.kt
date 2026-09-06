package com.typewritermc.types

import kotlinx.serialization.KSerializer
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclass
import kotlin.reflect.KClass

/** Supplies dependencies needed while encoding a Kotlin value into portable data. */
interface TypeEncodingContext {
    val prototypes: TypePrototypeRegistry
}

/** Supplies dependencies needed while decoding portable data into a Kotlin value. */
interface TypeDecodingContext {
    val prototypes: TypePrototypeRegistry
}

/**
 * Connects a Kotlin runtime class to its resolved catalog definition.
 *
 * [serializedFieldNames] maps Kotlin property names to serialized names for presentation bindings. Concrete and
 * abstract specializations supply value conversion; a plain prototype only describes metadata.
 */
interface TypePrototype<T : Any> {
    val runtimeType: KClass<T>
    val type: ResolvedTypeRef
    val definition: TypeDefinition
    val serializedFieldNames: Map<String, String>
        get() = emptyMap()
}

/**
 * Converts one concrete runtime type to and from its portable representation.
 *
 * Encoding and decoding use the contextual deployment registry for nested and polymorphic values. Callers must
 * supply the matching structural shape; malformed input and missing dependencies may throw.
 */
interface ConcreteTypePrototype<T : Any> : TypePrototype<T> {
    val serializer: KSerializer<T>

    context(context: TypeEncodingContext)
    fun encode(value: T): DataValue

    context(context: TypeDecodingContext)
    fun decode(value: DataValue): T
}

/**
 * Dispatches an abstract contract through concrete implementations registered in the deployment.
 *
 * Encoded values carry their concrete reference in [DataValue.Polymorphic]. Decoding must reject unregistered or
 * incompatible concrete types rather than loading arbitrary classes named by input.
 */
interface AbstractTypePrototype<T : Any> : TypePrototype<T> {
    context(prototypes: TypePrototypeRegistry)
    fun implementations(): List<ConcreteTypePrototype<out T>>

    context(
        prototypes: TypePrototypeRegistry,
        encoding: TypeEncodingContext,
    )
    fun encode(value: T): DataValue

    context(
        prototypes: TypePrototypeRegistry,
        decoding: TypeDecodingContext,
    )
    fun decode(value: DataValue): T
}

/**
 * Builds the codec graph for one assembled deployment.
 *
 * Prototype references and runtime classes must be unique, and every prototype must match its catalog definition.
 * Construction builds the serialization module and validates concrete serializer shapes. Lookup failures throw;
 * keep registries scoped to the deployment whose classes they retain.
 */
class TypePrototypeRegistry(
    prototypes: Collection<TypePrototype<*>>,
    definitions: Collection<TypeDefinition> = prototypes.map(TypePrototype<*>::definition),
) {
    private val all = prototypes.toList()
    private val byReference = all.associateBy(TypePrototype<*>::type)
    private val byRuntimeType = all.associateBy(TypePrototype<*>::runtimeType)
    private val concrete = all.filterIsInstance<ConcreteTypePrototype<*>>()
    private val definitionsByReference = definitions.associateBy(TypeDefinition::id)

    init {
        require(byReference.size == all.size) { "Type prototype references must be unique." }
        require(byRuntimeType.size == all.size) { "Type prototype runtime classes must be unique." }
        require(definitionsByReference.size == definitions.size) { "Type definitions must be unique." }
        all.forEach { prototype ->
            require(definitionsByReference[prototype.type] == prototype.definition) {
                "Type prototype ${prototype.type} must match its catalog definition."
            }
        }
    }

    val serializersModule: SerializersModule = buildSerializersModule()

    val dataFormat: TypewriterDataFormat = TypewriterDataFormat(serializersModule, this)

    init {
        concrete.forEach { prototype ->
            dataFormat.validate(
                descriptor = prototype.serializer.descriptor,
                type = prototype.definition.representation,
                path = prototype.type.toString(),
            )
        }
    }

    fun require(reference: ResolvedTypeRef): TypePrototype<*> = byReference[reference] ?: error("Type prototype is unavailable: $reference")

    @Suppress("UNCHECKED_CAST")
    fun <T : Any> require(type: KClass<T>): TypePrototype<T> =
        byRuntimeType[type] as? TypePrototype<T> ?: error("Type prototype is unavailable: ${type.qualifiedName}")

    /**
     * Lists registered concrete descendants in stable type order.
     *
     * Ancestry matching compares nominal identities and follows registered parent prototypes. This method does not
     * perform generic variance checking or full revision compatibility analysis.
     */
    fun concreteImplementationsOf(parent: ResolvedTypeRef): List<ConcreteTypePrototype<*>> =
        concrete
            .filter { prototype -> prototype.definition.isSubtypeOf(parent.id, emptySet()) }
            .sortedBy { it.type.toString() }

    internal fun definition(reference: ResolvedTypeRef): TypeDefinition =
        definitionsByReference[reference.copy(arguments = emptyList())]
            ?: error("Type definition is unavailable: $reference")

    internal fun concrete(reference: ResolvedTypeRef): ConcreteTypePrototype<*> =
        require(reference) as? ConcreteTypePrototype<*>
            ?: error("Type prototype is not concrete: $reference")

    internal fun concrete(runtimeType: KClass<*>): ConcreteTypePrototype<*> =
        byRuntimeType[runtimeType] as? ConcreteTypePrototype<*>
            ?: error("Concrete prototype is unavailable: ${runtimeType.qualifiedName}")

    private fun buildSerializersModule(): SerializersModule =
        SerializersModule {
            all
                .filterIsInstance<AbstractTypePrototype<*>>()
                .forEach { parent -> registerHierarchy(parent) }
        }

    @Suppress("UNCHECKED_CAST")
    private fun kotlinx.serialization.modules.SerializersModuleBuilder.registerHierarchy(parent: AbstractTypePrototype<*>) {
        val parentType = parent.runtimeType as KClass<Any>
        polymorphic(parentType) {
            concreteImplementationsOf(parent.type).forEach { implementation ->
                subclass(
                    implementation.runtimeType as KClass<Any>,
                    implementation.serializer as KSerializer<Any>,
                )
            }
        }
    }

    private fun TypeDefinition.isSubtypeOf(
        target: TypeId,
        visited: Set<TypeId>,
    ): Boolean {
        if (id.id in visited) return false
        if (parents.any { it.id == target }) return true
        val nextVisited = visited + id.id
        return parents.any { reference ->
            byReference[reference.copy(arguments = emptyList())]
                ?.definition
                ?.isSubtypeOf(target, nextVisited) == true
        }
    }
}

/**
 * Supplies abstract dispatch directly from catalog metadata without generating an extra provider class.
 *
 * Encoding requires exactly one matching concrete implementation. Decoding requires a polymorphic envelope whose
 * prototype is both assignable to the runtime class and registered beneath this abstract type.
 */
class CatalogAbstractTypePrototype<T : Any>(
    override val runtimeType: KClass<T>,
    override val type: ResolvedTypeRef,
    override val definition: TypeDefinition,
) : AbstractTypePrototype<T> {
    init {
        require(definition.kind != NominalTypeKind.CONCRETE) { "An abstract prototype requires an abstract definition." }
        require(definition.id == type) { "An abstract prototype definition must match its reference." }
    }

    @Suppress("UNCHECKED_CAST")
    context(prototypes: TypePrototypeRegistry)
    override fun implementations(): List<ConcreteTypePrototype<out T>> =
        prototypes.concreteImplementationsOf(type).map { it as ConcreteTypePrototype<out T> }

    context(
        prototypes: TypePrototypeRegistry,
        encoding: TypeEncodingContext,
    )
    override fun encode(value: T): DataValue {
        val prototype =
            implementations().singleOrNull { it.runtimeType.isInstance(value) }
                ?: error("No unique concrete prototype implements ${runtimeType.qualifiedName} for ${value::class.qualifiedName}.")

        @Suppress("UNCHECKED_CAST")
        val concrete = prototype as ConcreteTypePrototype<T>
        return with(encoding) {
            DataValue.Polymorphic(concrete.type, concrete.encode(value))
        }
    }

    context(
        prototypes: TypePrototypeRegistry,
        decoding: TypeDecodingContext,
    )
    override fun decode(value: DataValue): T {
        require(value is DataValue.Polymorphic) { "Abstract type values must carry their concrete type reference." }
        val prototype = prototypes.require(value.concreteType)
        require(prototype is ConcreteTypePrototype<*>) { "Polymorphic values must reference a concrete prototype." }
        require(runtimeType.java.isAssignableFrom(prototype.runtimeType.java)) {
            "Concrete prototype ${prototype.runtimeType.qualifiedName} does not implement ${runtimeType.qualifiedName}."
        }
        require(prototype in implementations()) {
            "Concrete prototype ${prototype.type} is not registered under $type."
        }
        @Suppress("UNCHECKED_CAST")
        return with(decoding) { (prototype as ConcreteTypePrototype<T>).decode(value.value) }
    }
}

context(prototypes: TypePrototypeRegistry)
val <T : Any> KClass<T>.prototype: TypePrototype<T>
    get() = prototypes.require(this)
