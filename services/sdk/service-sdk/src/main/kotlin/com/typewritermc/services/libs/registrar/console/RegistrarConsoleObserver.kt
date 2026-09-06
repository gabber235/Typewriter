package com.typewritermc.services.libs.registrar.console

import com.github.ajalt.mordant.rendering.TextColors.blue
import com.github.ajalt.mordant.rendering.TextColors.gray
import com.github.ajalt.mordant.rendering.TextStyles.bold
import com.github.ajalt.mordant.terminal.Terminal
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collect

/** Receives an operator-visible binding token. */
fun interface BindingTokenOutput {
    fun display(token: String)
}

/** Displays each changed binding token from registrar state. */
class RegistrarConsoleObserver(
    private val output: BindingTokenOutput,
) {
    suspend fun observe(states: Flow<RegistrarSnapshot>) {
        var displayed: String? = null
        states.collect { snapshot ->
            val awaiting = snapshot.state as? RegistrarState.AwaitingBinding ?: return@collect
            val token = awaiting.registrationToken?.reveal() ?: return@collect
            if (token == displayed) return@collect
            displayed = token
            output.display(token)
        }
    }
}

/** Mordant output for interactive service binding. */
class MordantBindingTokenOutput(
    private val terminal: Terminal = Terminal(),
) : BindingTokenOutput {
    override fun display(token: String) {
        val title = (bold + blue)("SERVICE REGISTRATION")
        val tokenLine = (bold + blue)(token)
        terminal.println()
        terminal.println(title)
        terminal.println("Registration Token: $tokenLine")
        terminal.println("Enter this token in the Typewriter Panel to bind this service.")
        terminal.println(gray("The token is refreshed while registration is pending."))
        terminal.println()
    }
}
