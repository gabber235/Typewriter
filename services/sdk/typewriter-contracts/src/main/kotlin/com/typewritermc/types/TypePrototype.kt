@file:OptIn(kotlin.time.ExperimentalTime::class)

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

/** Supplies field and type metadata for a catalog type that is never encoded as a root value. */
class CatalogMetadataTypePrototype<T : Any>(
    override val runtimeType: KClass<T>,
    override val type: ResolvedTypeRef,
    override val definition: TypeDefinition,
    override val serializedFieldNames: Map<String, String> = emptyMap(),
) : TypePrototype<T> {
    init {
        require(definition.id == type) { "A metadata prototype definition must match its reference." }
    }
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

/** Why concrete value initialization cannot yet construct a complete value. */
enum class TypeInitializationRequirementReason {
    MISSING_VALUE,
    CONCRETE_TYPE_REQUIRED,
}

/** One explicit caller obligation discovered while planning concrete value initialization. */
data class TypeInitializationRequirement(
    val path: DataPath,
    val expected: TypeExpression,
    val reason: TypeInitializationRequirementReason,
)

/**
 * Result of planning one concrete value initialization.
 *
 * [Ready] contains a value that can be decoded through the concrete serializer. [NeedsInput] retains the canonical
 * partial value while identifying every unresolved path. Constructor default fields remain absent from both results
 * so the serializer remains their only owner.
 */
sealed interface TypeInitializationPlan {
    data class Ready(
        val supplied: DataValue,
    ) : TypeInitializationPlan

    data class NeedsInput(
        val supplied: DataValue?,
        val requirements: List<TypeInitializationRequirement>,
    ) : TypeInitializationPlan {
        init {
            require(requirements.isNotEmpty()) { "Incomplete initialization must contain at least one requirement." }
        }
    }
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
    private val definitions = definitions.toList()

    init {
        require(byReference.size == all.size) { "Type prototype references must be unique." }
        require(byRuntimeType.size == all.size) {
            val collisions =
                all
                    .groupBy(TypePrototype<*>::runtimeType)
                    .filterValues { prototypes -> prototypes.size > 1 }
                    .entries
                    .sortedBy { (runtimeType) -> runtimeType.qualifiedName }
                    .joinToString("; ") { (runtimeType, prototypes) ->
                        "${runtimeType.qualifiedName}: ${prototypes.joinToString { it.type.toString() }}"
                    }
            "Type prototype runtime classes must be unique: $collisions"
        }
        require(definitionsByReference.size == definitions.size) { "Type definitions must be unique." }
        all.forEach { prototype ->
            require(definitionsByReference[prototype.type]?.copy(displayName = prototype.definition.displayName, qualifiedName = prototype.definition.qualifiedName) == prototype.definition) {
                "Type prototype ${prototype.type} must match its catalog definition."
            }
        }
    }

    val serializersModule: SerializersModule = buildSerializersModule()

    val dataFormat: TypewriterDataFormat = TypewriterDataFormat(serializersModule, this)

    /** Returns the complete structural graph needed to project one registered root value. */
    fun graph(root: ResolvedTypeRef): TypeGraph {
        require(root.copy(arguments = emptyList()) in definitionsByReference) { "Unknown type graph root $root." }
        return TypeGraph(TypeExpression.Named(root), definitions)
    }

    /** Encodes one concrete runtime value with its exact catalog type for typed authoring transport. */
    @Suppress("UNCHECKED_CAST")
    fun <T : Any> encode(value: T): TypedValueEnvelope {
        val prototype =
            require(value::class as KClass<T>) as? ConcreteTypePrototype<T>
                ?: error("Typed values require a concrete prototype: ${value::class.qualifiedName}")
        val context =
            object : TypeEncodingContext {
                override val prototypes: TypePrototypeRegistry = this@TypePrototypeRegistry
            }
        return TypedValueEnvelope(
            rootType = TypeExpression.Named(prototype.type),
            rootValue = with(context) { prototype.encode(value) },
        )
    }

    /** Decodes an envelope through the exact concrete prototype named by its root type. */
    fun decode(value: TypedValueEnvelope): Any {
        val reference =
            (value.rootType as? TypeExpression.Named)?.reference
                ?: error("Typed value envelopes require a named root type.")
        val prototype =
            require(reference) as? ConcreteTypePrototype<*>
                ?: error("Typed value envelopes require a concrete prototype: $reference")
        val context =
            object : TypeDecodingContext {
                override val prototypes: TypePrototypeRegistry = this@TypePrototypeRegistry
            }
        return with(context) { prototype.decode(value.rootValue) }
    }

    /** Decodes a concrete envelope and verifies its expected runtime supertype. */
    fun <T : Any> decodeAs(
        value: TypedValueEnvelope,
        expected: KClass<T>,
    ): T {
        val decoded = decode(value)
        require(expected.isInstance(decoded)) {
            "Typed value ${value.rootType} is not assignable to ${expected.qualifiedName}."
        }
        @Suppress("UNCHECKED_CAST")
        return decoded as T
    }

    /** Decodes a concrete envelope and verifies its reified runtime supertype. */
    inline fun <reified T : Any> decodeAs(value: TypedValueEnvelope): T = decodeAs(value, T::class)

    /**
     * Plans initialization for an exact concrete type using declared type and field initial values.
     *
     * Supplied values and declared editor initial values are preserved. Constructor default fields remain absent
     * until [initializeConcrete] decodes the ready plan.
     */
    fun planInitialization(
        root: ResolvedTypeRef,
        supplied: DataValue?,
    ): TypeInitializationPlan {
        require(require(root) is ConcreteTypePrototype<*>) {
            "Typed value initialization requires a concrete prototype: $root"
        }
        return ConcreteInitializationPlanner(this).plan(root, supplied)
    }

    /** Executes the concrete serializer after every initialization requirement has been supplied. */
    fun initializeConcrete(
        root: ResolvedTypeRef,
        supplied: DataValue,
    ): TypedValueEnvelope {
        val prototype = concrete(root)
        val plan = planInitialization(root, supplied)
        require(plan is TypeInitializationPlan.Ready) {
            val requirements = (plan as TypeInitializationPlan.NeedsInput).requirements.joinToString { it.path.toString() }
            "Typed value initialization still requires input at $requirements."
        }
        val decoding =
            object : TypeDecodingContext {
                override val prototypes: TypePrototypeRegistry = this@TypePrototypeRegistry
            }
        val value = with(decoding) { prototype.decode(plan.supplied) }
        val encoding =
            object : TypeEncodingContext {
                override val prototypes: TypePrototypeRegistry = this@TypePrototypeRegistry
            }
        return TypedValueEnvelope(
            rootType = TypeExpression.Named(root),
            rootValue = with(encoding) { encodeInitialized(prototype, value) },
        )
    }

    @Suppress("UNCHECKED_CAST")
    context(context: TypeEncodingContext)
    private fun encodeInitialized(
        prototype: ConcreteTypePrototype<*>,
        value: Any,
    ): DataValue = (prototype as ConcreteTypePrototype<Any>).encode(value)

    /** Builds the complete structural graph needed to validate edits to an encoded root. */
    fun graph(root: TypeExpression): TypeGraph = TypeGraph(root, definitions)

    init {
        concrete.forEach { prototype ->
            dataFormat.validate(
                descriptor = prototype.serializer.descriptor,
                type = prototype.definition.representation,
                path = prototype.type.toString(),
            )
        }
    }

    /** Finds the prototype for an exact resolved reference or fails when the deployment lacks it. */
    fun require(reference: ResolvedTypeRef): TypePrototype<*> = byReference[reference] ?: error("Type prototype is unavailable: $reference")

    /** Finds the prototype registered for a runtime class or fails when it is unavailable. */
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
            .filter { prototype -> prototype.definition.isPotentialSubtypeOf(parent, emptySet()) }
            .sortedBy { it.type.toString() }

    internal fun definition(reference: ResolvedTypeRef): TypeDefinition =
        definitionsByReference[reference.copy(arguments = emptyList())]
            ?: error("Type definition is unavailable: $reference")

    internal fun isConcreteSubtypeOf(
        candidate: ResolvedTypeRef,
        parent: ResolvedTypeRef,
    ): Boolean {
        val definition = definition(candidate)
        return definition.kind == NominalTypeKind.CONCRETE &&
            definition.isExactSubtypeOf(candidate, parent, emptySet())
    }

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

    private fun TypeDefinition.isPotentialSubtypeOf(
        target: ResolvedTypeRef,
        visited: Set<ResolvedTypeRef>,
    ): Boolean {
        if (id in visited) return false
        if (parents.any { it.matchesPattern(target) }) return true
        val nextVisited = visited + id
        return parents.any { reference ->
            byReference[reference.copy(arguments = emptyList())]
                ?.definition
                ?.isPotentialSubtypeOf(target, nextVisited) == true
        }
    }

    private fun TypeDefinition.isExactSubtypeOf(
        current: ResolvedTypeRef,
        target: ResolvedTypeRef,
        visited: Set<ResolvedTypeRef>,
    ): Boolean {
        if (current in visited) return false
        val bindings =
            parameters
                .mapIndexedNotNull { index, parameter ->
                    current.arguments.getOrNull(index)?.let { parameter.name to it }
                }.toMap()
        val resolvedParents = parents.map { it.resolveTypeBindings(bindings) }
        if (target in resolvedParents) return true
        val nextVisited = visited + current
        return resolvedParents.any { reference ->
            byReference[reference.copy(arguments = emptyList())]
                ?.definition
                ?.isExactSubtypeOf(reference, target, nextVisited) == true
        }
    }
}

private fun ResolvedTypeRef.matchesPattern(target: ResolvedTypeRef): Boolean =
    id == target.id &&
        revision == target.revision &&
        arguments.size == target.arguments.size &&
        arguments.zip(target.arguments).all { (pattern, value) ->
            pattern is TypeExpression.Parameter || pattern == value
        }

/**
 * Supplies abstract dispatch directly from catalog metadata without generating an extra provider class.
 *
 * Encoding requires exactly one matching concrete implementation. Decoding requires a polymorphic envelope whose
 * prototype is both assignable to the runtime class and registered beneath this abstract type.
 */
open class CatalogAbstractTypePrototype<T : Any>(
    override val runtimeType: KClass<T>,
    override val type: ResolvedTypeRef,
    override val definition: TypeDefinition,
    override val serializedFieldNames: Map<String, String> = emptyMap(),
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

/** Resolves this runtime class through the active prototype registry. */
context(prototypes: TypePrototypeRegistry)
val <T : Any> KClass<T>.prototype: TypePrototype<T>
    get() = prototypes.require(this)
