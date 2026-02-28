package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.JwtProvider
import com.typewritermc.services.libs.communicator.JwtProvisionException
import com.typewritermc.services.libs.communicator.TokenInfo
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger

/**
 * Implementation of JwtProvider that uses JwtExchanger.
 *
 * This bridges the service-registrar's credential/JWT exchange
 * with the service-communicator's JWT needs.
 *
 * @param credentialProvider Function that returns the current credential (may be null if not initialized)
 * @param jwtExchanger The exchanger used to convert credentials to JWT tokens
 */
class JwtProviderImpl(
    private val credentialProvider: () -> Credential?,
    private val jwtExchanger: JwtExchanger
) : JwtProvider {
    private val logger: KLogger = logger {}

    override fun getJwt(): String {
        return getTokenInfo().accessToken
    }

    override fun getTokenInfo(): TokenInfo {
        val credential = credentialProvider()
            ?: throw JwtProvisionException("Credentials not initialized. ServiceRegistrar.initialize() must be called first.")

        return try {
            val response = jwtExchanger.exchangeForJwt(credential)
            TokenInfo(
                accessToken = response.accessToken,
                expiresInSeconds = response.expiresIn,
                tokenType = response.tokenType
            )
        } catch (e: JwtExchangeException) {
            throw JwtProvisionException("Failed to exchange credential for JWT: ${e.message}", e)
        }
    }
}
