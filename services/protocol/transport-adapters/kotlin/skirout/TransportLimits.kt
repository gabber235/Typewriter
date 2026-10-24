package com.typewritermc.protocol.transport.generated

import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** Reply framing limits of the transport route manifest: frame size and frames per reply. */
val TRANSPORT_LIMITS = TransportLimits(chunkBytes = 524288, maxChunks = 64)

/** How long a responder may send replies after it received a request, so no requester waits longer. */
val TRANSPORT_REPLY_TTL: Duration = 300000.milliseconds
