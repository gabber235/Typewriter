@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.types

import kotlinx.serialization.DeserializationStrategy
import kotlinx.serialization.SerializationException
import kotlinx.serialization.SerializationStrategy
import kotlinx.serialization.descriptors.PolymorphicKind
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.descriptors.StructureKind
import kotlinx.serialization.encoding.AbstractDecoder
import kotlinx.serialization.encoding.AbstractEncoder
import kotlinx.serialization.encoding.CompositeDecoder
import kotlinx.serialization.encoding.CompositeEncoder
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.modules.SerializersModule
import java.math.BigInteger
import kotlin.reflect.KClass
import kotlin.time.Duration
import kotlin.time.Instant

/**
 * Bridges Kotlin serialization directly to [DataValue] using the deployment type registry.
 *
 * Structural expressions guide scalar representation, generic substitution, nullable Option values, and
 * polymorphic dispatch. Conversion failures report value paths where available. This codec is not a complete
 * validator of every constraint declared in a type expression.
 */
class TypewriterDataFormat internal constructor(
    val serializersModule: SerializersModule,
    private val prototypes: TypePrototypeRegistry,
) {
    /**
     * Runs the supplied serializer against the expected structural expression.
     *
     * The serializer must produce a value and any named dependencies must exist in this registry. No JSON
     * intermediate representation is used.
     */
    fun <T> encodeToDataValue(
        serializer: SerializationStrategy<T>,
        value: T,
        type: TypeExpression,
    ): DataValue {
        var encoded: DataValue? = null
        serializer.serialize(
            DataValueEncoder(
                format = this,
                expectedType = type,
                path = DataValuePath.Root,
                result = { encoded = it },
            ),
            value,
        )
        return encoded ?: throw SerializationException("The serializer produced no value at ${DataValuePath.Root}.")
    }

    /**
     * Reconstructs a Kotlin value using the supplied deserializer and expected expression.
     *
     * Shape mismatches, unsupported serialization events, and unavailable prototypes fail; callers at transport or
     * persistence boundaries must classify those errors.
     */
    fun <T> decodeFromDataValue(
        deserializer: DeserializationStrategy<T>,
        value: DataValue,
        type: TypeExpression,
    ): T =
        deserializer.deserialize(
            DataValueDecoder(
                format = this,
                expectedType = type,
                path = DataValuePath.Root,
                sourceValue = value,
            ),
        )

    internal fun materialize(
        expression: TypeExpression,
        parameters: Map<String, TypeExpression> = emptyMap(),
    ): TypeExpression =
        when (expression) {
            is TypeExpression.Parameter -> {
                parameters[expression.name]?.let { materialize(it, parameters) } ?: TypeExpression.Any
            }

            is TypeExpression.ListType -> {
                expression.copy(element = materialize(expression.element, parameters))
            }

            is TypeExpression.MapType -> {
                expression.copy(
                    key = materialize(expression.key, parameters),
                    value = materialize(expression.value, parameters),
                )
            }

            is TypeExpression.Record -> {
                expression.copy(fields = expression.fields.map { it.copy(type = materialize(it.type, parameters)) })
            }

            is TypeExpression.Named -> {
                materializeNamed(expression.reference, parameters)
            }

            else -> {
                expression
            }
        }

    private fun materializeNamed(
        reference: ResolvedTypeRef,
        parameters: Map<String, TypeExpression>,
    ): TypeExpression {
        val resolvedArguments = reference.arguments.map { materialize(it, parameters) }
        val resolvedReference = reference.withArguments(resolvedArguments)
        if (resolvedReference.id == TypeId.Option) return TypeExpression.Named(resolvedReference)

        val definition = prototypes.definition(resolvedReference)
        if (definition.kind != NominalTypeKind.CONCRETE) return TypeExpression.Named(resolvedReference)

        val bindings =
            definition.parameters
                .mapIndexed { index, parameter ->
                    parameter.name to (resolvedArguments.getOrNull(index) ?: TypeExpression.Any)
                }.toMap()
        return materialize(definition.representation, bindings)
    }

    internal fun concrete(reference: ResolvedTypeRef): ConcreteTypePrototype<*> = prototypes.concrete(reference)

    internal fun concrete(runtimeType: KClass<*>): ConcreteTypePrototype<*> = prototypes.concrete(runtimeType)

    internal fun requireImplementation(
        expectedType: TypeExpression,
        concrete: ConcreteTypePrototype<*>,
        path: String,
    ) {
        val parentReference =
            (materialize(expectedType) as? TypeExpression.Named)?.reference
                ?: throw SerializationException("$path: Polymorphic values require an abstract named type.")
        val parent = prototypes.require(parentReference.copy(arguments = emptyList()))
        require(parent is AbstractTypePrototype<*>) {
            "$path: Polymorphic parent $parentReference is not abstract."
        }
        require(parent.runtimeType.java.isAssignableFrom(concrete.runtimeType.java)) {
            "$path: Concrete type ${concrete.type} does not implement $parentReference."
        }
        require(concrete in prototypes.concreteImplementationsOf(parentReference)) {
            "$path: Concrete type ${concrete.type} is not registered under $parentReference."
        }
    }

    internal fun validate(
        descriptor: SerialDescriptor,
        type: TypeExpression,
        path: String,
        inspectNullability: Boolean = true,
    ) {
        val expected = materialize(type)
        if (inspectNullability && descriptor.isNullable) {
            val option = (expected as? TypeExpression.Named)?.reference
            require(option?.id == TypeId.Option && option.arguments.size == 1) {
                "$path: Nullable serializer ${descriptor.serialName} requires an Option expression."
            }
            validate(descriptor, option.arguments.single(), path, inspectNullability = false)
            return
        }
        when (expected) {
            TypeExpression.Any -> {}

            TypeExpression.Unit -> {
                require(descriptor.elementsCount == 0) { "$path: Unit types cannot contain serialized fields." }
            }

            TypeExpression.Boolean -> {
                require(descriptor.kind == PrimitiveKind.BOOLEAN) { "$path: Expected a Boolean serializer." }
            }

            is TypeExpression.StringType -> {
                require(descriptor.kind == PrimitiveKind.STRING || descriptor.kind == PrimitiveKind.CHAR) {
                    "$path: Expected a string serializer."
                }
            }

            is TypeExpression.Bytes -> {
                require(descriptor.serialName == "kotlin.ByteArray") { "$path: Expected the ByteArray serializer." }
            }

            is TypeExpression.Integer -> {
                require(
                    descriptor.kind in INTEGER_KINDS ||
                        descriptor.kind == PrimitiveKind.STRING ||
                        descriptor.serialName in UNSIGNED_INTEGER_SERIAL_NAMES,
                ) {
                    "$path: Expected an integer serializer."
                }
            }

            is TypeExpression.Float -> {
                require(descriptor.kind == PrimitiveKind.FLOAT || descriptor.kind == PrimitiveKind.DOUBLE) {
                    "$path: Expected a floating point serializer."
                }
            }

            is TypeExpression.Decimal,
            is TypeExpression.Timestamp,
            is TypeExpression.Duration,
            -> {
                require(descriptor.kind == PrimitiveKind.STRING) { "$path: Expected a logical string serializer." }
            }

            is TypeExpression.Enumeration -> {
                require(descriptor.kind == kotlinx.serialization.descriptors.SerialKind.ENUM) {
                    "$path: Expected an enum serializer."
                }
            }

            is TypeExpression.ListType -> {
                require(descriptor.kind == StructureKind.LIST) { "$path: Expected a list serializer." }
                validate(descriptor.getElementDescriptor(0), expected.element, "$path[]")
            }

            is TypeExpression.MapType -> {
                require(descriptor.kind == StructureKind.MAP) { "$path: Expected a map serializer." }
                validate(descriptor.getElementDescriptor(0), expected.key, "$path.key")
                validate(descriptor.getElementDescriptor(1), expected.value, "$path.value")
            }

            is TypeExpression.Record -> {
                require(descriptor.kind == StructureKind.CLASS || descriptor.kind == StructureKind.OBJECT) {
                    "$path: Expected a record serializer."
                }
                val descriptorFields = (0 until descriptor.elementsCount).associateBy(descriptor::getElementName)
                require(descriptorFields.keys == expected.fields.map(TypeField::name).toSet()) {
                    "$path: Serializer fields ${descriptorFields.keys} do not match catalog fields ${expected.fields.map(TypeField::name)}."
                }
                expected.fields.forEach { field ->
                    validate(
                        descriptor.getElementDescriptor(descriptorFields.getValue(field.name)),
                        field.type,
                        "$path.${field.name}",
                    )
                }
            }

            is TypeExpression.Named -> {
                require(descriptor.kind is PolymorphicKind) {
                    "$path: Abstract named type ${expected.reference} requires a polymorphic serializer."
                }
            }

            is TypeExpression.Parameter -> {}
        }
    }
}

