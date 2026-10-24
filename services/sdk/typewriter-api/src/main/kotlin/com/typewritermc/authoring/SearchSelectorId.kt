package com.typewritermc.authoring

@JvmInline
value class SearchSelectorId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Search selector ids must not be blank." }
    }
}
