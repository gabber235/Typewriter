package com.typewritermc.services.libs.communicator.nats

/** Authentication values supported by a NATS CONNECT operation. */
data class NatsAuthentication(
    val authToken: String? = null,
    val username: String? = null,
    val password: String? = null,
    val jwt: String? = null,
    val signature: String? = null,
    val nkey: String? = null,
) {
    init {
        require(listOf(authToken, username, password, jwt, signature, nkey).all { it == null || it.isNotBlank() }) {
            "NATS authentication values must not be blank"
        }
    }
}

/** Safe access to the current server nonce challenge. */
class NatsAuthenticationChallenge internal constructor(
    val hasNonce: Boolean,
    private val signer: suspend (String) -> String?,
) {
    /** Signs the current server nonce with [nkeySeed], or returns null when no nonce was supplied. */
    suspend fun signNonce(nkeySeed: String): String? {
        require(nkeySeed.isNotBlank()) { "NKey seed must not be blank" }
        return signer(nkeySeed)
    }
}

/** Supplies fresh CONNECT authentication for every NATS handshake. */
fun interface NatsAuthenticationProvider {
    suspend fun authenticate(challenge: NatsAuthenticationChallenge): NatsAuthentication
}
