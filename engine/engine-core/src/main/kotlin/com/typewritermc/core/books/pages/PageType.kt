package com.typewritermc.core.books.pages

import kotlinx.serialization.SerialName

enum class PageType(val id: String) {
    @SerialName("sequence")
    SEQUENCE("sequence"),

    @SerialName("static")
    STATIC("static"),

    @SerialName("cinematic")
    CINEMATIC("cinematic"),

    @SerialName("manifest")
    MANIFEST("manifest"),
    ;

    companion object {
        fun fromId(id: String) = entries.firstOrNull { it.id == id }
    }
}