package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Polymorphic
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.Instant

private interface NativeMessage

@Serializable
@SerialName("shared_literal")
private data class NativeLiteralMessage(
    val value: String,
) : NativeMessage

private interface NativeOtherMessage

@Serializable
@SerialName("shared_literal")
private data class NativeOtherLiteralMessage(
    val value: String,
) : NativeOtherMessage

private interface NativeRoot

private interface NativeIntermediate<T> : NativeRoot

@Serializable
private data class NativeGenericMessage(
    val value: String,
) : NativeIntermediate<String>

@Serializable
private data class NativeEnvelope(
    @SerialName("display_name")
    val displayName: String,
    val count: Int,
    val note: String?,
    val values: List<Int>,
    val labels: Map<Int, String>,
    val bytes: ByteArray,
    @Polymorphic
    val message: NativeMessage,
) {
    override fun equals(other: Any?): Boolean =
        other is NativeEnvelope &&
            displayName == other.displayName &&
            count == other.count &&
            note == other.note &&
            values == other.values &&
            labels == other.labels &&
            bytes.contentEquals(other.bytes) &&
            message == other.message

    override fun hashCode(): Int = bytes.contentHashCode()
}

@Serializable
private enum class NativeStatus {
    @SerialName("ready_value")
    READY,
}

@Serializable
private data class NativeLogicalValues(
    val unsigned: UInt,
    @Serializable(with = BigIntegerAsStringSerializer::class)
    val integer: BigInteger,
    val timestamp: Instant,
    val duration: Duration,
    val status: NativeStatus,
)

