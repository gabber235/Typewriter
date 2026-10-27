package com.typewritermc.realm.catalog

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

/** The incarnation's deployment still lends out its providers. */
internal fun RealmCatalogIncarnation.shouldBeOpen() = deployment.retain().close()

/** The incarnation's deployment refuses to lend out its providers any more. */
internal fun RealmCatalogIncarnation.shouldBeClosed() {
    shouldThrow<IllegalStateException> { deployment.retain() }.message shouldBe "Generated provider deployment is closed."
}