private val INTEGER_KINDS =
    setOf(
        PrimitiveKind.BYTE,
        PrimitiveKind.SHORT,
        PrimitiveKind.INT,
        PrimitiveKind.LONG,
    )

private val UNSIGNED_INTEGER_SERIAL_NAMES =
    setOf(
        "kotlin.UByte",
        "kotlin.UShort",
        "kotlin.UInt",
        "kotlin.ULong",
    )

private data class DataValuePath(
    private val value: String,
) {
    fun field(name: String): DataValuePath = DataValuePath("$value.$name")

    fun index(index: Int): DataValuePath = DataValuePath("$value[$index]")

    override fun toString(): String = value

    companion object {
        val Root = DataValuePath("value")
    }
}

private open class DataValueEncoder(
    protected val format: TypewriterDataFormat,
    expectedType: TypeExpression,
    protected var path: DataValuePath,
    private val result: (DataValue) -> Unit,
) : AbstractEncoder() {
    final override val serializersModule: SerializersModule = format.serializersModule

    protected var expected: TypeExpression = format.materialize(expectedType)
    private var nullableValueType: TypeExpression? = null

    override fun shouldEncodeElementDefault(
        descriptor: SerialDescriptor,
        index: Int,
    ): Boolean = true

    override fun encodeNull() {
        val valueType = requireOptionType()
        write(noneValue(valueType))
    }

    override fun encodeNotNullMark() {
        val valueType = requireOptionType()
        nullableValueType = valueType
        expected = format.materialize(valueType)
    }

    override fun encodeBoolean(value: Boolean) = emit(DataValue.Boolean(value))

    override fun encodeByte(value: Byte) = emit(DataValue.Integer(integerValue(value.toLong(), value.toUByte().toString())))

    override fun encodeShort(value: Short) = emit(DataValue.Integer(integerValue(value.toLong(), value.toUShort().toString())))

    override fun encodeInt(value: Int) = emit(DataValue.Integer(integerValue(value.toLong(), value.toUInt().toString())))

    override fun encodeLong(value: Long) = emit(DataValue.Integer(integerValue(value, value.toULong().toString())))

    override fun encodeFloat(value: Float) = emit(DataValue.Float(value.toDouble()))

    override fun encodeDouble(value: Double) = emit(DataValue.Float(value))

    override fun encodeChar(value: Char) = emit(DataValue.StringValue(value.toString()))

    override fun encodeString(value: String) {
        val encoded =
            when (val type = expected) {
                TypeExpression.Any -> DataValue.StringValue(value)
                is TypeExpression.StringType -> DataValue.StringValue(value)
                is TypeExpression.Decimal -> DataValue.Decimal(value)
                is TypeExpression.Timestamp -> DataValue.Timestamp(Instant.parse(value))
                is TypeExpression.Duration -> DataValue.Duration(Duration.parse(value))
                is TypeExpression.Integer -> DataValue.Integer(requireIntegerRange(value.toBigInteger(), type.width, path))
                is TypeExpression.Enumeration -> DataValue.StringValue(value)
                else -> mismatch("string", type)
            }
        emit(encoded)
    }

    override fun encodeEnum(
        enumDescriptor: SerialDescriptor,
        index: Int,
    ) = emit(DataValue.StringValue(enumDescriptor.getElementName(index)))

    override fun beginStructure(descriptor: SerialDescriptor): CompositeEncoder =
        when (descriptor.kind) {
            StructureKind.LIST -> {
                ListDataValueEncoder(format, expected, path, ::emit)
            }

            StructureKind.MAP -> {
                MapDataValueEncoder(format, expected, path, ::emit)
            }

            StructureKind.CLASS,
            StructureKind.OBJECT,
            -> {
                RecordDataValueEncoder(format, expected, path, ::emit)
            }

            PolymorphicKind.OPEN,
            PolymorphicKind.SEALED,
            -> {
                PolymorphicDataValueEncoder(format, expected, path, ::emit)
            }

            else -> {
                mismatch("structure ${descriptor.kind}", expected)
            }
        }

    override fun <T> encodeSerializableValue(
        serializer: SerializationStrategy<T>,
        value: T,
    ) {
        val integerType = expected as? TypeExpression.Integer
        when {
            integerType != null && serializer.descriptor.serialName == BIG_INTEGER_SERIAL_NAME -> {
                emit(DataValue.Integer(requireIntegerRange(value as BigInteger, integerType.width, path)))
                return
            }

            expected is TypeExpression.Timestamp && serializer.descriptor.serialName == KOTLIN_INSTANT_SERIAL_NAME -> {
                emit(DataValue.Timestamp(value as Instant))
                return
            }

            expected is TypeExpression.Duration && serializer.descriptor.serialName == KOTLIN_DURATION_SERIAL_NAME -> {
                emit(DataValue.Duration(value as Duration))
                return
            }
        }
        if (expected is TypeExpression.Bytes && serializer.descriptor.serialName == "kotlin.ByteArray") {
            @Suppress("UNCHECKED_CAST")
            emit(DataValue.Bytes(value as ByteArray))
            return
        }
        super.encodeSerializableValue(serializer, value)
    }

    override fun <T : Any> encodeNullableSerializableElement(
        descriptor: SerialDescriptor,
        index: Int,
        serializer: SerializationStrategy<T>,
        value: T?,
    ) {
        if (!encodeElement(descriptor, index)) return
        encodeNullableSerializableValue(serializer, value)
    }

    protected fun emit(value: DataValue) {
        val optionType = nullableValueType
        nullableValueType = null
        write(if (optionType == null) value else value.toSomeValue(optionType))
    }

    protected open fun write(value: DataValue) = result(value)

    protected fun mismatch(
        actual: String,
        expected: TypeExpression,
    ): Nothing = throw SerializationException("$path: Serializer emitted $actual where the catalog expected $expected.")

    private fun requireOptionType(): TypeExpression {
        val reference = (expected as? TypeExpression.Named)?.reference
        if (reference?.id != TypeId.Option || reference.arguments.size != 1) {
            mismatch("nullable value", expected)
        }
        return reference.arguments.single()
    }

    private fun integerValue(
        signed: Long,
        unsigned: String,
    ): BigInteger {
        val integerType = expected as? TypeExpression.Integer
        val value = if (integerType?.width?.signed == false) unsigned.toBigInteger() else BigInteger.valueOf(signed)
        return if (integerType == null) value else requireIntegerRange(value, integerType.width, path)
    }
}

