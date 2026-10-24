package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.toSkir
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

/*
 * Value paths and locations are the generated Skir ValuePath, PathSegment and ValueLocation. A path addresses one value
 * within a resource or bound value by field name and stable collection item identity, so it survives reordering. The
 * helpers below build and extend them; requireValid checks paths and locations that enter from outside.
 */

/** The path of the whole resource or bound value. */
val ValuePath.Companion.root: ValuePath get() = ValuePath.partial()

/** The location of [path] within the resource identified by the author facing [resource] id. */
fun ValueLocation.Companion.of(
    resource: ResourceId,
    path: ValuePath = ValuePath.root,
): ValueLocation = ValueLocation(resource = resource.toSkir(), path = path)

fun ValueLocation.Companion.of(
    resource: skirout.editor.v1.type_catalog.ResourceId,
    path: ValuePath = ValuePath.root,
): ValueLocation = ValueLocation(resource = resource, path = path)

/**
 * A compact readable form of this path for messages and labels: field names joined by dots, `[id]` for a collection
 * item and `key` or `value` for the branch of a map row.
 */
val ValuePath.text: String
    get() =
        buildString {
            segments.forEach { segment ->
                when (segment) {
                    is PathSegment.FieldWrapper -> {
                        if (isNotEmpty()) append('.')
                        append(segment.value.name)
                    }

                    is PathSegment.ItemWrapper -> {
                        append('[').append(segment.value.id.value).append(']')
                    }

                    PathSegment.MAP_KEY -> {
                        append(".key")
                    }

                    PathSegment.MAP_VALUE -> {
                        append(".value")
                    }

                    else -> {
                        append(".unknown")
                    }
                }
            }
        }

val PathSegment.FieldWrapper.name: String get() = value.name

val PathSegment.ItemWrapper.id: ItemId get() = value.id

fun ValuePath.append(vararg segments: PathSegment): ValuePath = ValuePath(segments = this.segments + segments)

fun ValuePath.append(relative: ValuePath): ValuePath = ValuePath(segments = segments + relative.segments)

fun ValuePath.field(name: String): ValuePath = append(PathSegment.createField(name = name))

fun ValuePath.item(id: ItemId): ValuePath = append(PathSegment.createItem(id = id))

fun ValuePath.mapKey(): ValuePath = append(PathSegment.MAP_KEY)

fun ValuePath.mapValue(): ValuePath = append(PathSegment.MAP_VALUE)

fun ValueLocation.append(vararg segments: PathSegment): ValueLocation = copy(path = path.append(*segments))

fun ValueLocation.append(relative: ValuePath): ValueLocation = copy(path = path.append(relative))

fun ValueLocation.field(name: String): ValueLocation = copy(path = path.field(name))

fun ValueLocation.item(id: ItemId): ValueLocation = copy(path = path.item(id))

fun ValueLocation.mapKey(): ValueLocation = copy(path = path.mapKey())

fun ValueLocation.mapValue(): ValueLocation = copy(path = path.mapValue())

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

fun <O, V> TypedPath<O, V>.bind(resource: ResourceId): BoundPath<V> = BoundPath(ValueLocation.of(resource, path), expected)

@GeneratedSdkApi
fun <O, V> typedPath(
    owner: TypeDefinitionId,
    path: ValuePath,
    expected: TypeUse,
): TypedPath<O, V> = TypedPath(owner, path, expected)

@GeneratedSdkApi
fun <V> boundPath(
    location: ValueLocation,
    expected: TypeUse,
): BoundPath<V> = BoundPath(location, expected)

@GeneratedSdkApi
fun boundCollectionPath(location: ValueLocation): BoundCollectionPath = BoundCollectionPath(location)
