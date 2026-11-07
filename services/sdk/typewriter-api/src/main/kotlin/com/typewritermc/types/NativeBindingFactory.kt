package com.typewritermc.types

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.complete
import com.typewritermc.formula.NamedValue
import com.typewritermc.formula.RecordValue
import com.typewritermc.types.catalog.CheckedType
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse

interface NativeBindingFactory {
    val definition: TypeDefinitionId
    val provider: NativeBindingId
    val nativeClass: kotlin.reflect.KClass<*>? get() = null

    val constructionPlan: NativeConstructionPlan? get() = null

    fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*>
}

fun interface NativeBindingResolver {
    fun bind(type: TypeUse): NativeBinding<*>
}

/** Resolves its native binding on first access, so recursive field applications need not expand during construction. */
@GeneratedSdkApi
class GeneratedNativeField<T>(
    val name: String,
    resolveBinding: () -> NativeBinding<*>,
    val read: (T) -> Any?,
) {
    val binding: NativeBinding<*> by lazy(LazyThreadSafetyMode.SYNCHRONIZED, resolveBinding)
}

@GeneratedSdkApi
class GeneratedRecordNativeBinding<T>(
    override val checked: CheckedType,
    override val provider: NativeBindingId,
    override val signature: String,
    override val nativeClass: kotlin.reflect.KClass<*>? = null,
    private val fields: List<GeneratedNativeField<T>>,
    private val construct: (Map<String, Any?>) -> T,
) : NativeBinding<T>,
    GeneratedCheckedNativeBinding {
    override val actualType: TypeUse = checked.use

    /** A fieldless object case, which the catalog declares as a unit case and stores with a unit payload. */
    private val unitCase: Boolean get() = checked.schema.representation is ResolvedRepresentation.ScalarWrapper

    override fun encode(value: T): DataValue =
        DataValue.named(
            actualType = (checked.use as TypeUse.NamedWrapper).value,
            payload =
                if (unitCase) {
                    DataValue.UNIT
                } else {
                    DataValue.record(fields.associate { it.name to it.binding.encodeGenerated(it.read(value)) })
                },
        )

    override fun decode(value: com.typewritermc.authoring.CompleteValue): T {
        val payload = value.value.namedPayload()
        if (unitCase && payload == DataValue.UNIT) return construct(emptyMap())
        val record =
            payload as? DataValue.RecordWrapper
                ?: throw NativeBindingException("wrong_native_representation", "Expected a named record value.")
        return construct(
            fields.associate { field ->
                val fieldValue =
                    record.field(field.name)
                        ?: throw NativeBindingException("missing_native_field", "Missing native field ${field.name}.")
                field.name to field.binding.decodeGenerated(fieldValue)
            },
        )
    }

    /** Builds the instance from a RecordValue, converting each field through its own binding; a fieldless object case needs none. */
    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): T {
        val resolved = values.resolve(value)
        if (resolved is NamedValue && fields.isEmpty()) return construct(emptyMap())
        val record = resolved as? RecordValue ?: values.fail("Expected a record of ${actualType.canonicalText}, got $resolved.")
        return construct(
            fields.associate { field ->
                if (field.name !in record.fields) values.fail("The record has no field ${field.name}.")
                field.name to field.binding.fromValueAny(values.resolve(record.fields[field.name]), values)
            },
        )
    }

    /** The RecordValue of [value] at this binding's applied type; a fieldless object case is a NamedValue, as the walk gives it. */
    override fun toValue(
        value: T,
        values: EvaluationValues,
    ): Any? {
        if (unitCase) return NamedValue(actualType, Unit)
        return RecordValue(actualType, fields.associate { it.name to it.binding.toValueAny(it.read(value), values) })
    }
}

