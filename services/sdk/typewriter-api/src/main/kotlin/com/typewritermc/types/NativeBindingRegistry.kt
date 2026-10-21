package com.typewritermc.types

import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.PortableValue
import com.typewritermc.authoring.complete
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
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
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult
}

class NativeBindingException(
    val code: String,
    message: String,
) : IllegalArgumentException(message)

sealed interface NativeValidationResult {
    data object Valid : NativeValidationResult

    data class Rejected(
        val findings: List<Diagnostic>,
    ) : NativeValidationResult
}

/**
 * Owns native bindings for one checked catalog, combining generated factories with framework representations.
 *
 * Bindings are cached by concrete type and reject checked types from another generation. Deferred bindings allow
 * recursive record factories to refer to themselves during construction, but fail if used before initialization.
 * Nullable and container child bindings resolve only when a value or signature needs them.
 * Concrete definitions without a native factory retain [PortableValue] content; abstract records dispatch through
 * the actual authored type. Native sets and maps reject duplicates that their Kotlin containers would discard.
 */
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
        val use = actual.use as? TypeUse.NamedWrapper ?: return emptySet()
        return defaultedFields(use.value.definition)
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
        val portable = if (authored is DataValue.NamedWrapper) authored.payload else authored
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
        supplied: Map<FieldOwner, CompleteValue>,
    ): CaptureResult {
        requireCurrentCatalog(actual)
        val use = actual.use as? TypeUse.NamedWrapper ?: return CaptureResult.Captured(emptyMap())
        val candidates = factoriesByDefinition[use.value.definition].orEmpty()
        if (candidates.isEmpty()) return CaptureResult.Captured(emptyMap())
        require(candidates.size == 1) {
            "Expected one native binding factory for ${use.value.definition}, found ${candidates.size}."
        }
        val plan = candidates.single().constructionPlan ?: return CaptureResult.Captured(emptyMap())
        return plan.sample(appliedArguments(use.value), supplied)
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
            is TypeUse.ScalarWrapper -> {
                ScalarNativeBinding(actual, use)
            }

            is TypeUse.NullableWrapper -> {
                NullableNativeBinding(actual, use) { binding(resolve(use.value.value)) }
            }

            is TypeUse.NamedWrapper -> {
                collectionBinding(actual, use.value) ?: run {
                    val candidates = factoriesByDefinition[use.value.definition].orEmpty()
                    if (candidates.isEmpty()) {
                        val record = actual.schema.representation as? ResolvedRepresentation.RecordWrapper
                        if (record?.value?.abstract_ == true) {
                            PolymorphicNativeBinding(actual, use.value, catalog, this)
                        } else {
                            PortableNativeBinding(actual, use.value)
                        }
                    } else {
                        require(candidates.size == 1) {
                            "Expected one native binding factory for ${use.value.definition}, found ${candidates.size}."
                        }
                        FactoryCheckedNativeBinding(
                            actual,
                            candidates.single().bind(
                                actual,
                                appliedArguments(use.value),
                            ),
                        )
                    }
                }
            }

            else -> {
                unknownVariant(use)
            }
        }

    private fun appliedArguments(use: NamedTypeUse): com.typewritermc.authoring.AppliedNativeArguments =
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
        use: NamedTypeUse,
    ): NativeBinding<*>? =
        when (val representation = actual.schema.representation) {
            is ResolvedRepresentation.SequenceWrapper -> {
                when (representation.value.kind) {
                    CollectionKind.LIST -> ListNativeBinding(use, actual) { binding(resolve(representation.value.item)) }
                    CollectionKind.SET -> SetNativeBinding(use, actual) { binding(resolve(representation.value.item)) }
                    else -> unknownVariant(representation.value.kind)
                }
            }

            is ResolvedRepresentation.MappingWrapper -> {
                MapNativeBinding(
                    use,
                    actual,
                    resolveKey = { binding(resolve(representation.value.key)) },
                    resolveValue = { binding(resolve(representation.value.value)) },
                )
            }

            is ResolvedRepresentation.LinkWrapper -> {
                LinkNativeBinding(use, actual, representation.value.endpoint)
            }

            else -> {
                null
            }
        }
}

