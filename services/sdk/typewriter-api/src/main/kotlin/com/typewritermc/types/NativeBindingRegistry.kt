package com.typewritermc.types

import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.PortableValue
import com.typewritermc.authoring.SamplingInputs
import com.typewritermc.authoring.complete
import com.typewritermc.checking.Diagnostic
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import java.math.BigDecimal
import java.math.BigInteger

interface NativeBinding<T> {
    val provider: NativeBindingId
    val signature: String
    val actualType: TypeUse
    val nativeClass: kotlin.reflect.KClass<*>? get() = null
    val opaque: Boolean get() = false

    fun encode(value: T): DataValue

    fun decode(value: CompleteValue): T
}

interface NativeBindingRegistry {
    fun bind(actual: CheckedType): NativeBinding<*>

    fun defaultedFields(actual: CheckedType): Set<FieldOwner>

    fun defaultedFields(definition: TypeDefinitionId): Set<FieldOwner>

    fun decode(
        value: CompleteValue,
        expected: TypeTemplate,
    ): Any? = bind(value.schema).decode(value)

    fun sampleDefaults(
        actual: CheckedType,
        requiredInputs: SamplingInputs,
    ): CaptureResult
}

class NativeBindingException(
    val code: String,
    message: String,
) : IllegalArgumentException(message)

data class NativeBindingKey(
    val actual: TypeUse.Named,
    val provider: NativeBindingId,
)

sealed interface NativeValidationResult {
    data object Valid : NativeValidationResult

    data class Rejected(
        val findings: List<Diagnostic>,
    ) : NativeValidationResult
}

interface PortableValueStorage {
    suspend fun store(
        key: ResourceId,
        value: PortableValue,
    )

    suspend fun load(key: ResourceId): PortableValue?
}

