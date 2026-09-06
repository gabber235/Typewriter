package com.typewritermc.types

import kotlinx.serialization.KSerializer
import kotlin.reflect.KClass

/**
 * Reusable concrete prototype delegating conversion to the registry data format. Construction requires a concrete
 * definition matching the resolved reference. Encoding and decoding use its representation and serializer within
 * the caller supplied prototype context; serialized field aliases keep property access aligned with the schema.
 */
open class SerializationConcreteTypePrototype<T : Any>(
    override val runtimeType: KClass<T>,
    override val type: ResolvedTypeRef,
    override val definition: TypeDefinition,
    final override val serializer: KSerializer<T>,
    final override val serializedFieldNames: Map<String, String> = emptyMap(),
) : ConcreteTypePrototype<T> {
    init {
        require(definition.id == type) { "A serialization prototype definition must match its reference." }
        require(definition.kind == NominalTypeKind.CONCRETE) { "A serialization prototype requires a concrete definition." }
    }

    context(context: TypeEncodingContext)
    override fun encode(value: T): DataValue =
        context.prototypes.dataFormat.encodeToDataValue(
            serializer = serializer,
            value = value,
            type = definition.representation,
        )

    context(context: TypeDecodingContext)
    override fun decode(value: DataValue): T =
        context.prototypes.dataFormat.decodeFromDataValue(
            deserializer = serializer,
            value = value,
            type = definition.representation,
        )
}
