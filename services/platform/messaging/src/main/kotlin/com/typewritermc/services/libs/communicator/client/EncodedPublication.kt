package com.typewritermc.services.libs.communicator.client

import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.transport.Payload

/** An immutable, already encoded publication without request or header capabilities. */
data class EncodedPublication(
    val address: MessageAddress,
    val payload: Payload,
)
