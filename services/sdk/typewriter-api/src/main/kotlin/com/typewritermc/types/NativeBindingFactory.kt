package com.typewritermc.types

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.NativeBindingId
import com.typewritermc.authoring.NativeConstructionPlan
import com.typewritermc.authoring.complete
import com.typewritermc.types.catalog.CheckedType

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

data class GeneratedNativeField<T>(
    val name: String,
    val binding: NativeBinding<*>,
    val read: (T) -> Any?,
)

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

    override fun encode(value: T): DataValue =
        DataValue.Named(
            actualType = checked.use as TypeUse.Named,
            payload = DataValue.Record(fields.associate { it.name to it.binding.encodeGenerated(it.read(value)) }),
        )

    override fun decode(value: com.typewritermc.authoring.CompleteValue): T {
        val record =
            value.value.namedPayload() as? DataValue.Record
                ?: throw NativeBindingException("wrong_native_representation", "Expected a named record value.")
        return construct(
            fields.associate { field ->
                val fieldValue =
                    record.fields[field.name]
                        ?: throw NativeBindingException("missing_native_field", "Missing native field ${field.name}.")
                field.name to field.binding.decodeGenerated(fieldValue)
            },
        )
    }
}

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

    override fun encode(value: T): DataValue = DataValue.Named(checked.use as TypeUse.Named, representation.encodeGenerated(unwrap(value)))

    override fun decode(value: com.typewritermc.authoring.CompleteValue): T =
        construct(representation.decodeGenerated(value.value.namedPayload()))
}

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

    override fun encode(value: T): DataValue = DataValue.Named(checked.use as TypeUse.Named, DataValue.EnumCase(key(value)))

    override fun decode(value: com.typewritermc.authoring.CompleteValue): T {
        val case =
            value.value.namedPayload() as? DataValue.EnumCase
                ?: throw NativeBindingException("wrong_native_representation", "Expected a named enum value.")
        return construct(case.key)
    }
}

private fun DataValue.namedPayload(): DataValue = (this as? DataValue.Named)?.payload ?: this

private fun NativeBinding<*>.encodeGenerated(value: Any?): DataValue {
    @Suppress("UNCHECKED_CAST")
    return (this as NativeBinding<Any?>).encode(value)
}

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
