package com.typewritermc.services.libs.communicator

/**
 * Interface for providing JWT tokens for NATS authentication.
 *
 * This interface is defined in service-communicator but implemented
 * in service-registrar to avoid circular dependencies. The implementation
 * is late-registered via Koin after credentials are initialized.
 *
 * The implementation should handle:
 * - Token exchange via OAuth2
 * - Error handling for failed exchanges
 */
interface JwtProvider {
    /**
     * Get a fresh JWT token for NATS authentication.
     *
     * @return A valid JWT access token string
     * @throws JwtProvisionException if token cannot be obtained
     */
    fun getJwt(): String

    /**
     * Get the full token response including metadata.
     *
     * @return TokenInfo with access token and expiration info
     * @throws JwtProvisionException if token cannot be obtained
     */
    fun getTokenInfo(): TokenInfo
}

/**
 * Token information including access token and metadata.
 */
data class TokenInfo(
    val accessToken: String,
    val expiresInSeconds: Long,
    val tokenType: String
)

/**
 * Exception thrown when JWT provision fails.
 */
class JwtProvisionException(
    message: String,
    cause: Throwable? = null
) : RuntimeException(message, cause)
