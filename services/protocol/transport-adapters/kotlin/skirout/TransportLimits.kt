package com.typewritermc.protocol.transport.generated

import com.typewritermc.services.libs.communicator.transfer.TransportLimits

/** Reply framing limits of the transport route manifest: frame size and frames per reply. */
val TRANSPORT_LIMITS = TransportLimits(chunkBytes = 524288, maxChunks = 64)
