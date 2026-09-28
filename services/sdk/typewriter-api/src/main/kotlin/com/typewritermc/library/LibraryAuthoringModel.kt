package com.typewritermc.library

import com.typewritermc.types.Color
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterType

/** Canonical Realm projection consumed by tag lookup, search, and inheritance graph presentations. */
@TypewriterType(id = "9e9eaf947ed848a69fd1bbfc66cb13eb")
data class TagCollectionRow(
    val key: Ref<Tag>,
    val name: String,
    val color: Color,
    val parents: List<Ref<Tag>>,
    val selectable: Boolean,
)

const val TAG_COLLECTION_SOURCE_ID = "realm.tags"
const val TAG_INHERITS_RELATION_ID = "inherits"
