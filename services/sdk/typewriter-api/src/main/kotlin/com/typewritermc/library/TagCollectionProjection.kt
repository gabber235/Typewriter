package com.typewritermc.library

import com.typewritermc.presentation.CollectionProjectionSpec
import com.typewritermc.presentation.PresentationBuildContext
import com.typewritermc.presentation.TypewriterCollectionProjection
import com.typewritermc.presentation.collectionProjection
import com.typewritermc.types.DataValue

@TypewriterCollectionProjection
context(_: PresentationBuildContext)
fun coreTagCollectionProjection(): CollectionProjectionSpec<Tag, TagCollectionRow> =
    collectionProjection(TAG_COLLECTION_SOURCE_ID, CoreResourceDefinitionIds.TAG.value) {
        resourceId(TagCollectionRow::key)
        content(TagCollectionRow::name, Tag::name)
        content(TagCollectionRow::color, Tag::color)
        content(TagCollectionRow::parents, Tag::parents)
        literal(TagCollectionRow::selectable, DataValue.Boolean(true))
    }
