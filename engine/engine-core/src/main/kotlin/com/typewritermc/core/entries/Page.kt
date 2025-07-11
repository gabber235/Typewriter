package com.typewritermc.core.entries

import com.typewritermc.core.books.pages.PageType
import kotlinx.serialization.Serializable

// Could be @Serializable, but error reporting would be "worse"
data class Page(
    val id: String = "",
    val name: String = "",
    val entries: List<Entry> = emptyList(),
    val type: PageType = PageType.SEQUENCE,
    val priority: Int = 0
)