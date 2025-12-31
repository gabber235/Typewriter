package com.typewritermc.realm.shell

import com.typewritermc.realm.REALM_VERSION
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import java.time.Instant
import java.util.concurrent.atomic.AtomicBoolean

class RealmShellContext(
    val startTime: Instant = Instant.now(),
) {
    private val stopRequested = AtomicBoolean(false)

    val version: String get() = REALM_VERSION

    fun requestStop() {
        stopRequested.set(true)
    }

    fun isStopRequested(): Boolean = stopRequested.get()
}
