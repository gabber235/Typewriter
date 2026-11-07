package com.typewritermc.types

import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.formula.NamedValue
import com.typewritermc.formula.RecordValue
import com.typewritermc.formula.Var
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.isNominalSubtype
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
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.typed_value.PortableValue
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

    /** The Kotlin value of an evaluation value, with no DataValue between. Reads a nested value only to convert it, through [values]. */
    fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): T

    /** The evaluation value of a Kotlin value, in the catalog's representation: the form the stored value walk gives. */
    fun toValue(
        value: T,
        values: EvaluationValues,
    ): Any?
}

/**
 * What a conversion between evaluation values and Kotlin needs from the evaluation that runs it. A formula function
 * call is one, so a provider's values cross at its own edge.
 */
interface EvaluationValues {
    /** A value not yet evaluated, evaluated one level; any other value as it is. */
    fun resolve(value: Any?): Any?

    /** [value] with everything inside it evaluated. */
    fun force(value: Any?): Any?

    /** Stops the current call with [message], as a failure the provider caused. */
    fun fail(message: String): Nothing
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

    /** The same bindings over [catalog], such as a view's catalog with its content types. */
    fun over(catalog: CheckedCatalog): NativeBindingRegistry

    /**
     * A code record of [actual] from the evaluation values a formula gave, each converted through its field's binding:
     * the binding's constructor when every field is given, the construction plan's when a defaulted one is left out.
     * Init checks run either way, and what they throw reaches the caller. The answer is the instance's evaluation value.
     */
    fun construct(
        actual: CheckedType,
        fields: Map<String, Any?>,
        values: EvaluationValues,
    ): Any?
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
    private val factories: List<NativeBindingFactory>,
) : NativeBindingRegistry {
    private val factoriesByDefinition = factories.groupBy(NativeBindingFactory::definition)
    private val bindings = mutableMapOf<TypeUse, DeferredNativeBinding>()

    override fun over(catalog: CheckedCatalog): NativeBindingRegistry = FactoryNativeBindingRegistry(catalog, factories)

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

    override fun construct(
        actual: CheckedType,
        fields: Map<String, Any?>,
        values: EvaluationValues,
    ): Any? {
        requireCurrentCatalog(actual)
        val binding = bind(actual)
        val declared = actual.schema.fields
        if (declared.all { it.key in fields }) {
            return binding.toValueAny(
                binding.fromValueAny(RecordValue(actual.use, fields), values),
                values,
            )
        }
        val use = actual.use as? TypeUse.NamedWrapper ?: values.fail("Only a record has a constructor.")
        val plan =
            factoriesByDefinition[use.value.definition]?.singleOrNull()?.constructionPlan
                ?: values.fail("${actual.use.canonicalText} has no constructor defaults.")
        val supplied =
            declared.filter { it.key in fields }.associate { field ->
                FieldOwner(definition = use.value.definition, name = field.key) to
                    binding(resolve(field.type)).fromValueAny(fields[field.key], values)
            }
        return binding.toValueAny(plan.construct(supplied), values)
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
                varBinding(actual, use.value) ?: collectionBinding(actual, use.value) ?: namedBinding(actual, use.value)
            }

            // A function value is its stored body: the Formula record's binding reads and writes it.
            is TypeUse.FunctionWrapper -> {
                binding(resolve(use.storedUse))
            }

            else -> {
                unknownVariant(use)
            }
        }

    /** A named type's generated binding, or the polymorphic or portable one when no factory declares it. */
    private fun namedBinding(
        actual: CheckedType,
        use: NamedTypeUse,
    ): NativeBinding<*> {
        val candidates = factoriesByDefinition[use.definition].orEmpty()
        if (candidates.isEmpty()) {
            val representation = actual.schema.representation
            return if (representation is ResolvedRepresentation.RecordWrapper && !representation.isInstantiable() &&
                actual.enumCases() == null
            ) {
                PolymorphicNativeBinding(actual, use, catalog, this)
            } else {
                PortableNativeBinding(actual, use)
            }
        }
        require(candidates.size == 1) { "Expected one native binding factory for ${use.definition}, found ${candidates.size}." }
        return FactoryCheckedNativeBinding(actual, candidates.single().bind(actual, appliedArguments(use)))
    }

    /**
     * Var is an interface with no generated binding: stored data reads and writes it by each value's own case, and an
     * evaluation value crosses as a Var.Value of its value type.
     */
    private fun varBinding(
        actual: CheckedType,
        use: NamedTypeUse,
    ): NativeBinding<*>? {
        if (use.definition != VAR_DEFINITION) return null
        val value = use.arguments.firstOrNull() ?: return null
        return VarNativeBinding(actual, PolymorphicNativeBinding(actual, use, catalog, this), value) { binding(resolve(value)) }
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

        is TypeTemplate.FunctionWrapper -> {
            val function = actual.function
            if (function != null && function.parts.size == value.parts.size) {
                TypeUse.FunctionWrapper(
                    function.copy(
                        context =
                            value.context.zip(
                                function.context,
                            ) { template, slot -> slot.copy(type = template.type.concreteFor(slot.type)) },
                        parameters =
                            value.parameters.zip(
                                function.parameters,
                            ) { template, slot -> slot.copy(type = template.type.concreteFor(slot.type)) },
                        result = value.result.concreteFor(function.result),
                    ),
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

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Any? = requireDelegate().fromValueAny(value, values)

    override fun toValue(
        value: Any?,
        values: EvaluationValues,
    ): Any? = requireDelegate().toValueAny(value, values)

    private fun requireDelegate(): NativeBinding<*> =
        delegate
            ?: throw NativeBindingException(
                "recursive_native_binding_initialization",
                "A recursive native binding was used before initialization completed.",
            )
}

private val FRAMEWORK_NATIVE_BINDING = NativeBindingId(value = "typewriter.framework")

/**
 * A type with no Kotlin class, such as a content type. Stored data decodes to a [PortableValue]; an evaluation value
 * stays its forced RecordValue or NamedValue in a Kotlin slot, and comes back as it went.
 */
private class PortableNativeBinding(
    override val checked: CheckedType,
    private val application: NamedTypeUse,
) : NativeBinding<Any>,
    GeneratedCheckedNativeBinding {
    override val actualType: TypeUse = application.use
    override val provider: NativeBindingId = NativeBindingId(value = "typewriter.portable")
    override val signature: String = "portable(${actualType.canonicalText})"
    override val opaque: Boolean = true

    /** Encodes [value] as its own actual type, which is this binding's type or, for a closed union, one of its cases. */
    override fun encode(value: Any): DataValue {
        if (value !is PortableValue) {
            throw NativeBindingException(
                "wrong_portable_value",
                "Only a portable value encodes through a portable binding.",
            )
        }
        val actual = value.actualType.named
        if (value.actualType != actualType && (actual == null || !checked.isNominalSubtype(actual.definition, application.definition))) {
            throw NativeBindingException("wrong_portable_actual_type", "The portable value type does not match its native binding.")
        }
        return DataValue.named(actual ?: application, value.payload)
    }

    /** Decodes the stored value as the type it was written with, so a union value keeps its case. */
    override fun decode(value: CompleteValue): PortableValue =
        PortableValue(
            actualType = (value.value as? DataValue.NamedWrapper)?.value?.actualType?.use ?: actualType,
            payload = value.payload<DataValue>(),
        )

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Any =
        when (val forced = values.force(value)) {
            is RecordValue, is NamedValue -> forced
            else -> values.fail("Expected a value of ${actualType.canonicalText}, got $forced.")
        }

    override fun toValue(
        value: Any,
        values: EvaluationValues,
    ): Any? =
        when (value) {
            is RecordValue, is NamedValue -> value
            else -> values.fail("A provider returned ${value::class.simpleName} where a ${actualType.canonicalText} was expected.")
        }
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
    override val provider: NativeBindingId = NativeBindingId(value = "typewriter.polymorphic")
    override val signature: String = "polymorphic(${actualType.canonicalText})"

    override fun encode(value: Any): DataValue = concreteBinding(value).encodeAny(value)

    override fun decode(value: CompleteValue): Any = decodeAuthored(value.value)

    /** Binds by the value's own type, which a RecordValue and a NamedValue carry. */
    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Any {
        val actual =
            when (val resolved = values.resolve(value)) {
                is RecordValue -> resolved.type
                is NamedValue -> resolved.type
                else -> values.fail("Expected a value of ${actualType.canonicalText}, got $resolved.")
            }
        if (!catalog.isReadableAs(actual, actualType)) values.fail("A ${actual.canonicalText} is not a ${actualType.canonicalText}.")
        val concrete =
            when (val resolution = catalog.resolve(actual)) {
                is Resolution.Ready -> resolution.value
                is Resolution.Invalid -> values.fail("The type ${actual.canonicalText} is not available.")
            }
        return registry.bind(concrete).fromValueAny(value, values) as Any
    }

    /** Binds by the instance's class, as encode does. */
    override fun toValue(
        value: Any,
        values: EvaluationValues,
    ): Any? = concreteBinding(value).toValueAny(value, values)

    private fun concreteBinding(value: Any): NativeBinding<*> {
        val candidates =
            catalog
                .concreteForms(checked)
                .map { concrete -> registry.bind(concrete) }
                .filter { binding -> binding.nativeClass?.isInstance(value) == true }
        if (candidates.size != 1) {
            throw NativeBindingException(
                "ambiguous_polymorphic_native_type",
                "Expected one concrete native binding for ${value::class.qualifiedName}, found ${candidates.size}.",
            )
        }
        return candidates.single()
    }

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

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Any? = delegate.fromValueAny(value, values)

    override fun toValue(
        value: Any?,
        values: EvaluationValues,
    ): Any? = delegate.toValueAny(value, values)
}

/**
 * A `Var<T, F>`: stored data through the polymorphic binding, by each value's own case. An evaluation value crosses as a
 * Var.Value of [value]'s Kotlin value; a function typed Var cannot cross in this layer, since its engine form is not
 * settled, and a Var.Computed coming back is a formula where a value was expected.
 */
private class VarNativeBinding(
    override val checked: CheckedType,
    private val stored: PolymorphicNativeBinding,
    private val value: TypeUse,
    resolveValue: () -> NativeBinding<*>,
) : NativeBinding<Any>,
    CheckedNativeBinding,
    AuthoredNativeBinding {
    private val valueBinding by lazy(LazyThreadSafetyMode.SYNCHRONIZED, resolveValue)
    override val provider: NativeBindingId get() = stored.provider
    override val signature: String get() = "var(${checked.use.canonicalText})"
    override val actualType: TypeUse get() = checked.use

    override fun encode(value: Any): DataValue = stored.encode(value)

    override fun decode(value: CompleteValue): Any = stored.decode(value)

    override fun decodeAuthored(value: DataValue): Any = stored.decodeAuthored(value)

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Any {
        if (this.value is TypeUse.FunctionWrapper) values.fail("A function typed Var cannot reach a provider yet.")
        return Var.Value<Any?, Any?>(valueBinding.fromValueAny(values.resolve(value), values))
    }

    override fun toValue(
        value: Any,
        values: EvaluationValues,
    ): Any? =
        when (value) {
            is Var.Value<*, *> -> valueBinding.toValueAny(value.value, values)
            else -> values.fail("A provider returned a formula where a value was expected.")
        }
}

/**
 * The Kotlin value of the stored scalar [this] of [kind], as its native binding decodes it: an integer at its declared
 * width, a float as Float or Double, a type as [Type]. A Float32 that would lose precision fails.
 */
fun DataValue.scalarValue(kind: ScalarKind): Any? =
    when (kind) {
        ScalarKind.UNIT -> {
            Unit
        }

        ScalarKind.BOOLEAN -> {
            (this as DataValue.BooleanWrapper).value
        }

        ScalarKind.TEXT -> {
            (this as DataValue.StringValueWrapper).value
        }

        ScalarKind.BYTES -> {
            (this as DataValue.BytesWrapper).value.toByteArray()
        }

        is ScalarKind.IntegerWrapper -> {
            (this as DataValue.IntegerWrapper).bigInteger.toNativeInteger(kind.value.width)
        }

        is ScalarKind.FloatWrapper -> {
            (this as DataValue.FloatWrapper).value.atWidth(kind.value.width)
        }

        ScalarKind.DECIMAL -> {
            BigDecimal((this as DataValue.DecimalWrapper).value)
        }

        ScalarKind.TIMESTAMP -> {
            (this as DataValue.TimestampWrapper).instant
        }

        ScalarKind.DURATION -> {
            (this as DataValue.DurationWrapper).duration
        }

        ScalarKind.TYPE -> {
            Type((this as DataValue.TypeUseWrapper).value)
        }

        else -> {
            unknownVariant(kind)
        }
    }

/** The float at [width]: a Double, or a Float that holds it exactly. */
private fun Double.atWidth(width: FloatWidth): Any {
    if (width != FloatWidth.THIRTY_TWO) return this
    val narrowed = toFloat()
    if (!narrowed.isFinite()) throw NativeBindingException("float32_out_of_range", "Float32 value is out of range.")
    if (narrowed.toDouble() != this) {
        throw NativeBindingException("float32_precision_loss", "Float32 cannot represent the authored value exactly.")
    }
    return narrowed
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

            ScalarKind.TYPE -> {
                DataValue.TypeUseWrapper((value as Type).use)
            }

            else -> {
                unknownVariant(kind)
            }
        }

    override fun decode(value: CompleteValue): Any? = value.value.scalarValue(actualType.value)

    /** The value at its Kotlin width: an integer narrowed or widened to its declared width, a float to Float or Double. */
    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Any? {
        val resolved = values.resolve(value)
        return when (val kind = actualType.value) {
            is ScalarKind.IntegerWrapper -> {
                resolved.toBigInteger(kind.value.width).toNativeInteger(kind.value.width)
            }

            is ScalarKind.FloatWrapper -> {
                if (kind.value.width ==
                    FloatWidth.THIRTY_TWO
                ) {
                    (resolved as Number).toFloat()
                } else {
                    (resolved as Number).toDouble()
                }
            }

            else -> {
                resolved
            }
        }
    }

    override fun toValue(
        value: Any?,
        values: EvaluationValues,
    ): Any? = value
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

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Any? = values.resolve(value)?.let { inner.fromValueAny(it, values) }

    override fun toValue(
        value: Any?,
        values: EvaluationValues,
    ): Any? = value?.let { inner.toValueAny(it, values) }
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

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): List<*> = (values.resolve(value) as List<*>).map { item.fromValueAny(it, values) }

    override fun toValue(
        value: List<*>,
        values: EvaluationValues,
    ): Any? = value.map { item.toValueAny(it, values) }
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
        if (authored.map(DataValue::identityKey).distinct().size != authored.size) {
            throw NativeBindingException("duplicate_set_value", "A native Set cannot preserve duplicate authored values.")
        }
        val decoded = authored.map { row -> item.decodeAuthoredAny(row) }
        if (decoded.distinct().size != decoded.size) {
            throw NativeBindingException("duplicate_set_value", "A native Set cannot preserve duplicate authored values.")
        }
        return decoded.toSet()
    }

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Set<*> = (values.resolve(value) as Set<*>).mapTo(LinkedHashSet()) { item.fromValueAny(it, values) }

    override fun toValue(
        value: Set<*>,
        values: EvaluationValues,
    ): Any? = value.mapTo(LinkedHashSet()) { item.toValueAny(it, values) }
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
        if (authored.map { it.key.identityKey() }.distinct().size != authored.size) {
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

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Map<*, *> =
        (values.resolve(value) as Map<*, *>).entries.associateTo(LinkedHashMap()) { (key, item) ->
            this.key.fromValueAny(key, values) to this.value.fromValueAny(item, values)
        }

    override fun toValue(
        value: Map<*, *>,
        values: EvaluationValues,
    ): Any? =
        value.entries.associateTo(LinkedHashMap()) { (key, item) ->
            this.key.toValueAny(key, values) to
                this.value.toValueAny(item, values)
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

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): Ref<*, *> = values.resolve(value) as? Ref<*, *> ?: values.fail("Expected a reference, got $value.")

    override fun toValue(
        value: Ref<*, *>,
        values: EvaluationValues,
    ): Any? = value
}

private fun NativeBinding<*>.encodeAny(value: Any?): DataValue {
    @Suppress("UNCHECKED_CAST")
    return (this as NativeBinding<Any?>).encode(value)
}

private fun NativeBinding<*>.decodeAny(value: CompleteValue): Any? = decode(value)

/** The Kotlin value of an evaluation [value], through a binding of any type. */
fun NativeBinding<*>.fromValueAny(
    value: Any?,
    values: EvaluationValues,
): Any? = fromValue(value, values)

/** The evaluation value of a Kotlin [value], through a binding of any type. */
fun NativeBinding<*>.toValueAny(
    value: Any?,
    values: EvaluationValues,
): Any? {
    @Suppress("UNCHECKED_CAST")
    return (this as NativeBinding<Any?>).toValue(value, values)
}

private val VAR_DEFINITION: TypeDefinitionId = TypeDefinitionId.declared(VAR_TYPE_ID)

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