class FactoryNativeBindingRegistry(
    private val catalog: CheckedCatalog,
    factories: List<NativeBindingFactory>,
) : NativeBindingRegistry {
    private val factoriesByDefinition = factories.groupBy(NativeBindingFactory::definition)
    private val bindings = mutableMapOf<TypeUse, DeferredNativeBinding>()

    override fun bind(actual: CheckedType): NativeBinding<*> {
        if (actual.catalog != catalog.generation) {
            throw NativeBindingException(
                "catalog_generation_mismatch",
                "The checked type belongs to catalog ${actual.catalog.value}, but this registry belongs to ${catalog.generation.value}.",
            )
        }
        return synchronized(bindings) {
            bindings[actual.use] ?: DeferredNativeBinding(actual).also { deferred ->
                bindings[actual.use] = deferred
                try {
                    deferred.initialize(createBinding(actual))
                } catch (failure: Throwable) {
                    bindings.remove(actual.use, deferred)
                    throw failure
                }
            }
        }
    }

    override fun defaultedFields(actual: CheckedType): Set<FieldOwner> {
        requireCurrentCatalog(actual)
        val use = actual.use as? TypeUse.Named ?: return emptySet()
        return defaultedFields(use.definition)
    }

    override fun defaultedFields(definition: TypeDefinitionId): Set<FieldOwner> {
        val candidates = factoriesByDefinition[definition].orEmpty()
        if (candidates.isEmpty()) return emptySet()
        require(candidates.size == 1) {
            "Expected one native binding factory for $definition, found ${candidates.size}."
        }
        return candidates
            .single()
            .constructionPlan
            ?.defaultedFields
            .orEmpty()
    }

    override fun decode(
        value: CompleteValue,
        expected: TypeTemplate,
    ): Any? {
        val expectedUse = expected.concreteFor(value.schema.use)
        if (expectedUse == value.schema.use) return bind(value.schema).decode(value)
        val checked = resolve(expectedUse)
        val authored = value.value
        val portable = if (authored is DataValue.Named) authored.payload else authored
        val complete =
            when (val result = checked.complete(portable)) {
                is CompletenessResult.Complete -> {
                    result.value
                }

                is CompletenessResult.Unfinished -> {
                    throw NativeBindingException("unfinished_native_projection", result.locations.joinToString())
                }

                is CompletenessResult.Invalid -> {
                    throw NativeBindingException("invalid_native_projection", result.problems.joinToString())
                }
            }
        return bind(checked).decode(complete)
    }

    override fun sampleDefaults(
        actual: CheckedType,
        requiredInputs: SamplingInputs,
    ): CaptureResult {
        requireCurrentCatalog(actual)
        val use = actual.use as? TypeUse.Named ?: return CaptureResult.Captured(emptyMap())
        val candidates = factoriesByDefinition[use.definition].orEmpty()
        if (candidates.isEmpty()) return CaptureResult.Captured(emptyMap())
        require(candidates.size == 1) {
            "Expected one native binding factory for ${use.definition}, found ${candidates.size}."
        }
        val plan = candidates.single().constructionPlan ?: return CaptureResult.Captured(emptyMap())
        return plan.sample(appliedArguments(use), requiredInputs)
    }

    private fun requireCurrentCatalog(actual: CheckedType) {
        if (actual.catalog != catalog.generation) {
            throw NativeBindingException(
                "catalog_generation_mismatch",
                "The checked type belongs to catalog ${actual.catalog.value}, but this registry belongs to ${catalog.generation.value}.",
            )
        }
    }

    private fun binding(actual: CheckedType): NativeBinding<*> = bind(actual)

    private fun createBinding(actual: CheckedType): NativeBinding<*> =
        when (val use = actual.use) {
            is TypeUse.Scalar -> {
                ScalarNativeBinding(actual, use)
            }

            is TypeUse.Nullable -> {
                NullableNativeBinding(actual, use, binding(resolve(use.value)))
            }

            is TypeUse.Named -> {
                collectionBinding(actual, use) ?: run {
                    val candidates = factoriesByDefinition[use.definition].orEmpty()
                    if (candidates.isEmpty()) {
                        val record = actual.schema.representation as? ResolvedRepresentation.Record
                        if (record?.abstract == true) {
                            PolymorphicNativeBinding(actual, use, catalog, this)
                        } else {
                            PortableNativeBinding(actual, use)
                        }
                    } else {
                        require(candidates.size == 1) {
                            "Expected one native binding factory for ${use.definition}, found ${candidates.size}."
                        }
                        FactoryCheckedNativeBinding(
                            actual,
                            candidates.single().bind(
                                actual,
                                appliedArguments(use),
                            ),
                        )
                    }
                }
            }
        }

    private fun appliedArguments(use: TypeUse.Named): com.typewritermc.authoring.AppliedNativeArguments =
        com.typewritermc.authoring.AppliedNativeArguments(
            use.arguments,
            use.arguments.map { binding(resolve(it)) },
            NativeBindingResolver { binding(resolve(it)) },
        )

    private fun resolve(use: TypeUse): CheckedType =
        when (val result = catalog.resolve(use)) {
            is Resolution.Ready -> result.value
            is Resolution.Invalid -> throw NativeBindingException("unresolved_native_argument", result.diagnostics.joinToString())
        }

    private fun collectionBinding(
        actual: CheckedType,
        use: TypeUse.Named,
    ): NativeBinding<*>? =
        when (val representation = actual.schema.representation) {
            is ResolvedRepresentation.Sequence -> {
                val item = binding(resolve(representation.item))
                when (representation.kind) {
                    CollectionKind.List -> ListNativeBinding(use, actual, item)
                    CollectionKind.Set -> SetNativeBinding(use, actual, item)
                }
            }

            is ResolvedRepresentation.Mapping -> {
                MapNativeBinding(use, actual, binding(resolve(representation.key)), binding(resolve(representation.value)))
            }

            is ResolvedRepresentation.Link -> {
                LinkNativeBinding(use, actual, representation.endpoint)
            }

            else -> {
                null
            }
        }
}

