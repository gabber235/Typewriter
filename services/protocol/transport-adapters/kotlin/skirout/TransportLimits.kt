package com.typewritermc.protocol.transport.generated

import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import kotlin.time.Duration.Companion.milliseconds

/** Payload framing limits of the transport route manifest; routes whose limits differ carry their own. */
val TRANSPORT_LIMITS =
    TransportLimits(
        chunkBytes = 524288,
        windowFrames = 8,
        requestMaxBytes = 524288,
        replyMaxBytes = 33554432,
        frameInactivity = 30000.milliseconds,
        replyTtl = 300000.milliseconds,
        replyCredit = false,
    )
