package com.typewritermc.loader.standalone

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.types.shouldBeInstanceOf

val LocalLoaderBootstrapTest by testSuite {
    test("the distribution discovers a local standalone bootstrap") {
        localLoaderApplication().use { application -> application.bootstrap.shouldBeInstanceOf<ArtifactLoaderBootstrap>() }
    }
}
