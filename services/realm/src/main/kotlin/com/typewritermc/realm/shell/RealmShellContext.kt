package com.typewritermc.realm.shell

import com.typewritermc.realm.REALM_VERSION
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.utils.StateProvider
import java.time.Instant
import java.util.concurrent.atomic.AtomicBoolean

class RealmShellContext(
    val startTime: Instant = Instant.now(),
    val registrationStateProvider: StateProvider<RegistrationState>,
) {
    private val stopRequested = AtomicBoolean(false)

    val version: String get() = REALM_VERSION

    fun requestStop() {
        stopRequested.set(true)
    }

    fun isStopRequested(): Boolean = stopRequested.get()
}
