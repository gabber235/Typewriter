package com.typewritermc.codegen

/**
 * This Kotlin identifier as words in sentence case, for display defaults derived from declaration names:
 * `SequencePage` becomes `Sequence page` and `NPCRoster` becomes `NPC roster`. Acronyms keep their capitals.
 */
internal fun String.sentenceCase(): String {
    val words = WORD.findAll(this).map { it.value }.toList()
    if (words.isEmpty()) return this
    return words
        .mapIndexed { index, word ->
            when {
                word.length > 1 && word.all(Char::isUpperCase) -> word
                index == 0 -> word.replaceFirstChar(Char::uppercaseChar)
                else -> word.lowercase()
            }
        }.joinToString(" ")
}

/** An acronym before a capitalized word, a capitalized or lower case word, or a run of digits. */
private val WORD = Regex("[A-Z]+(?=[A-Z][a-z])|[A-Z]?[a-z]+|[A-Z]+|[0-9]+")
