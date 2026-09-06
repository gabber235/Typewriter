package com.typewritermc.services.libs.communicator.nats

/** Authentication values supported by a NATS CONNECT operation. */
class NatsAuthentication(
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

    override fun equals(other: Any?): Boolean =
        other is NatsAuthentication &&
            authToken == other.authToken && username == other.username && password == other.password &&
            jwt == other.jwt && signature == other.signature && nkey == other.nkey

    override fun hashCode(): Int {
        var result = authToken.hashCode()
        result = 31 * result + username.hashCode()
        result = 31 * result + password.hashCode()
        result = 31 * result + jwt.hashCode()
        result = 31 * result + signature.hashCode()
        return 31 * result + nkey.hashCode()
    }

    override fun toString(): String = "NatsAuthentication([REDACTED])"
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
