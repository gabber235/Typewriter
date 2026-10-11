package com.typewritermc.library

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.elements.Cue
import com.typewritermc.elements.Element

private const val BOOK_ID = "typewriter.book"
private const val TAG_ID = "typewriter.tag"
private const val PAGE_ID = "typewriter.page"
private const val ELEMENT_ID = "typewriter.element"
private const val CUE_ID = "typewriter.cue"

/** Stable ids of the resources supplied by the core library. */
object CoreResourceDefinitionIds {
    @TypewriterResourceDefinition(BOOK_ID, Book::class, "typewriter.book")
    val BOOK = ResourceDefinitionId(BOOK_ID)

    @TypewriterResourceDefinition(TAG_ID, Tag::class, "typewriter.tags")
    val TAG = ResourceDefinitionId(TAG_ID)

    @TypewriterResourceDefinition(PAGE_ID, Page::class, "typewriter.page")
    val PAGE = ResourceDefinitionId(PAGE_ID)

    @TypewriterResourceDefinition(ELEMENT_ID, Element::class, "typewriter.page-element")
    val ELEMENT = ResourceDefinitionId(ELEMENT_ID)

    @TypewriterResourceDefinition(CUE_ID, Cue::class, "typewriter.page-element")
    val CUE = ResourceDefinitionId(CUE_ID)
}
