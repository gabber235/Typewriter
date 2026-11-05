package com.typewritermc.services.libs.registrar.console

import com.github.ajalt.mordant.rendering.TextColors.blue
import com.github.ajalt.mordant.rendering.TextColors.gray
import com.github.ajalt.mordant.rendering.TextStyles.bold
import com.github.ajalt.mordant.terminal.Terminal
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.collect

/** Receives a binding token for explicit display to the operator. */
fun interface BindingTokenOutput {
    /** Displays a registration token without assuming ownership of its lifetime. */
    fun display(token: String)

    /** The displayed token is no longer pending: the service was bound or registration stopped. */
    fun cleared() {}
}

/** Displays each changed binding token from registrar state and reports when no token is pending anymore. */
class RegistrarConsoleObserver(
    private val output: BindingTokenOutput,
) {
    /** Collects until cancelled, suppressing a pending token when it matches the most recently displayed token. */
    suspend fun observe(states: Flow<RegistrarSnapshot>) {
        var displayed: String? = null
        states.collect { snapshot ->
            val awaiting = snapshot.state as? RegistrarState.AwaitingBinding
            if (awaiting == null) {
                if (displayed != null) {
                    displayed = null
                    output.cleared()
                }
                return@collect
            }
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