val TypewriterDataFormatTest by testSuite {
    test("native format preserves exact structured values") {
        val fixture = nativeFormatFixture()
        val source =
            NativeEnvelope(
                displayName = "example",
                count = 42,
                note = null,
                values = listOf(1, 2),
                labels = linkedMapOf(7 to "seven"),
                bytes = byteArrayOf(1, 2, 3),
                message = NativeLiteralMessage("hello"),
            )

        val encoded = with(fixture.encoding) { fixture.envelope.encode(source) }

        encoded shouldBe
            DataValue.Record(
                mapOf(
                    "display_name" to DataValue.StringValue("example"),
                    "count" to DataValue.Integer(BigInteger.valueOf(42)),
                    "note" to noneValue(TypeExpression.StringType()),
                    "values" to
                        DataValue.ListValue(
                            listOf(
                                DataValue.Integer(BigInteger.ONE),
                                DataValue.Integer(BigInteger.TWO),
                            ),
                        ),
                    "labels" to
                        DataValue.MapValue(
                            listOf(
                                DataMapEntry(
                                    DataValue.Integer(BigInteger.valueOf(7)),
                                    DataValue.StringValue("seven"),
                                ),
                            ),
                        ),
                    "bytes" to DataValue.Bytes(byteArrayOf(1, 2, 3)),
                    "message" to
                        DataValue.Polymorphic(
                            concreteType = fixture.literal.type,
                            value = DataValue.Record(mapOf("value" to DataValue.StringValue("hello"))),
                        ),
                ),
            )
        with(fixture.decoding) { fixture.envelope.decode(encoded) } shouldBe source
    }

    test("open polymorphism stores stable identities instead of serializer names") {
        val fixture = nativeFormatFixture()
        val source =
            NativeEnvelope(
                displayName = "polymorphic",
                count = 1,
                note = "present",
                values = emptyList(),
                labels = emptyMap(),
                bytes = byteArrayOf(),
                message = NativeLiteralMessage("payload"),
            )

        val encoded = with(fixture.encoding) { fixture.envelope.encode(source) } as DataValue.Record
        val message = encoded.fields.getValue("message") as DataValue.Polymorphic

        message.concreteType shouldBe fixture.literal.type
        message.toString().contains(NativeLiteralMessage.serializer().descriptor.serialName) shouldBe false
        with(fixture.decoding) { fixture.envelope.decode(encoded) } shouldBe source
    }

    test("native format preserves unsigned logical and enum values") {
        val reference = declaredReference("019d4aaa333373339333333333333333")
        val definition =
            TypeDefinition(
                id = reference,
                kind = NominalTypeKind.CONCRETE,
                representation =
                    TypeExpression.Record(
                        listOf(
                            TypeField("duration", TypeExpression.Duration()),
                            TypeField("integer", TypeExpression.Integer(IntegerWidth.SIGNED_64)),
                            TypeField(
                                "status",
                                TypeExpression.Enumeration(
                                    valueType = TypeExpression.StringType(),
                                    values = listOf(DataValue.StringValue("ready_value")),
                                ),
                            ),
                            TypeField("timestamp", TypeExpression.Timestamp()),
                            TypeField("unsigned", TypeExpression.Integer(IntegerWidth.UNSIGNED_32)),
                        ),
                    ),
            )
        val prototype =
            SerializationConcreteTypePrototype(
                runtimeType = NativeLogicalValues::class,
                type = reference,
                definition = definition,
                serializer = NativeLogicalValues.serializer(),
            )
        val registry = TypePrototypeRegistry(listOf(prototype))
        val context =
            object : TypeEncodingContext, TypeDecodingContext {
                override val prototypes: TypePrototypeRegistry = registry
            }
        val source =
            NativeLogicalValues(
                unsigned = UInt.MAX_VALUE,
                integer = BigInteger("9223372036854775807"),
                timestamp = Instant.parse("2026-08-23T12:34:56.123456789Z"),
                duration = 75.seconds,
                status = NativeStatus.READY,
            )

        val encoded = with(context as TypeEncodingContext) { prototype.encode(source) }

        encoded shouldBe
            DataValue.Record(
                mapOf(
                    "unsigned" to DataValue.Integer(BigInteger("4294967295")),
                    "integer" to DataValue.Integer(BigInteger("9223372036854775807")),
                    "timestamp" to DataValue.Timestamp(source.timestamp),
                    "duration" to DataValue.Duration(source.duration),
                    "status" to DataValue.StringValue("ready_value"),
                ),
            )
        with(context as TypeDecodingContext) { prototype.decode(encoded) } shouldBe source
        shouldThrow<SerializationException> {
            with(context as TypeEncodingContext) {
                prototype.encode(source.copy(integer = BigInteger("9223372036854775808")))
            }
        }
        val oversized =
            (encoded as DataValue.Record).copy(
                fields = encoded.fields + ("integer" to DataValue.Integer(BigInteger("9223372036854775808"))),
            )
        shouldThrow<SerializationException> {
            with(context as TypeDecodingContext) { prototype.decode(oversized) }
        }
    }

    test("serializer names are scoped to their polymorphic parent") {
        val firstParent = ResolvedTypeRef(TypeId.Qualified("test", "NativeMessage"), revision = 1)
        val secondParent = ResolvedTypeRef(TypeId.Qualified("test", "NativeOtherMessage"), revision = 1)
        val first =
            concretePrototype(
                runtimeType = NativeLiteralMessage::class,
                reference = declaredReference("019d4aaa444474449444444444444444"),
                parent = firstParent,
                serializer = NativeLiteralMessage.serializer(),
            )
        val second =
            concretePrototype(
                runtimeType = NativeOtherLiteralMessage::class,
                reference = declaredReference("019d4aaa555575559555555555555555"),
                parent = secondParent,
                serializer = NativeOtherLiteralMessage.serializer(),
            )

        val registry =
            TypePrototypeRegistry(
                listOf(
                    first,
                    second,
                    abstractPrototype(NativeMessage::class, firstParent),
                    abstractPrototype(NativeOtherMessage::class, secondParent),
                ),
            )

        registry.concreteImplementationsOf(firstParent) shouldBe listOf(first)
        registry.concreteImplementationsOf(secondParent) shouldBe listOf(second)
    }

    test("generic intermediate parents retain runtime subtype traversal") {
        val root = ResolvedTypeRef(TypeId.Qualified("test", "NativeRoot"), revision = 1)
        val intermediate = ResolvedTypeRef(TypeId.Qualified("test", "NativeIntermediate"), revision = 1)
        val concreteReference = declaredReference("019d4aaa666676669666666666666666")
        val concrete =
            SerializationConcreteTypePrototype(
                runtimeType = NativeGenericMessage::class,
                type = concreteReference,
                definition =
                    TypeDefinition(
                        id = concreteReference,
                        kind = NominalTypeKind.CONCRETE,
                        representation = TypeExpression.Record(listOf(TypeField("value", TypeExpression.StringType()))),
                        parents = listOf(intermediate.withArguments(listOf(TypeExpression.StringType()))),
                    ),
                serializer = NativeGenericMessage.serializer(),
            )
        val intermediatePrototype =
            CatalogAbstractTypePrototype(
                runtimeType = NativeIntermediate::class,
                type = intermediate,
                definition =
                    TypeDefinition(
                        id = intermediate,
                        kind = NominalTypeKind.OPEN_ABSTRACT,
                        parents = listOf(root),
                    ),
            )
        val registry =
            TypePrototypeRegistry(
                listOf(
                    concrete,
                    intermediatePrototype,
                    abstractPrototype(NativeRoot::class, root),
                ),
            )

        registry.concreteImplementationsOf(root) shouldBe listOf(concrete)
    }

    test("abstract decoding rejects concrete values absent from the catalog hierarchy") {
        val parent = ResolvedTypeRef(TypeId.Qualified("test", "NativeMessage"), revision = 1)
        val reference = declaredReference("019d4aaa777777779777777777777777")
        val concrete =
            SerializationConcreteTypePrototype(
                runtimeType = NativeLiteralMessage::class,
                type = reference,
                definition =
                    TypeDefinition(
                        id = reference,
                        kind = NominalTypeKind.CONCRETE,
                        representation = TypeExpression.Record(listOf(TypeField("value", TypeExpression.StringType()))),
                    ),
                serializer = NativeLiteralMessage.serializer(),
            )
        val abstract = abstractPrototype(NativeMessage::class, parent)
        val registry = TypePrototypeRegistry(listOf(concrete, abstract))
        val decoding =
            object : TypeDecodingContext {
                override val prototypes: TypePrototypeRegistry = registry
            }

        shouldThrow<IllegalArgumentException> {
            with(registry) {
                with(decoding) {
                    abstract.decode(
                        DataValue.Polymorphic(
                            concreteType = reference,
                            value = DataValue.Record(mapOf("value" to DataValue.StringValue("invalid"))),
                        ),
                    )
                }
            }
        }
    }
}

