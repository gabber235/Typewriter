package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.transfer.PayloadFrame
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import kotlin.random.Random
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/** Address of the requests the frame property and vector tests send. */
val frameRequest: MessageAddress = MessageAddress.of("service.to.quests.organization.writers.realm.shared.blob.store")

/** Limits of a frame test route: [chunkBytes] per frame, two frames per window, and replies that wait for credit. */
fun frameLimits(
    chunkBytes: Int,
    maxBytes: Long,
): TransportLimits =
    TransportLimits(
        chunkBytes = chunkBytes,
        windowFrames = 2,
        requestMaxBytes = maxBytes,
        replyMaxBytes = maxBytes,
        frameInactivity = 5.seconds,
        replyTtl = 5.minutes,
        replyCredit = true,
    )

/** The inbound message [PayloadFrame] arrives as on [frameRequest], with the frame's payload and headers. */
internal fun PayloadFrame.toInbound(): InboundMessage = InboundMessage(frameRequest, payload, headers = headers)

/** Seeded random bytes of [size], so a generated case reproduces from its seed alone. */
fun seededBytes(
    size: Int,
    seed: Long,
): ByteArray = Random(seed).nextBytes(size)
