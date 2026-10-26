package com.typewritermc.services.libs.registrar.console

import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RegistrationToken
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import kotlinx.coroutines.flow.flowOf

private val identity =
    ServiceIdentity(
        ServiceId("service-id"),
        "Service Name",
        "service-user",
        ServiceRole.Custom("realm", "1.0.0"),
    )

val RegistrarConsoleObserverTest by testSuite {
    test("displays only changed non-null binding tokens") {
        val displayed = mutableListOf<String>()
        val observer = RegistrarConsoleObserver(displayed::add)
        observer.observe(
            flowOf(
                RegistrarSnapshot(1, 0, RegistrarState.AwaitingBinding(identity, null)),
                RegistrarSnapshot(2, 0, RegistrarState.AwaitingBinding(identity, RegistrationToken("TOKEN12345"))),
                RegistrarSnapshot(3, 0, RegistrarState.AwaitingBinding(identity, RegistrationToken("TOKEN12345"))),
                RegistrarSnapshot(4, 0, RegistrarState.AwaitingBinding(identity, RegistrationToken("OTHER12345"))),
            ),
        )
        displayed.shouldContainExactly("TOKEN12345", "OTHER12345")
    }

    test("a pending registration token is cleared once bound") {
        val shown = ShownTokens()
        RegistrarConsoleObserver(shown).observe(
            flowOf(
                RegistrarSnapshot(1, 0, RegistrarState.AwaitingBinding(identity, RegistrationToken("TOKEN12345"))),
                RegistrarSnapshot(
                    2,
                    0,
                    RegistrarState.Ready(ReadySession(identity, OrganizationBinding("organization", "Organization")), 1),
                ),
            ),
        )
        shown.history.shouldContainExactly("TOKEN12345", null)
    }
}

/** What an operator sees over time: each displayed token, and null once the display is cleared. */
private class ShownTokens : BindingTokenOutput {
    val history = mutableListOf<String?>()

    override fun display(token: String) {
        history += token
    }

    override fun cleared() {
        history += null
    }
}
