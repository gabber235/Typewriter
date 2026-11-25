package com.typewritermc.engine.panel

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.protocol.transport.OrganizationActorRouteScope
import com.typewritermc.protocol.transport.everyMemberOf
import com.typewritermc.protocol.transport.generated.organizationPresence
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.organization.v1.presence.PresenceEvent
import skirout.organization.v1.presence.PresenceLocation
import java.time.Clock
import java.time.Instant
import kotlin.time.ComparableTimeMark
import kotlin.time.TimeSource

/**
 * The panel tabs in this engine's Realm, each a session of the tab's user, from the panel's presence heartbeat; there
 * is no second heartbeat. The first heartbeat in the Realm adds the tab's session, connected at that instant, and each
 * later one moves its deadline a key's time to live ahead. A tab that leaves the Realm or says it left is removed at once, and a tab whose
 * deadline passes is removed then, so its session ends after the vacancy. The protagonist is the user the broker bound
 * into the subject, never a value from the payload.
 *
 * Deadlines are kept here, not by the messaging session presence arrives through: one expiry loop in [deployment], the
 * engine's own lifetime, removes every tab past its deadline, so a messaging session the host replaces changes nothing
 * about when a tab leaves, and the loop ends with the deployment.
 */
class PresenceSessions(
    private val realmId: String,
    private val timings: SessionTimings,
    deployment: CoroutineScope,
    private val time: TimeSource.WithComparableMarks = TimeSource.Monotonic,
    private val clock: Clock = Clock.systemUTC(),
) : OnlineSessions {
    /** The open tabs, each with its deadline; changed only under its own lock, together with [open]. */
    private val tabs = HashMap<SessionId, Tab>()
    private val open = MutableStateFlow<Map<Session, Instant>>(emptyMap())

    override val sessions: StateFlow<Map<Session, Instant>> = open.asStateFlow()

    // Every deadline is set a time to live after its heartbeat, so a new one is never earlier than the one the loop waits
    // for: a tab whose deadline moved is found unexpired and the loop waits for the next earliest.
    init {
        deployment.launch {
            while (true) {
                val next = synchronized(tabs) { tabs.values.minOfOrNull { it.deadline } }
                if (next == null) {
                    open.first { it.isNotEmpty() }
                } else {
                    delay(next - time.markNow())
                    expire()
                }
            }
        }
    }

    /** Receives the presence of every member of [messaging]'s organization until cancelled. */
    suspend fun serve(messaging: HostedMessagingSession): Unit =
        coroutineScope {
            val presence =
                OrganizationActorRouteScope(
                    messaging.organizationId,
                    ANY_MEMBER,
                ).organizationPresence.everyMemberOf(messaging.organizationId)
            val router =
                messaging.communicator.createRouter(
                    communicatorRoutes { event(presence) { call -> receive(call.address.userId, call.event) } },
                    this,
                )
            val started = router.start()
            check(started == RouterResult.Success) { "The presence router could not start: $started" }
            try {
                awaitCancellation()
            } finally {
                withContext(NonCancellable) { router.stop() }
            }
        }

    private fun receive(
        userId: String,
        event: PresenceEvent,
    ) {
        when (event) {
            is PresenceEvent.ActiveWrapper -> {
                val tab = SessionId(event.value.sessionId)
                if (event.value.location.isIn(
                        realmId,
                    )
                ) {
                    heartbeat(Session(Protagonist(PrincipalId(PrincipalId.USER, userId)), tab))
                } else {
                    end(tab)
                }
            }

            is PresenceEvent.LeftWrapper -> {
                end(SessionId(event.value.sessionId))
            }

            else -> {
                Unit
            }
        }
    }

    private fun heartbeat(session: Session) {
        synchronized(tabs) {
            tabs[session.id] = Tab(session, tabs[session.id]?.connected ?: clock.instant(), time.markNow() + timings.lease.ttl)
            publish()
        }
    }

    private fun end(tab: SessionId) {
        synchronized(tabs) {
            if (tabs.remove(tab) != null) publish()
        }
    }

    private fun expire() {
        synchronized(tabs) {
            if (tabs.values.removeAll { it.deadline.hasPassedNow() }) publish()
        }
    }

    private fun publish() {
        open.value = tabs.values.associate { it.session to it.connected }
    }

    private class Tab(
        val session: Session,
        val connected: Instant,
        val deadline: ComparableTimeMark,
    )

    private companion object {
        /** The member of an organization actor scope whose value a subscription to every member leaves open. */
        const val ANY_MEMBER = "member"
    }
}

/** Whether a panel tab at this location is in Realm [realmId]: on the Realm itself or on one of its resources. */
private fun PresenceLocation.isIn(realmId: String): Boolean =
    when (this) {
        is PresenceLocation.RealmWrapper -> value.realmId.isRealm(realmId)
        is PresenceLocation.ResourceWrapper -> value.realmId.isRealm(realmId)
        else -> false
    }

private fun RecordId.isRealm(realmId: String): Boolean = (key as? RecordIdKey.StringWrapper)?.value == realmId

/** Serves [presence] through every messaging session the host lends this engine, one at a time. */
class PresenceSessionsRegistrar(
    private val host: HostedRuntimeHost,
    private val presence: PresenceSessions,
) : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        scope.coroutineScope.launch { host.messaging.collectLatest { messaging -> messaging?.let { presence.serve(it) } } }
    }
}