private fun TypeTemplate.concreteFor(actual: TypeUse): TypeUse =
    when (this) {
        is TypeTemplate.Parameter -> {
            actual
        }

        is TypeTemplate.Scalar -> {
            TypeUse.Scalar(kind)
        }

        is TypeTemplate.Nullable -> {
            if (actual is TypeUse.Nullable) {
                TypeUse.Nullable(
                    value.concreteFor(actual.value),
                )
            } else {
                TypeUse.Nullable(value.concreteFor(actual))
            }
        }

        is TypeTemplate.Named -> {
            val named = actual as? TypeUse.Named
            if (named?.definition == definition && named.arguments.size == arguments.size) {
                TypeUse.Named(definition, arguments.zip(named.arguments).map { (template, argument) -> template.concreteFor(argument) })
            } else {
                actual
            }
        }
    }

private class DeferredNativeBinding(
    override val checked: CheckedType,
) : NativeBinding<Any?>,
    GeneratedCheckedNativeBinding,
    AuthoredNativeBinding {
    private var delegate: NativeBinding<*>? = null

    override val provider: NativeBindingId
        get() = requireDelegate().provider
    override val signature: String
        get() = delegate?.signature ?: checked.use.toString()
    override val actualType: TypeUse
        get() = checked.use
    override val nativeClass: kotlin.reflect.KClass<*>?
        get() = delegate?.nativeClass
    override val opaque: Boolean
        get() = delegate?.opaque ?: false

    fun initialize(binding: NativeBinding<*>) {
        check(delegate == null) { "A native binding can only be initialized once." }
        delegate = binding
    }

    override fun encode(value: Any?): DataValue = requireDelegate().encodeAny(value)

    override fun decode(value: CompleteValue): Any? = requireDelegate().decodeAny(value)

    override fun decodeAuthored(value: DataValue): Any? = requireDelegate().decodeAuthoredAny(value)

    private fun requireDelegate(): NativeBinding<*> =
        delegate
            ?: throw NativeBindingException(
                "recursive_native_binding_initialization",
                "A recursive native binding was used before initialization completed.",
            )
}

private val FRAMEWORK_NATIVE_BINDING = NativeBindingId("typewriter.framework")

private class PortableNativeBinding(
    override val checked: CheckedType,
    override val actualType: TypeUse.Named,
) : NativeBinding<PortableValue>,
    GeneratedCheckedNativeBinding {
    override val provider: NativeBindingId = NativeBindingId("typewriter.portable")
    override val signature: String = "portable($actualType)"
    override val opaque: Boolean = true

    override fun encode(value: PortableValue): DataValue {
        if (value.actualType != actualType) {
            throw NativeBindingException("wrong_portable_actual_type", "The portable value type does not match its native binding.")
        }
        return DataValue.Named(actualType, value.payload)
    }

    override fun decode(value: CompleteValue): PortableValue = PortableValue(actualType, value.payload<DataValue>())
}

private class PolymorphicNativeBinding(
    override val checked: CheckedType,
    override val actualType: TypeUse.Named,
    private val catalog: CheckedCatalog,
    private val registry: FactoryNativeBindingRegistry,
) : NativeBinding<Any>,
    GeneratedCheckedNativeBinding,
    AuthoredNativeBinding {
    override val provider: NativeBindingId = NativeBindingId("typewriter.polymorphic")
    override val signature: String = "polymorphic($actualType)"

    override fun encode(value: Any): DataValue {
        val candidates =
            catalog
                .concreteForms(checked)
                .map { concrete -> concrete to registry.bind(concrete) }
                .filter { (_, binding) -> binding.nativeClass?.isInstance(value) == true }
        if (candidates.size != 1) {
            throw NativeBindingException(
                "ambiguous_polymorphic_native_type",
                "Expected one concrete native binding for ${value::class.qualifiedName}, found ${candidates.size}.",
            )
        }
        @Suppress("UNCHECKED_CAST")
        return (candidates.single().second as NativeBinding<Any>).encode(value)
    }

    override fun decode(value: CompleteValue): Any = decodeAuthored(value.value)

    override fun decodeAuthored(value: DataValue): Any {
        val named =
            value as? DataValue.Named
                ?: throw NativeBindingException("missing_polymorphic_type_tag", "A polymorphic value requires its concrete named type.")
        if (!catalog.isReadableAs(named.actualType, actualType)) {
            throw NativeBindingException("unreadable_polymorphic_type", "The concrete value is not readable as its declared type.")
        }
        val concrete =
            when (val resolution = catalog.resolve(named.actualType)) {
                is Resolution.Ready -> {
                    resolution.value
                }

                is Resolution.Invalid -> {
                    throw NativeBindingException("unresolved_polymorphic_type", resolution.diagnostics.joinToString())
                }
            }
        val complete =
            when (val result = concrete.complete(named)) {
                is CompletenessResult.Complete -> {
                    result.value
                }

                is CompletenessResult.Unfinished -> {
                    throw NativeBindingException("unfinished_polymorphic_value", result.locations.joinToString())
                }

                is CompletenessResult.Invalid -> {
                    throw NativeBindingException("invalid_polymorphic_value", result.problems.joinToString())
                }
            }
        return registry.bind(concrete).decodeAny(complete) as Any
    }
}