private class ListDataValueEncoder(
    format: TypewriterDataFormat,
    expectedType: TypeExpression,
    path: DataValuePath,
    private val complete: (DataValue) -> Unit,
) : DataValueEncoder(format, expectedType, path, complete) {
    private val containerPath = path
    private val values = mutableListOf<DataValue>()
    private val listType = expected as? TypeExpression.ListType

    override fun encodeElement(
        descriptor: SerialDescriptor,
        index: Int,
    ): Boolean {
        expected = listType?.element ?: TypeExpression.Any
        path = containerPath.index(index)
        return true
    }

    override fun endStructure(descriptor: SerialDescriptor) {
        complete(DataValue.ListValue(values.toList()))
    }

    override fun write(value: DataValue) {
        values += value
    }
}

private class MapDataValueEncoder(
    format: TypewriterDataFormat,
    expectedType: TypeExpression,
    path: DataValuePath,
    private val complete: (DataValue) -> Unit,
) : DataValueEncoder(format, expectedType, path, complete) {
    private val containerPath = path
    private val entries = mutableListOf<DataMapEntry>()
    private val mapType = expected as? TypeExpression.MapType
    private var key: DataValue? = null

    override fun encodeElement(
        descriptor: SerialDescriptor,
        index: Int,
    ): Boolean {
        expected = if (index % 2 == 0) mapType?.key ?: TypeExpression.Any else mapType?.value ?: TypeExpression.Any
        path = containerPath.index(index / 2).field(if (index % 2 == 0) "key" else "value")
        return true
    }

    override fun endStructure(descriptor: SerialDescriptor) {
        require(key == null) { "$path: Map serializer produced a key without a value." }
        complete(DataValue.MapValue(entries.toList()))
    }

    override fun write(value: DataValue) {
        val pending = key
        if (pending == null) {
            key = value
        } else {
            entries += DataMapEntry(pending, value)
            key = null
        }
    }
}

