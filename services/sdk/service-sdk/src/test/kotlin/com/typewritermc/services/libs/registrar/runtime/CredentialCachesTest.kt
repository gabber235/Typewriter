package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.registrar.AccessTokenFailureReason
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.RedactedSecret
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.SentinelFailureReason
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

val CredentialCachesTest by testSuite {
    val cacheCredentials =
        IdentityCredentials(
            ServiceIdentity(ServiceId("service-id"), "Service Name", "service-user", ServiceRole.Host("1.0")),
            RedactedSecret.AppPassword("app-password"),
        )

    val unavailableToken = AccessTokenResult.Failure(RegistrarFailure.AccessToken(AccessTokenFailureReason.UNAVAILABLE, true))

    val unavailableSentinel = SentinelResult.Failure(RegistrarFailure.Sentinel(SentinelFailureReason.UNAVAILABLE, true))

    val protocolSentinel = SentinelResult.Failure(RegistrarFailure.Sentinel(SentinelFailureReason.PROTOCOL, false))

    test("an access token is reused until its expiry minus the skew") {
        val clock = TestTimeSource()
        val script = ScriptedCalls<AccessTokenResult>(token("first"), token("second"))
        val cache = AccessTokenCache(cacheCredentials, { script.next() }, clock, skew = 10.seconds)

        cache.get().revealed() shouldBe "first"
        clock += 49.seconds
        cache.get().revealed() shouldBe "first"
        script.calls shouldBe 1

        clock += 1.seconds
        cache.get().revealed() shouldBe "second"
        script.calls shouldBe 2
    }

    test("a failed token refresh never serves the expired token") {
        val clock = TestTimeSource()
        val script = ScriptedCalls<AccessTokenResult>(token("first"), unavailableToken)
        val cache = AccessTokenCache(cacheCredentials, { script.next() }, clock, skew = 0.seconds)

        cache.get().revealed() shouldBe "first"
        clock += 60.seconds
        cache.get() shouldBe unavailableToken
    }

    test("sentinel credentials are reused before the refresh age") {
        val clock = TestTimeSource()
        val script = ScriptedCalls<SentinelResult>(sentinel("first"), sentinel("second"))
        val cache = SentinelCache({ script.next() }, refreshAfter = 30.seconds, maximumStaleness = 60.seconds, clock = clock)

        cache.get().jwt() shouldBe "first"
        clock += 29.seconds
        cache.get().jwt() shouldBe "first"
        script.calls shouldBe 1

        clock += 1.seconds
        cache.get().jwt() shouldBe "second"
    }

    test("stale sentinel credentials are served while the service is unavailable, up to the maximum staleness") {
        val clock = TestTimeSource()
        val script = ScriptedCalls<SentinelResult>(sentinel("first"), unavailableSentinel, unavailableSentinel)
        val cache = SentinelCache({ script.next() }, refreshAfter = 30.seconds, maximumStaleness = 60.seconds, clock = clock)

        cache.get().jwt() shouldBe "first"
        clock += 60.seconds
        cache.get().jwt() shouldBe "first"
        clock += 1.seconds
        cache.get() shouldBe unavailableSentinel
    }

    test("a sentinel protocol error gets no stale fallback") {
        val clock = TestTimeSource()
        val script = ScriptedCalls<SentinelResult>(sentinel("first"), protocolSentinel)
        val cache = SentinelCache({ script.next() }, refreshAfter = 30.seconds, maximumStaleness = 60.seconds, clock = clock)

        cache.get().jwt() shouldBe "first"
        clock += 31.seconds
        cache.get() shouldBe protocolSentinel
    }
}
