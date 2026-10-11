package com.typewritermc.library

import com.typewritermc.types.Color
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "9e9eaf947ed848a69fd1bbfc66cb13eb")
data class TagCollectionRow(
    val name: String,
    val color: Color,
    val parents: Set<Ref<TagParents.Child, Tag>>,
    val selectable: Boolean,
)