private fun <T : Any> concretePrototype(
    runtimeType: kotlin.reflect.KClass<T>,
    reference: ResolvedTypeRef,
    parent: ResolvedTypeRef,
    serializer: KSerializer<T>,
): SerializationConcreteTypePrototype<T> =
    SerializationConcreteTypePrototype(
        runtimeType = runtimeType,
        type = reference,
        definition =
            TypeDefinition(
                id = reference,
                kind = NominalTypeKind.CONCRETE,
                representation = TypeExpression.Record(listOf(TypeField("value", TypeExpression.StringType()))),
                parents = listOf(parent),
            ),
        serializer = serializer,
    )

private fun <T : Any> abstractPrototype(
    runtimeType: kotlin.reflect.KClass<T>,
    reference: ResolvedTypeRef,
): CatalogAbstractTypePrototype<T> =
    CatalogAbstractTypePrototype(
        runtimeType = runtimeType,
        type = reference,
        definition = TypeDefinition(reference, NominalTypeKind.OPEN_ABSTRACT),
    )

private data class NativeFormatFixture(
    val envelope: SerializationConcreteTypePrototype<NativeEnvelope>,
    val literal: SerializationConcreteTypePrototype<NativeLiteralMessage>,
    val encoding: TypeEncodingContext,
    val decoding: TypeDecodingContext,
)

private fun nativeFormatFixture(): NativeFormatFixture {
    val messageReference = ResolvedTypeRef(TypeId.Qualified("test", "NativeMessage"), revision = 1)
    val literalReference = declaredReference("019d4aaa111171119111111111111111")
    val envelopeReference = declaredReference("019d4aaa222272229222222222222222")
    val messageDefinition =
        TypeDefinition(
            id = messageReference,
            kind = NominalTypeKind.OPEN_ABSTRACT,
        )
    val literalDefinition =
        TypeDefinition(
            id = literalReference,
            kind = NominalTypeKind.CONCRETE,
            representation =
                TypeExpression.Record(
                    listOf(TypeField("value", TypeExpression.StringType())),
                ),
            parents = listOf(messageReference),
        )
    val envelopeDefinition =
        TypeDefinition(
            id = envelopeReference,
            kind = NominalTypeKind.CONCRETE,
            representation =
                TypeExpression.Record(
                    listOf(
                        TypeField("bytes", TypeExpression.Bytes()),
                        TypeField("count", TypeExpression.Integer(IntegerWidth.SIGNED_32)),
                        TypeField("display_name", TypeExpression.StringType()),
                        TypeField(
                            "labels",
                            TypeExpression.MapType(TypeExpression.Integer(IntegerWidth.SIGNED_32), TypeExpression.StringType()),
                        ),
                        TypeField("message", TypeExpression.Named(messageReference)),
                        TypeField("note", TypeExpression.Named(StandardTypes.optionOf(TypeExpression.StringType()))),
                        TypeField("values", TypeExpression.ListType(TypeExpression.Integer(IntegerWidth.SIGNED_32))),
                    ),
                ),
        )
    val literal =
        SerializationConcreteTypePrototype(
            runtimeType = NativeLiteralMessage::class,
            type = literalReference,
            definition = literalDefinition,
            serializer = NativeLiteralMessage.serializer(),
        )
    val envelope =
        SerializationConcreteTypePrototype(
            runtimeType = NativeEnvelope::class,
            type = envelopeReference,
            definition = envelopeDefinition,
            serializer = NativeEnvelope.serializer(),
        )
    val abstract =
        CatalogAbstractTypePrototype(
            runtimeType = NativeMessage::class,
            type = messageReference,
            definition = messageDefinition,
        )
    val registry = TypePrototypeRegistry(listOf(envelope, literal, abstract))
    return NativeFormatFixture(
        envelope = envelope,
        literal = literal,
        encoding =
            object : TypeEncodingContext {
                override val prototypes: TypePrototypeRegistry = registry
            },
        decoding =
            object : TypeDecodingContext {
                override val prototypes: TypePrototypeRegistry = registry
            },
    )
}

private fun declaredReference(id: String): ResolvedTypeRef = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse(id)), revision = 1)
