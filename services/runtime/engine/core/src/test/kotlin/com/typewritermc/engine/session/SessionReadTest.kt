package com.typewritermc.engine.session

import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.services.libs.communicator.testing.unansweredKeyValueBucket
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrowAny

/** Reading a session's entry from the sessions bucket. */
val SessionReadTest by testSuite {
    test("a session read the broker never answered fails instead of reading as no session") {
        shouldThrowAny {
            unansweredKeyValueBucket().readSessionEntry(Protagonist(PrincipalId(PrincipalId.MINECRAFT, "alex")), SessionId("alex"))
        }
    }
}