private class RecordDataValueEncoder(
    format: TypewriterDataFormat,
    expectedType: TypeExpression,
    path: DataValuePath,
    private val complete: (DataValue) -> Unit,
) : DataValueEncoder(format, expectedType, path, complete) {
    private val containerPath = path
    private val fields = linkedMapOf<String, DataValue>()
    private val recordType = expected as? TypeExpression.Record
    private var fieldName: String? = null

    override fun encodeElement(
        descriptor: SerialDescriptor,
        index: Int,
    ): Boolean {
        val name = descriptor.getElementName(index)
        fieldName = name
        expected = recordType?.fields?.singleOrNull { it.name == name }?.type ?: TypeExpression.Any
        path = containerPath.field(name)
        return true
    }

    override fun endStructure(descriptor: SerialDescriptor) {
        complete(if (fields.isEmpty() && descriptor.elementsCount == 0) DataValue.Unit else DataValue.Record(fields.toMap()))
    }

    override fun write(value: DataValue) {
        val name = requireNotNull(fieldName) { "$path: Record serializer emitted a value without a field." }
        require(fields.put(name, value) == null) { "$path: Record serializer emitted field $name more than once." }
        fieldName = null
    }
}

private class PolymorphicDataValueEncoder(
    format: TypewriterDataFormat,
    expectedType: TypeExpression,
    path: DataValuePath,
    private val complete: (DataValue) -> Unit,
) : DataValueEncoder(format, expectedType, path, complete) {
    private var prototype: ConcreteTypePrototype<*>? = null
    private var payload: DataValue? = null

    override fun encodeElement(
        descriptor: SerialDescriptor,
        index: Int,
    ): Boolean = true

    override fun encodeString(value: String) {}

    override fun <T> encodeSerializableElement(
        descriptor: SerialDescriptor,
        index: Int,
        serializer: SerializationStrategy<T>,
        value: T,
    ) {
        if (index == 0) {
            super.encodeSerializableElement(descriptor, index, serializer, value)
            return
        }
        val selected = format.concrete(requireNotNull(value)::class)
        format.requireImplementation(expected, selected, path.toString())
        DataValueEncoder(format, selected.definition.representation, path, { payload = it })
            .encodeSerializableValue(serializer, value)
        prototype = selected
    }

    override fun endStructure(descriptor: SerialDescriptor) {
        val selected = requireNotNull(prototype) { "$path: Polymorphic serializer omitted its payload type." }
        complete(
            DataValue.Polymorphic(
                concreteType = selected.type,
                value = requireNotNull(payload) { "$path: Polymorphic serializer omitted its payload." },
            ),
        )
    }
}

