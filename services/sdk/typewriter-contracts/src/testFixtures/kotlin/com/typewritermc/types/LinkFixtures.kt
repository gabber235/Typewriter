package com.typewritermc.types

import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.LinkValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** A link to the resource [target] whose opposite end sits at its field [opposite], or nowhere when null. */
fun linkTo(
    target: String,
    opposite: String?,
): DataValue =
    DataValue.LinkWrapper(
        LinkValue(
            endpoint = EndpointId(value = "test:reference#first"),
            target =
                LinkTarget(
                    resource = ResourceId(value = target),
                    opposite = opposite?.let { ValuePath(segments = listOf(PathSegment.createField(name = it))) },
                ),
        ),
    )

/** A bare set value holding [values] as authored, each under an item id named after its position. */
fun setValueOf(vararg values: DataValue): DataValue =
    DataValue.setValue(values.mapIndexed { index, value -> ListItem(id = ItemId(value = "item-$index"), value = value) })

/** A record holding a link to any resource, as an author's resource holds one. */
@Serializable
data class LinkHolder(
    val link: Ref<RelationshipEndpoint<Resource, Resource>, Resource>,
)

/** A resource generic in its rows, so a link that admits every one of them names it with a star. */
@Serializable
data class RowsResource<V>(
    val rows: List<V> = emptyList(),
) : Resource

/** A record holding a link to any [RowsResource], whatever its rows, as an author's resource holds one. */
@Serializable
data class StarLinkHolder(
    val link: Ref<RelationshipEndpoint<Resource, Resource>, RowsResource<*>>,
)
