package com.typewritermc.realm.shell

import com.typewritermc.realm.REALM_VERSION
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import kotlinx.coroutines.flow.StateFlow
import java.time.Instant
import java.util.concurrent.atomic.AtomicBoolean

class RealmShellContext(
    val startTime: Instant = Instant.now(),
    val registrarStates: StateFlow<RegistrarSnapshot>,
) {
    private val stopRequested = AtomicBoolean(false)

    val version: String get() = REALM_VERSION
    val registrarSnapshot: RegistrarSnapshot get() = registrarStates.value

    fun requestStop() {
        stopRequested.set(true)
    }

    fun isStopRequested(): Boolean = stopRequested.get()
}
