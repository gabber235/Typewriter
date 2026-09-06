package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.result.CommunicationResult

/**
 * Fails when the transport did not accept a required update publication.
 *
 * Successful return confirms publication only, not processing by subscribers.
 */
internal fun CommunicationResult<Unit>.requirePublished() {
    if (this is CommunicationResult.Failure) error("Watch publication failed: $error")
}