private typealias CheckedNativeBinding = GeneratedCheckedNativeBinding

private class FactoryCheckedNativeBinding(
    override val checked: CheckedType,
    private val delegate: NativeBinding<*>,
) : NativeBinding<Any?>,
    CheckedNativeBinding {
    override val provider: NativeBindingId get() = delegate.provider
    override val signature: String get() = delegate.signature
    override val actualType: TypeUse get() = delegate.actualType
    override val nativeClass: kotlin.reflect.KClass<*>? get() = delegate.nativeClass
    override val opaque: Boolean get() = delegate.opaque

    override fun encode(value: Any?): DataValue = delegate.encodeAny(value)

    override fun decode(value: CompleteValue): Any? = delegate.decodeAny(value)
}

private class ScalarNativeBinding(
    override val checked: CheckedType,
    override val actualType: TypeUse.Scalar,
) : NativeBinding<Any?>,
    CheckedNativeBinding {
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    override val signature: String = actualType.toString()

    override fun encode(value: Any?): DataValue =
        when (val kind = actualType.kind) {
            ScalarKind.Unit -> {
                DataValue.Unit
            }

            ScalarKind.Boolean -> {
                DataValue.Boolean(value as Boolean)
            }

            ScalarKind.Text -> {
                DataValue.StringValue(value as String)
            }

            ScalarKind.Bytes -> {
                DataValue.Bytes(value as ByteArray)
            }

            is ScalarKind.Integer -> {
                DataValue.Integer(value.toBigInteger(kind.width))
            }

            is ScalarKind.Float -> {
                when (kind.width) {
                    FloatWidth.FLOAT_32 -> {
                        val number =
                            value as? Float
                                ?: throw NativeBindingException("wrong_native_float", "Float32 requires a Kotlin Float value.")
                        DataValue.Float(number.toDouble())
                    }

                    FloatWidth.FLOAT_64 -> {
                        val number =
                            value as? Double
                                ?: throw NativeBindingException("wrong_native_float", "Float64 requires a Kotlin Double value.")
                        DataValue.Float(number)
                    }
                }
            }

            ScalarKind.Decimal -> {
                DataValue.Decimal((value as BigDecimal).toPlainString())
            }

            ScalarKind.Timestamp -> {
                DataValue.Timestamp(value as kotlin.time.Instant)
            }

            ScalarKind.Duration -> {
                DataValue.Duration(value as kotlin.time.Duration)
            }
        }

    override fun decode(value: CompleteValue): Any? =
        when (val kind = actualType.kind) {
            ScalarKind.Unit -> {
                Unit
            }

            ScalarKind.Boolean -> {
                (value.value as DataValue.Boolean).value
            }

            ScalarKind.Text -> {
                (value.value as DataValue.StringValue).value
            }

            ScalarKind.Bytes -> {
                (value.value as DataValue.Bytes).toByteArray()
            }

            is ScalarKind.Integer -> {
                (value.value as DataValue.Integer).value.toNativeInteger(kind.width)
            }

            is ScalarKind.Float -> {
                val number = (value.value as DataValue.Float).value
                if (kind.width == FloatWidth.FLOAT_32) {
                    val narrowed = number.toFloat()
                    if (!narrowed.isFinite()) throw NativeBindingException("float32_out_of_range", "Float32 value is out of range.")
                    if (narrowed.toDouble() != number) {
                        throw NativeBindingException(
                            "float32_precision_loss",
                            "Float32 cannot represent the authored value exactly.",
                        )
                    }
                    narrowed
                } else {
                    number
                }
            }

            ScalarKind.Decimal -> {
                BigDecimal((value.value as DataValue.Decimal).value)
            }

            ScalarKind.Timestamp -> {
                (value.value as DataValue.Timestamp).value
            }

            ScalarKind.Duration -> {
                (value.value as DataValue.Duration).value
            }
        }
}

