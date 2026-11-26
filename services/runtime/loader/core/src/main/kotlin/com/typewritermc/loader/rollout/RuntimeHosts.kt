package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.artifact.PublicationBlobRetention
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.api.work.RuntimeWork
import com.typewritermc.loader.api.work.WorkRuntime
import com.typewritermc.loader.work.HostWork
import com.typewritermc.loader.work.counted
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/** The host as the runtimes it stages see it: each runtime gets its own view, whose work counts as that runtime's. */
interface RuntimeHosts {
    /** The host's work in flight, every runtime's included, and how long a drain of it waits. */
    val work: HostWork

    /** The host as [runtime] sees it, until the view closes once the runtime closed. */
    fun open(runtime: WorkRuntime): RuntimeHost
}

/** The host one staged runtime sees: its tasks and outbound operations count in [work] as [runtime]'s. */
interface RuntimeHost :
    HostedRuntimeHost,
    AutoCloseable {
    val runtime: WorkRuntime
}

/**
 * The views of one assignment's host: each counts the current session's outbound operations and the shared
 * artifacts' operations in [work] as its runtime's, and follows every session [follow] hands it until it closes.
 */
internal class SessionRuntimeHosts(
    override val work: HostWork,
    private val sharedArtifacts: SharedArtifactAccess,
    private val openTelemetry: OpenTelemetry,
    private val publicationRetention: PublicationBlobRetention?,
) : RuntimeHosts {
    // One lock orders follow against open and close, so no view keeps a session the host already replaced.
    private val lock = Any()
    private val views = mutableSetOf<View>()
    private var current: HostedMessagingSession? = null

    /** Every open view now borrows [session], counted as its runtime's. */
    fun follow(session: HostedMessagingSession?) =
        synchronized(lock) {
            current = session
            views.forEach { it.follow(session) }
        }

    override fun open(runtime: WorkRuntime): RuntimeHost =
        synchronized(lock) {
            View(runtime).also { view ->
                view.follow(current)
                views += view
            }
        }

    private inner class View(
        override val runtime: WorkRuntime,
    ) : RuntimeHost {
        override val work: RuntimeWork = this@SessionRuntimeHosts.work.inFlight.of(runtime)
        private val session = MutableStateFlow<HostedMessagingSession?>(null)
        override val messaging: StateFlow<HostedMessagingSession?> = session.asStateFlow()
        override val sharedArtifacts: SharedArtifactAccess = this@SessionRuntimeHosts.sharedArtifacts.counted(work)
        override val openTelemetry: OpenTelemetry get() = this@SessionRuntimeHosts.openTelemetry
        override val publicationRetention get() = this@SessionRuntimeHosts.publicationRetention

        fun follow(current: HostedMessagingSession?) {
            session.value = current?.counted(work)
        }

        override fun close() {
            synchronized(lock) { views -= this }
        }
    }
}
