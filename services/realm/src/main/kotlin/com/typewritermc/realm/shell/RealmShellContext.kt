package com.typewritermc.realm.shell

import com.typewritermc.realm.REALM_VERSION
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import kotlinx.coroutines.flow.StateFlow
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration
import kotlin.time.TimeSource

class RealmShellContext(
    val registrarStates: StateFlow<RegistrarSnapshot>,
    timeSource: TimeSource,
) {
    private val startedAt = timeSource.markNow()
    private val stopRequested = AtomicBoolean(false)

    val version: String get() = REALM_VERSION
    val uptime: Duration get() = startedAt.elapsedNow()
    val registrarSnapshot: RegistrarSnapshot get() = registrarStates.value

    fun requestStop() {
        stopRequested.set(true)
    }

    fun isStopRequested(): Boolean = stopRequested.get()
}