@GeneratedSdkApi
class GeneratedScalarNativeBinding<T>(
    override val checked: CheckedType,
    override val provider: NativeBindingId,
    override val signature: String,
    override val nativeClass: kotlin.reflect.KClass<*>? = null,
    private val representation: NativeBinding<*>,
    private val unwrap: (T) -> Any?,
    private val construct: (Any?) -> T,
) : NativeBinding<T>,
    GeneratedCheckedNativeBinding {
    override val actualType: TypeUse = checked.use

    override fun encode(value: T): DataValue =
        DataValue.named((checked.use as TypeUse.NamedWrapper).value, representation.encodeGenerated(unwrap(value)))

    override fun decode(value: com.typewritermc.authoring.CompleteValue): T =
        construct(representation.decodeGenerated(value.value.namedPayload()))

    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): T {
        val named = values.resolve(value) as? NamedValue ?: values.fail("Expected a ${actualType.canonicalText}.")
        return construct(representation.fromValueAny(named.value, values))
    }

    override fun toValue(
        value: T,
        values: EvaluationValues,
    ): Any? = NamedValue(actualType, representation.toValueAny(unwrap(value), values))
}

@GeneratedSdkApi
class GeneratedEnumNativeBinding<T>(
    override val checked: CheckedType,
    override val provider: NativeBindingId,
    override val signature: String,
    override val nativeClass: kotlin.reflect.KClass<*>? = null,
    private val key: (T) -> String,
    private val construct: (String) -> T,
) : NativeBinding<T>,
    GeneratedCheckedNativeBinding {
    override val actualType: TypeUse = checked.use

    override fun encode(value: T): DataValue =
        DataValue.named((checked.use as TypeUse.NamedWrapper).value.member(key(value)), DataValue.UNIT)

    override fun decode(value: com.typewritermc.authoring.CompleteValue): T {
        val case =
            value.value.enumCaseName()
                ?: throw NativeBindingException("wrong_native_representation", "Expected a named enum case.")
        return construct(case)
    }

    /** The constant of the case a NamedValue names by its own type. */
    override fun fromValue(
        value: Any?,
        values: EvaluationValues,
    ): T {
        val named = values.resolve(value) as? NamedValue
        val case =
            named
                ?.type
                ?.named
                ?.definition
                ?.memberName ?: values.fail("Expected a case of ${actualType.canonicalText}.")
        return construct(case)
    }

    override fun toValue(
        value: T,
        values: EvaluationValues,
    ): Any? = NamedValue((checked.use as TypeUse.NamedWrapper).value.member(key(value)).use, Unit)
}

private fun DataValue.namedPayload(): DataValue = (this as? DataValue.NamedWrapper)?.payload ?: this

private fun NativeBinding<*>.encodeGenerated(value: Any?): DataValue {
    @Suppress("UNCHECKED_CAST")
    return (this as NativeBinding<Any?>).encode(value)
}

@GeneratedSdkApi
fun NativeBinding<*>.encodeGeneratedDefault(value: Any?): DataValue = encodeGenerated(value)

private fun NativeBinding<*>.decodeGenerated(value: DataValue): Any? {
    if (this is AuthoredNativeBinding) return decodeAuthored(value)
    val checkedBinding =
        this as? GeneratedCheckedNativeBinding
            ?: throw NativeBindingException("nested_binding_schema_unavailable", "The nested native binding has no checked schema.")
    return decode(checkedBinding.checked.complete(value).requireGeneratedComplete())
}

interface GeneratedCheckedNativeBinding {
    val checked: CheckedType
}

internal interface AuthoredNativeBinding {
    fun decodeAuthored(value: DataValue): Any?
}

private fun com.typewritermc.authoring.CompletenessResult.requireGeneratedComplete(): com.typewritermc.authoring.CompleteValue =
    when (this) {
        is com.typewritermc.authoring.CompletenessResult.Complete -> {
            value
        }

        is com.typewritermc.authoring.CompletenessResult.Unfinished -> {
            throw NativeBindingException("unfinished_native_value", locations.joinToString())
        }

        is com.typewritermc.authoring.CompletenessResult.Invalid -> {
            throw NativeBindingException("invalid_native_value", problems.joinToString())
        }
    }
