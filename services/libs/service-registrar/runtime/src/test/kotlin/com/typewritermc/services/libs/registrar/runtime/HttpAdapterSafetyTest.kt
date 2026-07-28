package com.typewritermc.services.libs.registrar.runtime

import com.typewritermc.services.libs.registrar.IdentityIssueError
import com.typewritermc.services.libs.registrar.IdentityRejectionReason
import com.typewritermc.services.libs.registrar.RedactedSecret
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val HttpAdapterSafetyTest by testSuite {
    IdentityRejectionReason.entries.forEach { reason ->
        test("identity rejection $reason is closed and unambiguous") {
            val failure = IdentityIssueError.Rejected(reason)
            failure.reason shouldBe reason
            failure.outcomeMayBeAmbiguous shouldBe false
        }
    }
    test("sentinel credentials diagnostics redact both secrets") {
        val credentials = SentinelCredentials(
            RedactedSecret.SentinelJwt("private-jwt"),
            RedactedSecret.SentinelSeed("private-seed"),
        )
        credentials.toString() shouldBe "SentinelCredentials(jwt=[REDACTED], seed=[REDACTED])"
    }
}