private open class DataValueDecoder(
    protected val format: TypewriterDataFormat,
    expectedType: TypeExpression,
    protected var path: DataValuePath,
    sourceValue: DataValue,
) : AbstractDecoder() {
    final override val serializersModule: SerializersModule = format.serializersModule

    protected var expected: TypeExpression = format.materialize(expectedType)
    protected var value: DataValue = sourceValue

    override fun decodeElementIndex(descriptor: SerialDescriptor): Int = CompositeDecoder.DECODE_DONE

    override fun decodeNotNullMark(): Boolean {
        val reference = (expected as? TypeExpression.Named)?.reference
        if (reference?.id != TypeId.Option || reference.arguments.size != 1) mismatch("optional value")
        val option = value as? DataValue.Polymorphic ?: mismatch("optional polymorphic value")
        return when (option.concreteType.id) {
            TypeId.None -> {
                false
            }

            TypeId.Some -> {
                expected = format.materialize(reference.arguments.single())
                value =
                    (option.value as? DataValue.Record)?.fields?.get("value")
                        ?: option.value
                true
            }

            else -> {
                mismatch("Some or None")
            }
        }
    }

    override fun decodeNull(): Nothing? = null

    override fun decodeBoolean(): Boolean = requireValue<DataValue.Boolean>().value

    override fun decodeByte(): Byte =
        if (isUnsignedInteger()) requireInteger().toString().toUByte().toByte() else requireInteger().byteValueExact()

    override fun decodeShort(): Short =
        if (isUnsignedInteger()) requireInteger().toString().toUShort().toShort() else requireInteger().shortValueExact()

    override fun decodeInt(): Int =
        if (isUnsignedInteger()) requireInteger().toString().toUInt().toInt() else requireInteger().intValueExact()

    override fun decodeLong(): Long =
        if (isUnsignedInteger()) requireInteger().toString().toULong().toLong() else requireInteger().longValueExact()

    override fun decodeFloat(): Float = requireValue<DataValue.Float>().value.toFloat()

    override fun decodeDouble(): Double = requireValue<DataValue.Float>().value

    override fun decodeChar(): Char = requireValue<DataValue.StringValue>().value.single()

    override fun decodeString(): String =
        when (val current = value) {
            is DataValue.StringValue -> current.value
            is DataValue.Decimal -> current.value
            is DataValue.Timestamp -> current.value.toString()
            is DataValue.Duration -> current.value.toString()
            is DataValue.Integer -> current.value.toString()
            else -> mismatch("string compatible value")
        }

    override fun decodeEnum(enumDescriptor: SerialDescriptor): Int {
        val name = requireValue<DataValue.StringValue>().value
        val index = (0 until enumDescriptor.elementsCount).firstOrNull { enumDescriptor.getElementName(it) == name }
        return index ?: throw SerializationException("$path: Enum ${enumDescriptor.serialName} has no value $name.")
    }

    override fun beginStructure(descriptor: SerialDescriptor): CompositeDecoder =
        when (descriptor.kind) {
            StructureKind.LIST -> ListDataValueDecoder(format, expected, path, value)

            StructureKind.MAP -> MapDataValueDecoder(format, expected, path, value)

            StructureKind.CLASS,
            StructureKind.OBJECT,
            -> RecordDataValueDecoder(format, expected, path, value)

            PolymorphicKind.OPEN,
            PolymorphicKind.SEALED,
            -> PolymorphicDataValueDecoder(format, expected, path, value)

            else -> mismatch("structure ${descriptor.kind}")
        }

    override fun <T> decodeSerializableValue(deserializer: DeserializationStrategy<T>): T {
        @Suppress("UNCHECKED_CAST")
        when {
            expected is TypeExpression.Integer && deserializer.descriptor.serialName == BIG_INTEGER_SERIAL_NAME -> {
                return requireInteger() as T
            }

            expected is TypeExpression.Timestamp && deserializer.descriptor.serialName == KOTLIN_INSTANT_SERIAL_NAME -> {
                return requireValue<DataValue.Timestamp>().value as T
            }

            expected is TypeExpression.Duration && deserializer.descriptor.serialName == KOTLIN_DURATION_SERIAL_NAME -> {
                return requireValue<DataValue.Duration>().value as T
            }
        }
        if (expected is TypeExpression.Bytes && deserializer.descriptor.serialName == "kotlin.ByteArray") {
            @Suppress("UNCHECKED_CAST")
            return requireValue<DataValue.Bytes>().toByteArray() as T
        }
        return super.decodeSerializableValue(deserializer)
    }

    protected inline fun <reified T : DataValue> requireValue(): T = value as? T ?: mismatch(T::class.simpleName ?: "value")

    protected fun mismatch(expectedValue: String): Nothing =
        throw SerializationException(
            "$path: Expected $expectedValue for $expected, but received ${value::class.simpleName}.",
        )

    private fun requireInteger(): BigInteger {
        val integer = requireValue<DataValue.Integer>().value
        val integerType = expected as? TypeExpression.Integer ?: return integer
        return requireIntegerRange(integer, integerType.width, path)
    }

    private fun isUnsignedInteger(): Boolean = (expected as? TypeExpression.Integer)?.width?.signed == false
}

