package com.typewritermc.library

import com.typewritermc.presentation.CollectionProjection
import com.typewritermc.presentation.TypewriterCollectionProjection
import com.typewritermc.presentation.collectionProjection
import com.typewritermc.types.DataValue
import com.typewritermc.types.TypeTemplate

const val TAG_COLLECTION_SOURCE_ID: String = "typewriter.tags"

@TypewriterCollectionProjection
fun coreTagCollectionProjection(): CollectionProjection<Tag, TagCollectionRow, TagCollectionRowExpressions> =
    collectionProjection<Tag, TagCollectionRow, TagCollectionRowExpressions>(
        sourceId = TAG_COLLECTION_SOURCE_ID,
        root = TypeTemplate.Named(TagDefinition.id),
        rowType = TypeTemplate.Named(TagCollectionRowDefinition.id),
        expressions = TagCollectionRowExpressions::class,
    ) {
        content(TagCollectionRowFields.name, TagFields.name)
        content(TagCollectionRowFields.color, TagFields.color)
        content(TagCollectionRowFields.parents, TagFields.parents)
        literal(TagCollectionRowFields.selectable, DataValue.Boolean(true))
    }
