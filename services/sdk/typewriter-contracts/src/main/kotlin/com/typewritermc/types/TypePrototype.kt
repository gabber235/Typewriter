@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types

import kotlinx.serialization.KSerializer
import kotlinx.serialization.modules.SerializersModule
import kotlinx.serialization.modules.polymorphic
import kotlinx.serialization.modules.subclass
import java.math.BigInteger
import kotlin.reflect.KClass
import kotlin.time.Duration
import kotlin.time.Instant

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
            require(definitionsByReference[prototype.type] == prototype.definition) {
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

    /** Completes a partial concrete value by executing its Kotlin serializer defaults. */
    fun initialize(
        root: ResolvedTypeRef,
        partial: DataValue,
    ): TypedValueEnvelope {
        val prototype =
            require(root) as? ConcreteTypePrototype<*>
                ?: error("Typed value initialization requires a concrete prototype: $root")
        val decoding =
            object : TypeDecodingContext {
                override val prototypes: TypePrototypeRegistry = this@TypePrototypeRegistry
            }
        val materialized = DraftValueMaterializer(this).materialize(TypeExpression.Named(root), partial)
        val value = with(decoding) { prototype.decode(materialized) }
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

/** Builds a decodable value while leaving constructor default fields absent. */
private class DraftValueMaterializer(
    private val prototypes: TypePrototypeRegistry,
) {
    fun materialize(
        type: TypeExpression,
        partial: DataValue? = null,
    ): DataValue {
        val resolved = prototypes.dataFormat.materialize(type)
        return when (resolved) {
            TypeExpression.Any -> {
                partial ?: DataValue.Unit
            }

            TypeExpression.Unit -> {
                partial ?: DataValue.Unit
            }

            TypeExpression.Boolean -> {
                partial ?: DataValue.Boolean(false)
            }

            is TypeExpression.StringType -> {
                partial ?: DataValue.StringValue(resolved.allowedValues.firstOrNull().orEmpty())
            }

            is TypeExpression.Bytes -> {
                partial ?: DataValue.Bytes(byteArrayOf())
            }

            is TypeExpression.Integer -> {
                partial ?: DataValue.Integer(integerBaseline(resolved))
            }

            is TypeExpression.Float -> {
                partial ?: DataValue.Float(floatBaseline(resolved))
            }

            is TypeExpression.Decimal -> {
                partial ?: DataValue.Decimal(resolved.minimum ?: resolved.maximum ?: "0")
            }

            is TypeExpression.Timestamp -> {
                partial
                    ?: DataValue.Timestamp(resolved.minimum ?: resolved.maximum ?: Instant.fromEpochMilliseconds(0))
            }

            is TypeExpression.Duration -> {
                partial ?: DataValue.Duration(resolved.minimum ?: resolved.maximum ?: Duration.ZERO)
            }

            is TypeExpression.Enumeration -> {
                partial ?: resolved.values.first()
            }

            is TypeExpression.ListType -> {
                val values = (partial as? DataValue.ListValue)?.values.orEmpty()
                DataValue.ListValue(values.map { materialize(resolved.element, it) })
            }

            is TypeExpression.MapType -> {
                val entries = (partial as? DataValue.MapValue)?.entries.orEmpty()
                DataValue.MapValue(
                    entries.map { entry ->
                        DataMapEntry(
                            materialize(resolved.key, entry.key),
                            materialize(resolved.value, entry.value),
                        )
                    },
                )
            }

            is TypeExpression.Record -> {
                materializeRecord(resolved, partial)
            }

            is TypeExpression.Named -> {
                materializeAbstract(resolved, partial)
            }

            is TypeExpression.Reference -> {
                partial ?: DataValue.Reference(ResourceId("new"))
            }

            is TypeExpression.Parameter -> {
                error("Unresolved type parameter ${resolved.name} cannot be materialized.")
            }
        }
    }

    private fun materializeRecord(
        type: TypeExpression.Record,
        partial: DataValue?,
    ): DataValue.Record {
        val supplied = (partial as? DataValue.Record)?.fields.orEmpty()
        val known = type.fields.mapTo(hashSetOf(), TypeField::name)
        require(supplied.keys.all { it in known }) { "Partial value contains fields outside its declared record." }
        return DataValue.Record(
            buildMap {
                type.fields.forEach { field ->
                    when {
                        field.name in supplied -> put(field.name, materialize(field.type, supplied.getValue(field.name)))
                        field.initialValue != null -> put(field.name, materialize(field.type, field.initialValue))
                        field.defaulted -> Unit
                        else -> put(field.name, materialize(field.type))
                    }
                }
            },
        )
    }

    private fun materializeAbstract(
        type: TypeExpression.Named,
        partial: DataValue?,
    ): DataValue {
        if (type.reference.id == TypeId.Option) {
            return partial ?: noneValue(type.reference.arguments.single())
        }
        val polymorphic =
            partial as? DataValue.Polymorphic
                ?: error("Abstract type ${type.reference} requires a concrete value.")
        return polymorphic.copy(
            value = materialize(TypeExpression.Named(polymorphic.concreteType), polymorphic.value),
        )
    }

    private fun integerBaseline(type: TypeExpression.Integer): BigInteger {
        val zero = BigInteger.ZERO
        return when {
            type.minimum != null && zero < type.minimum -> type.minimum
            type.maximum != null && zero > type.maximum -> type.maximum
            else -> zero
        }
    }

    private fun floatBaseline(type: TypeExpression.Float): Double =
        when {
            type.minimum != null && 0.0 < type.minimum -> type.minimum
            type.maximum != null && 0.0 > type.maximum -> type.maximum
            else -> 0.0
        }
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
