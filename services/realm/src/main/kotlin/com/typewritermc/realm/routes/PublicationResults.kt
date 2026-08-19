package com.typewritermc.realm.routes

import com.typewritermc.services.libs.communicator.result.CommunicationResult

internal fun CommunicationResult<Unit>.requirePublished() {
    if (this is CommunicationResult.Failure) error("Watch publication failed: $error")
}