private const val BIG_INTEGER_SERIAL_NAME = "BigInteger"
private const val KOTLIN_INSTANT_SERIAL_NAME = "kotlin.time.Instant"
private const val KOTLIN_DURATION_SERIAL_NAME = "kotlin.time.Duration"

private fun requireIntegerRange(
    value: BigInteger,
    width: IntegerWidth,
    path: DataValuePath,
): BigInteger {
    val magnitude = BigInteger.ONE.shiftLeft(width.bits)
    val minimum = if (width.signed) magnitude.shiftRight(1).negate() else BigInteger.ZERO
    val maximum = if (width.signed) magnitude.shiftRight(1).subtract(BigInteger.ONE) else magnitude.subtract(BigInteger.ONE)
    if (value < minimum || value > maximum) {
        throw SerializationException(
            "$path: Integer $value is outside the ${width.bits} bit ${if (width.signed) "signed" else "unsigned"} range.",
        )
    }
    return value
}

private class ListDataValueDecoder(
    format: TypewriterDataFormat,
    expectedType: TypeExpression,
    path: DataValuePath,
    sourceValue: DataValue,
) : DataValueDecoder(format, expectedType, path, sourceValue) {
    private val containerPath = path
    private val values = requireValue<DataValue.ListValue>().values
    private val elementType = (expected as? TypeExpression.ListType)?.element ?: TypeExpression.Any
    private var index = 0

    override fun decodeCollectionSize(descriptor: SerialDescriptor): Int = values.size

    override fun decodeElementIndex(descriptor: SerialDescriptor): Int {
        if (index >= values.size) return CompositeDecoder.DECODE_DONE
        value = values[index]
        expected = elementType
        path = containerPath.index(index)
        return index++
    }
}

