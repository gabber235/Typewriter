package com.typewritermc.engine.panel

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.identity.SessionReporter
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.protocol.transport.OrganizationActorRouteScope
import com.typewritermc.protocol.transport.everyMemberOf
import com.typewritermc.protocol.transport.generated.organizationPresence
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.organization.v1.presence.PresenceEvent
import skirout.organization.v1.presence.PresenceLocation
import java.util.concurrent.ConcurrentHashMap

/**
 * Reports each panel tab in this engine's Realm as a session of the tab's user, from the panel's presence heartbeat;
 * there is no second heartbeat. The first heartbeat in the Realm connects the tab's session, and each later one keeps
 * it. A tab that leaves the Realm or says it left disconnects at once, and a tab whose heartbeats stop for a key's
 * time to live disconnects then, so its session ends after the vacancy. The protagonist is the user the broker bound into
 * the subject, never a value from the payload.
 */
class PresenceSessions(
    private val realmId: String,
    private val sessions: SessionReporter,
    private val timings: LeaseTimings,
) {
    private val tabs = ConcurrentHashMap<SessionId, Job>()

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
                    communicatorRoutes { event(presence) { call -> receive(this@coroutineScope, call.address.userId, call.event) } },
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
        scope: CoroutineScope,
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
                    heartbeat(scope, Protagonist(PrincipalId(PrincipalId.USER, userId)), tab)
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

    private fun heartbeat(
        scope: CoroutineScope,
        protagonist: Protagonist,
        tab: SessionId,
    ) {
        val silence =
            scope.launch {
                delay(timings.ttl)
                if (tabs.remove(tab, coroutineContext[Job])) sessions.disconnected(tab)
            }
        val previous = tabs.put(tab, silence)
        if (previous == null) sessions.connected(protagonist, tab) else previous.cancel()
    }

    private fun end(tab: SessionId) {
        tabs.remove(tab)?.let {
            it.cancel()
            sessions.disconnected(tab)
        }
    }

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
