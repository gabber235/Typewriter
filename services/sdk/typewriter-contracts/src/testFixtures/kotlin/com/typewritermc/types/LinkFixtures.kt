package com.typewritermc.types

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
