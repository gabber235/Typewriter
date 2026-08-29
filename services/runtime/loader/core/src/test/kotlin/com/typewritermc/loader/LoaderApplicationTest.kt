package com.typewritermc.loader

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.types.shouldBeInstanceOf

val LoaderApplicationTest by testSuite {
    test("shared application assembles the artifact bootstrap") {
        loaderApplication { }.use { application -> application.bootstrap.shouldBeInstanceOf<ArtifactLoaderBootstrap>() }
    }
}
