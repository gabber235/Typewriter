package com.typewritermc.playtest

/** The test JVM's console, where the framework notes what passes yet needs a reader's eye, such as a quarantined failure. */
internal object Console {
    /**
     * Writes [text] as a line of the console.
     *
     * The test JVM's standard error is the framework's only console; Gradle shows it beside the test.
     */
    @Suppress("ForbiddenMethodCall")
    fun line(text: String) = System.err.println(text)
}