private fun TypeTemplate.concreteFor(actual: TypeUse): TypeUse =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            actual
        }

        is TypeTemplate.ScalarWrapper -> {
            value.use
        }

        is TypeTemplate.NullableWrapper -> {
            if (actual is TypeUse.NullableWrapper) {
                value.value.concreteFor(actual.value.value).nullable()
            } else {
                value.value.concreteFor(actual).nullable()
            }
        }

        is TypeTemplate.NamedWrapper -> {
            val named = actual as? TypeUse.NamedWrapper
            if (named?.value?.definition == value.definition && named.value.arguments.size == value.arguments.size) {
                value.definition.use(
                    value.arguments.zip(named.value.arguments).map { (template, argument) ->
                        template.concreteFor(argument)
                    },
                )
            } else {
                actual
            }
        }

        else -> {
            unknownVariant(this)
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
        get() = delegate?.signature ?: checked.use.canonicalText
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
    private val application: NamedTypeUse,
) : NativeBinding<PortableValue>,
    GeneratedCheckedNativeBinding {
    override val actualType: TypeUse = application.use
    override val provider: NativeBindingId = NativeBindingId("typewriter.portable")
    override val signature: String = "portable(${actualType.canonicalText})"
    override val opaque: Boolean = true

    override fun encode(value: PortableValue): DataValue {
        if (value.actualType != actualType) {
            throw NativeBindingException("wrong_portable_actual_type", "The portable value type does not match its native binding.")
        }
        return DataValue.named(application, value.payload)
    }

    override fun decode(value: CompleteValue): PortableValue = PortableValue(actualType, value.payload<DataValue>())
}