private class MapDataValueDecoder(
    format: TypewriterDataFormat,
    expectedType: TypeExpression,
    path: DataValuePath,
    sourceValue: DataValue,
) : DataValueDecoder(format, expectedType, path, sourceValue) {
    private val containerPath = path
    private val entries = requireValue<DataValue.MapValue>().entries
    private val mapType = expected as? TypeExpression.MapType
    private var index = 0

    override fun decodeCollectionSize(descriptor: SerialDescriptor): Int = entries.size * 2

    override fun decodeElementIndex(descriptor: SerialDescriptor): Int {
        if (index >= entries.size * 2) return CompositeDecoder.DECODE_DONE
        val entry = entries[index / 2]
        val key = index % 2 == 0
        value = if (key) entry.key else entry.value
        expected = if (key) mapType?.key ?: TypeExpression.Any else mapType?.value ?: TypeExpression.Any
        path = containerPath.index(index / 2).field(if (key) "key" else "value")
        return index++
    }
}

private class RecordDataValueDecoder(
    format: TypewriterDataFormat,
    expectedType: TypeExpression,
    path: DataValuePath,
    sourceValue: DataValue,
) : DataValueDecoder(format, expectedType, path, sourceValue) {
    private val containerPath = path
    private val fields = if (sourceValue is DataValue.Unit) emptyMap() else requireValue<DataValue.Record>().fields
    private val recordType = expected as? TypeExpression.Record
    private var nextIndex = 0

    override fun decodeElementIndex(descriptor: SerialDescriptor): Int {
        while (nextIndex < descriptor.elementsCount) {
            val index = nextIndex++
            val name = descriptor.getElementName(index)
            val field = recordType?.fields?.singleOrNull { it.name == name }
            val source = fields[name] ?: field?.initialValue ?: continue
            value = source
            expected = field?.type ?: TypeExpression.Any
            path = containerPath.field(name)
            return index
        }
        return CompositeDecoder.DECODE_DONE
    }
}

private class PolymorphicDataValueDecoder(
    format: TypewriterDataFormat,
    expectedType: TypeExpression,
    path: DataValuePath,
    sourceValue: DataValue,
) : DataValueDecoder(format, expectedType, path, sourceValue) {
    private val polymorphic = requireValue<DataValue.Polymorphic>()
    private val prototype = format.concrete(polymorphic.concreteType)
    private var index = 0

    init {
        format.requireImplementation(expected, prototype, path.toString())
    }

    override fun decodeElementIndex(descriptor: SerialDescriptor): Int =
        when (index++) {
            0 -> {
                value = DataValue.StringValue(prototype.serializer.descriptor.serialName)
                expected = TypeExpression.StringType()
                0
            }

            1 -> {
                value = polymorphic.value
                expected = prototype.definition.representation
                1
            }

            else -> {
                CompositeDecoder.DECODE_DONE
            }
        }

    override fun <T> decodeSerializableElement(
        descriptor: SerialDescriptor,
        index: Int,
        deserializer: DeserializationStrategy<T>,
        previousValue: T?,
    ): T =
        DataValueDecoder(
            format = format,
            expectedType = prototype.definition.representation,
            path = path,
            sourceValue = polymorphic.value,
        ).decodeSerializableValue(deserializer)
}