private class NullableNativeBinding(
    override val checked: CheckedType,
    override val actualType: TypeUse.Nullable,
    private val inner: NativeBinding<*>,
) : NativeBinding<Any?>,
    CheckedNativeBinding {
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    override val signature: String get() = "nullable(${inner.signature})"

    override fun encode(value: Any?): DataValue = if (value == null) DataValue.Null else inner.encodeAny(value)

    override fun decode(value: CompleteValue): Any? = if (value.value == DataValue.Null) null else inner.decodeAuthoredAny(value.value)
}

private class ListNativeBinding(
    override val actualType: TypeUse.Named,
    override val checked: CheckedType,
    private val item: NativeBinding<*>,
) : NativeBinding<List<*>>,
    CheckedNativeBinding {
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    override val signature: String get() = "list(${item.signature})"

    override fun encode(value: List<*>): DataValue =
        DataValue.Named(
            actualType,
            DataValue.ListValue(
                value.mapIndexed {
                    index,
                    element,
                    ->
                    com.typewritermc.types.ListItem(generatedItemId(index), item.encodeAny(element))
                },
            ),
        )

    override fun decode(value: CompleteValue): List<*> = value.payload<DataValue.ListValue>().items.map { item.decodeAuthoredAny(it.value) }
}

private class SetNativeBinding(
    override val actualType: TypeUse.Named,
    override val checked: CheckedType,
    private val item: NativeBinding<*>,
) : NativeBinding<Set<*>>,
    CheckedNativeBinding {
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    override val signature: String get() = "set(${item.signature})"

    override fun encode(value: Set<*>): DataValue =
        DataValue.Named(
            actualType,
            DataValue.SetValue(
                value.mapIndexed {
                    index,
                    element,
                    ->
                    com.typewritermc.types.ListItem(generatedItemId(index), item.encodeAny(element))
                },
            ),
        )

    override fun decode(value: CompleteValue): Set<*> {
        val authored = value.payload<DataValue.SetValue>().items.map { it.value }
        if (authored.map(DataValue::canonicalValueKey).distinct().size != authored.size) {
            throw NativeBindingException("duplicate_set_value", "A native Set cannot preserve duplicate authored values.")
        }
        val decoded = authored.map(item::decodeAuthoredAny)
        if (decoded.distinct().size != decoded.size) {
            throw NativeBindingException("duplicate_set_value", "A native Set cannot preserve duplicate authored values.")
        }
        return decoded.toSet()
    }
}

private class MapNativeBinding(
    override val actualType: TypeUse.Named,
    override val checked: CheckedType,
    private val key: NativeBinding<*>,
    private val value: NativeBinding<*>,
) : NativeBinding<Map<*, *>>,
    CheckedNativeBinding {
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    override val signature: String get() = "map(${key.signature},${value.signature})"

    override fun encode(value: Map<*, *>): DataValue =
        DataValue.Named(
            actualType,
            DataValue.MapValue(
                value.entries.mapIndexed { index, entry ->
                    MapRow(generatedItemId(index), key.encodeAny(entry.key), this.value.encodeAny(entry.value))
                },
            ),
        )

    override fun decode(value: CompleteValue): Map<*, *> {
        val authored = value.payload<DataValue.MapValue>().rows
        if (authored.map { it.key.canonicalValueKey() }.distinct().size != authored.size) {
            throw NativeBindingException("duplicate_map_key", "A native Map cannot preserve duplicate authored keys.")
        }
        val rows =
            authored.map { row ->
                key.decodeAuthoredAny(row.key) to this.value.decodeAuthoredAny(row.value)
            }
        if (rows.map(Pair<*, *>::first).distinct().size != rows.size) {
            throw NativeBindingException("duplicate_map_key", "A native Map cannot preserve duplicate authored keys.")
        }
        return rows.toMap()
    }
}