private class PolymorphicNativeBinding(
    override val checked: CheckedType,
    private val application: NamedTypeUse,
    private val catalog: CheckedCatalog,
    private val registry: FactoryNativeBindingRegistry,
) : NativeBinding<Any>,
    GeneratedCheckedNativeBinding,
    AuthoredNativeBinding {
    override val actualType: TypeUse = application.use
    override val provider: NativeBindingId = NativeBindingId("typewriter.polymorphic")
    override val signature: String = "polymorphic(${actualType.canonicalText})"

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
            value as? DataValue.NamedWrapper
                ?: throw NativeBindingException("missing_polymorphic_type_tag", "A polymorphic value requires its concrete named type.")
        if (!catalog.isReadableAs(named.actualType.use, actualType)) {
            throw NativeBindingException("unreadable_polymorphic_type", "The concrete value is not readable as its declared type.")
        }
        val concrete =
            when (val resolution = catalog.resolve(named.actualType.use)) {
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
    override val actualType: TypeUse.ScalarWrapper,
) : NativeBinding<Any?>,
    CheckedNativeBinding {
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    override val signature: String = actualType.canonicalText

    override fun encode(value: Any?): DataValue =
        when (val kind = actualType.value) {
            ScalarKind.UNIT -> {
                DataValue.UNIT
            }

            ScalarKind.BOOLEAN -> {
                DataValue.BooleanWrapper(value as Boolean)
            }

            ScalarKind.TEXT -> {
                DataValue.StringValueWrapper(value as String)
            }

            ScalarKind.BYTES -> {
                DataValue.bytes(value as ByteArray)
            }

            is ScalarKind.IntegerWrapper -> {
                DataValue.integer(value.toBigInteger(kind.value.width))
            }

            is ScalarKind.FloatWrapper -> {
                when (kind.value.width) {
                    FloatWidth.THIRTY_TWO -> {
                        val number =
                            value as? Float
                                ?: throw NativeBindingException("wrong_native_float", "Float32 requires a Kotlin Float value.")
                        DataValue.FloatWrapper(number.toDouble())
                    }

                    FloatWidth.SIXTY_FOUR -> {
                        val number =
                            value as? Double
                                ?: throw NativeBindingException("wrong_native_float", "Float64 requires a Kotlin Double value.")
                        DataValue.FloatWrapper(number)
                    }

                    else -> {
                        unknownVariant(kind.value.width)
                    }
                }
            }

            ScalarKind.DECIMAL -> {
                DataValue.DecimalWrapper((value as BigDecimal).toPlainString())
            }

            ScalarKind.TIMESTAMP -> {
                DataValue.timestamp(value as kotlin.time.Instant)
            }

            ScalarKind.DURATION -> {
                DataValue.duration(value as kotlin.time.Duration)
            }

            else -> {
                unknownVariant(kind)
            }
        }

    override fun decode(value: CompleteValue): Any? =
        when (val kind = actualType.value) {
            ScalarKind.UNIT -> {
                Unit
            }

            ScalarKind.BOOLEAN -> {
                (value.value as DataValue.BooleanWrapper).value
            }

            ScalarKind.TEXT -> {
                (value.value as DataValue.StringValueWrapper).value
            }

            ScalarKind.BYTES -> {
                (value.value as DataValue.BytesWrapper).value.toByteArray()
            }

            is ScalarKind.IntegerWrapper -> {
                (value.value as DataValue.IntegerWrapper).bigInteger.toNativeInteger(kind.value.width)
            }

            is ScalarKind.FloatWrapper -> {
                val number = (value.value as DataValue.FloatWrapper).value
                if (kind.value.width == FloatWidth.THIRTY_TWO) {
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

            ScalarKind.DECIMAL -> {
                BigDecimal((value.value as DataValue.DecimalWrapper).value)
            }

            ScalarKind.TIMESTAMP -> {
                (value.value as DataValue.TimestampWrapper).instant
            }

            ScalarKind.DURATION -> {
                (value.value as DataValue.DurationWrapper).duration
            }

            else -> {
                unknownVariant(kind)
            }
        }
}

private class NullableNativeBinding(
    override val checked: CheckedType,
    override val actualType: TypeUse.NullableWrapper,
    resolveInner: () -> NativeBinding<*>,
) : NativeBinding<Any?>,
    CheckedNativeBinding {
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    private val inner by lazy(LazyThreadSafetyMode.SYNCHRONIZED, resolveInner)
    override val signature: String get() = "nullable(${inner.signature})"

    override fun encode(value: Any?): DataValue = if (value == null) DataValue.NULL else inner.encodeAny(value)

    override fun decode(value: CompleteValue): Any? = if (value.value == DataValue.NULL) null else inner.decodeAuthoredAny(value.value)
}

private class ListNativeBinding(
    private val application: NamedTypeUse,
    override val checked: CheckedType,
    resolveItem: () -> NativeBinding<*>,
) : NativeBinding<List<*>>,
    CheckedNativeBinding {
    override val actualType: TypeUse = application.use
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    private val item by lazy(LazyThreadSafetyMode.SYNCHRONIZED, resolveItem)
    override val signature: String get() = "list(${item.signature})"

    override fun encode(value: List<*>): DataValue =
        DataValue.named(
            application,
            DataValue.listValue(
                value.mapIndexed {
                    index,
                    element,
                    ->
                    ListItem(id = generatedItemId(index), value = item.encodeAny(element))
                },
            ),
        )

    override fun decode(value: CompleteValue): List<*> =
        value.payload<DataValue.ListValueWrapper>().items.map {
            item.decodeAuthoredAny(it.value)
        }
}

private class SetNativeBinding(
    private val application: NamedTypeUse,
    override val checked: CheckedType,
    resolveItem: () -> NativeBinding<*>,
) : NativeBinding<Set<*>>,
    CheckedNativeBinding {
    override val actualType: TypeUse = application.use
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    private val item by lazy(LazyThreadSafetyMode.SYNCHRONIZED, resolveItem)
    override val signature: String get() = "set(${item.signature})"

    override fun encode(value: Set<*>): DataValue =
        DataValue.named(
            application,
            DataValue.setValue(
                value.mapIndexed {
                    index,
                    element,
                    ->
                    ListItem(id = generatedItemId(index), value = item.encodeAny(element))
                },
            ),
        )

    override fun decode(value: CompleteValue): Set<*> {
        val authored = value.payload<DataValue.SetValueWrapper>().items.map { it.value }
        if (authored.map(DataValue::canonicalValueKey).distinct().size != authored.size) {
            throw NativeBindingException("duplicate_set_value", "A native Set cannot preserve duplicate authored values.")
        }
        val decoded = authored.map { row -> item.decodeAuthoredAny(row) }
        if (decoded.distinct().size != decoded.size) {
            throw NativeBindingException("duplicate_set_value", "A native Set cannot preserve duplicate authored values.")
        }
        return decoded.toSet()
    }
}

private class MapNativeBinding(
    private val application: NamedTypeUse,
    override val checked: CheckedType,
    resolveKey: () -> NativeBinding<*>,
    resolveValue: () -> NativeBinding<*>,
) : NativeBinding<Map<*, *>>,
    CheckedNativeBinding {
    override val actualType: TypeUse = application.use
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    private val key by lazy(LazyThreadSafetyMode.SYNCHRONIZED, resolveKey)
    private val value by lazy(LazyThreadSafetyMode.SYNCHRONIZED, resolveValue)
    override val signature: String get() = "map(${key.signature},${value.signature})"

    override fun encode(value: Map<*, *>): DataValue =
        DataValue.named(
            application,
            DataValue.mapValue(
                value.entries.mapIndexed { index, entry ->
                    MapRow(id = generatedItemId(index), key = key.encodeAny(entry.key), value = this.value.encodeAny(entry.value))
                },
            ),
        )

    override fun decode(value: CompleteValue): Map<*, *> {
        val authored = value.payload<DataValue.MapValueWrapper>().rows
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
    private val application: NamedTypeUse,
    override val checked: CheckedType,
    private val endpoint: EndpointId,
) : NativeBinding<Ref<*, *>>,
    CheckedNativeBinding {
    override val actualType: TypeUse = application.use
    override val provider: NativeBindingId = FRAMEWORK_NATIVE_BINDING
    override val signature: String = "link(${endpoint.value})"

    override fun encode(value: Ref<*, *>): DataValue =
        DataValue.named(
            application,
            DataValue.createLink(endpoint = endpoint, target = LinkTarget(resource = value.target.toSkir(), opposite = value.opposite)),
        )

    override fun decode(value: CompleteValue): Ref<*, *> {
        val link = value.payload<DataValue.LinkWrapper>()
        if (link.endpoint != endpoint) {
            throw NativeBindingException("wrong_link_endpoint", "The authored link endpoint does not match its native binding.")
        }
        val target = link.value.target
        return Ref<RelationshipEndpoint<Resource, Resource>, Resource>(target.resource.toResourceId(), target.opposite)
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
    val payload = (value as? DataValue.NamedWrapper)?.payload ?: value
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
        else -> throw NativeBindingException("wrong_native_integer", "Unsupported $width native integer value.")
    }

private fun BigInteger.toNativeInteger(width: IntegerWidth): Any =
    when (width) {
        IntegerWidth.SIGNED_EIGHT -> toByte()
        IntegerWidth.SIGNED_SIXTEEN -> toShort()
        IntegerWidth.SIGNED_THIRTY_TWO -> toInt()
        IntegerWidth.SIGNED_SIXTY_FOUR -> toLong()
        IntegerWidth.UNSIGNED_EIGHT -> toInt().toUByte()
        IntegerWidth.UNSIGNED_SIXTEEN -> toInt().toUShort()
        IntegerWidth.UNSIGNED_THIRTY_TWO -> toLong().toUInt()
        IntegerWidth.UNSIGNED_SIXTY_FOUR -> toString().toULong()
        else -> unknownVariant(width)
    }

private fun generatedItemId(index: Int): ItemId = ItemId(value = "native:$index")
