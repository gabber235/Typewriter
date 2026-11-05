package com.typewritermc.services.libs.registrar.console

/** A token output that records each displayed token, and null once the display is cleared. */
class ShownTokens : BindingTokenOutput {
    val history = mutableListOf<String?>()

    override fun display(token: String) {
        history += token
    }

    override fun cleared() {
        history += null
    }
}
