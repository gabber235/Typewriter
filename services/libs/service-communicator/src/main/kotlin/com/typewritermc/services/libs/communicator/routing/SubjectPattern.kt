package com.typewritermc.services.libs.communicator.routing

class SubjectPattern(private val pattern: String) {
    private val paramRegex = Regex("""\{([^}]+)\}""")

    private val paramNames: List<String> = paramRegex.findAll(pattern)
        .map { it.groupValues[1] }
        .toList()

    val subscriptionSubject: String = paramRegex.replace(pattern, "*")

    private val matchRegex: Regex = Regex(
        "^" + pattern
            .replace(".", "\\.")
            .let { paramRegex.replace(it, "([^.]+)") } + "$"
    )

    fun matches(subject: String): Boolean = matchRegex.matches(subject)

    fun extractParams(subject: String): Map<String, String> {
        val match = matchRegex.matchEntire(subject) ?: return emptyMap()
        return paramNames.zip(match.groupValues.drop(1)).toMap()
    }
}
