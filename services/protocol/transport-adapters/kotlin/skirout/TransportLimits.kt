package com.typewritermc.protocol.transport.generated

import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** Payload framing limits of the transport route manifest; routes that raise a ceiling carry their own. */
val TRANSPORT_LIMITS =
    TransportLimits(
        chunkBytes = 524288,
        windowFrames = 8,
        requestMaxBytes = 524288,
        replyMaxBytes = 33554432,
    )

/** How long a responder may send replies after it received a request, so no requester waits longer. */
val TRANSPORT_REPLY_TTL: Duration = 300000.milliseconds
