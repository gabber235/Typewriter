package com.typewritermc.library

import com.typewritermc.presentation.collectionRelation
import com.typewritermc.presentation.presentationCollection

internal val tagInheritanceRelation =
    collectionRelation(TAG_INHERITS_RELATION_ID, TagCollectionRow::parents)

internal val tagCollection =
    presentationCollection(
        sourceId = TAG_COLLECTION_SOURCE_ID,
        key = TagCollectionRow::key,
        selectability = TagCollectionRow::selectable,
        tagInheritanceRelation,
    )
