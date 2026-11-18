package com.typewritermc.realm.session

import com.typewritermc.failures.rethrowExceptional
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.protocol.transport.generated.SessionsBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.RetryPolicy
import kotlinx.coroutines.delay

/**
 * Creates the Realm's sessions bucket through each messaging session, since only the Realm's coordinator may create
 * it. Engines tolerate a missing bucket and write their sessions once it exists, so creation runs beside the routes
 * and never delays them; a failed attempt is reported and retried for as long as the session stays current. Its
 * retries wait on their own and never take a turn of the Realm's route retries.
 */
internal class RealmSessionsBucket(
    private val realmId: String,
    private val telemetry: ServiceTelemetry,
    private val retryPolicy: RetryPolicy,
) {
    suspend fun ensure(session: HostedMessagingSession) {
        var retry = 0L
        while (true) {
            try {
                telemetry.mainSpan(
                    name = "realm.sessions.bucket.ensure",
                    unhandledFailureSlug = ErrorSlug.of("realm-sessions-bucket-failed"),
                ) {
                    when (val opened = session.buckets.ensure(SessionsBucket.declaration(realmId))) {
                        is KeyValueOpen.Opened -> Unit
                        is KeyValueOpen.Failed -> throw IllegalStateException("The sessions bucket could not be created", opened.cause)
                        KeyValueOpen.Missing -> error("The sessions bucket is missing after it was created")
                    }
                }
                return
            } catch (failure: Throwable) {
                failure.rethrowExceptional()
                delay(retryPolicy.delayFor(retry++, 0.5))
            }
        }
    }
}