private class LinkNativeBinding(
    override val actualType: TypeUse.Named,
    override val checked: CheckedType,
    private val endpoint: EndpointId,
) : NativeBinding<Ref<*, *>>,
    CheckedNativeBinding {
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    override val signature: String = "link(${endpoint.value})"

    override fun encode(value: Ref<*, *>): DataValue =
        DataValue.Named(
            actualType,
            DataValue.Link(endpoint, LinkTarget(value.target, value.opposite)),
        )

    override fun decode(value: CompleteValue): Ref<*, *> {
        val link = value.payload<DataValue.Link>()
        if (link.endpoint != endpoint) {
            throw NativeBindingException("wrong_link_endpoint", "The authored link endpoint does not match its native binding.")
        }
        return Ref<RelationshipEndpoint<Resource, Resource>, Resource>(link.target.resource, link.target.opposite)
    }
}

private fun NativeBinding<*>.encodeAny(value: Any?): DataValue {
    @Suppress("UNCHECKED_CAST")
    return (this as NativeBinding<Any?>).encode(value)
}

private fun NativeBinding<*>.decodeAny(value: CompleteValue): Any? = decode(value)

private fun NativeBinding<*>.decodeAuthoredAny(value: DataValue): Any? =
    if (this is AuthoredNativeBinding) decodeAuthored(value) else decodeAny(complete(this, value))

private fun complete(
    binding: NativeBinding<*>,
    value: DataValue,
): CompleteValue {
    val checked =
        (binding as? CheckedNativeBinding)?.checked
            ?: throw NativeBindingException("nested_binding_schema_unavailable", "The nested native binding has no checked schema.")
    return checked.complete(value).requireComplete()
}

private fun CompletenessResult.requireComplete(): CompleteValue =
    when (this) {
        is CompletenessResult.Complete -> value
        is CompletenessResult.Unfinished -> throw NativeBindingException("unfinished_native_value", locations.joinToString())
        is CompletenessResult.Invalid -> throw NativeBindingException("invalid_native_value", problems.joinToString())
    }

private inline fun <reified T : DataValue> CompleteValue.payload(): T {
    val payload = (value as? DataValue.Named)?.payload ?: value
    return payload as? T ?: throw NativeBindingException("wrong_native_representation", "Expected ${T::class.simpleName}.")
}

private fun Any?.toBigInteger(width: IntegerWidth): BigInteger =
    when (this) {
        is Byte -> BigInteger.valueOf(toLong())
        is Short -> BigInteger.valueOf(toLong())
        is Int -> BigInteger.valueOf(toLong())
        is Long -> BigInteger.valueOf(this)
        is UByte -> BigInteger.valueOf(toLong())
        is UShort -> BigInteger.valueOf(toLong())
        is UInt -> BigInteger(toString())
        is ULong -> BigInteger(toString())
        is BigInteger -> this
        else -> throw NativeBindingException("wrong_native_integer", "Unsupported ${width.name} native integer value.")
    }

private fun BigInteger.toNativeInteger(width: IntegerWidth): Any =
    when (width) {
        IntegerWidth.SIGNED_8 -> toByte()
        IntegerWidth.SIGNED_16 -> toShort()
        IntegerWidth.SIGNED_32 -> toInt()
        IntegerWidth.SIGNED_64 -> toLong()
        IntegerWidth.UNSIGNED_8 -> toInt().toUByte()
        IntegerWidth.UNSIGNED_16 -> toInt().toUShort()
        IntegerWidth.UNSIGNED_32 -> toLong().toUInt()
        IntegerWidth.UNSIGNED_64 -> toString().toULong()
    }

private fun generatedItemId(index: Int): com.typewritermc.authoring.ItemId = com.typewritermc.authoring.ItemId("native:$index")
