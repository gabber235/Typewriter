package com.typewritermc.library

import com.typewritermc.presentation.CollectionProjection
import com.typewritermc.presentation.TypewriterCollectionProjection
import com.typewritermc.presentation.collectionProjection
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.DataValue

const val TAG_COLLECTION_SOURCE_ID: String = "typewriter.tags"

@TypewriterCollectionProjection
fun coreTagCollectionProjection(): CollectionProjection<Tag, TagCollectionRow, TagCollectionRowExpressions> =
    collectionProjection<Tag, TagCollectionRow, TagCollectionRowExpressions>(
        sourceId = TAG_COLLECTION_SOURCE_ID,
        root = TagDefinition.id.namedTemplate(),
        rowType = TagCollectionRowDefinition.id.template(),
        expressions = TagCollectionRowExpressionsFactory,
    ) {
        content(TagCollectionRowFields.name, TagFields.name)
        content(TagCollectionRowFields.color, TagFields.color)
        content(TagCollectionRowFields.parents, TagFields.parents)
        literal(TagCollectionRowFields.selectable, DataValue.BooleanWrapper(true))
    }
