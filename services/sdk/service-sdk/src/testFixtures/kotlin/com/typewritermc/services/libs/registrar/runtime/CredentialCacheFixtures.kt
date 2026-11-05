package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.registrar.RedactedSecret
import io.kotest.matchers.types.shouldBeInstanceOf

/** Answers each call with the next scripted result and counts the calls. */
class ScriptedCalls<T>(
    vararg results: T,
) {
    private val remaining = ArrayDeque(results.toList())
    var calls = 0
        private set

    fun next(): T {
        calls++
        return checkNotNull(remaining.removeFirstOrNull()) { "No result scripted for call $calls" }
    }
}

fun token(value: String) = AccessTokenResult.Success(RedactedSecret.AccessToken(value), expiresInSeconds = 60)

fun sentinel(jwt: String) =
    SentinelResult.Success(SentinelCredentials(RedactedSecret.SentinelJwt(jwt), RedactedSecret.SentinelSeed("seed")))

fun AccessTokenResult.revealed() = shouldBeInstanceOf<AccessTokenResult.Success>().token.reveal()

fun SentinelResult.jwt() = shouldBeInstanceOf<SentinelResult.Success>().credentials.jwt.reveal()
