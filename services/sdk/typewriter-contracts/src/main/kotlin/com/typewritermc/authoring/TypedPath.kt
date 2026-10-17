package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@JvmInline
@Serializable
value class ItemId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Item ids must not be blank." }
    }
}

@Serializable
data class ValuePath(
    val segments: List<PathSegment> = emptyList(),
)

@Serializable
data class ValueLocation(
    val resource: ResourceId,
    val path: ValuePath,
)

@Serializable
sealed interface PathSegment {
    @Serializable
    @SerialName("field")
    data class Field(
        val name: String,
    ) : PathSegment

    @Serializable
    @SerialName("item")
    data class Item(
        val id: ItemId,
    ) : PathSegment

    @Serializable
    @SerialName("map_key")
    data object MapKey : PathSegment

    @Serializable
    @SerialName("map_value")
    data object MapValue : PathSegment
}

class TypedPath<Owner, Value> internal constructor(
    val owner: TypeDefinitionId,
    val path: ValuePath,
    internal val expected: TypeUse,
)

class BoundPath<Value> internal constructor(
    val location: ValueLocation,
    val expected: TypeUse,
)

class BoundCollectionPath internal constructor(
    val location: ValueLocation,
)

fun <O, V> TypedPath<O, V>.bind(resource: ResourceId): BoundPath<V> = BoundPath(ValueLocation(resource, path), expected)

fun <O, V> typedPath(
    owner: TypeDefinitionId,
    path: ValuePath,
    expected: TypeUse,
): TypedPath<O, V> = TypedPath(owner, path, expected)

fun <V> boundPath(
    location: ValueLocation,
    expected: TypeUse,
): BoundPath<V> = BoundPath(location, expected)

fun boundCollectionPath(location: ValueLocation): BoundCollectionPath = BoundCollectionPath(location)
