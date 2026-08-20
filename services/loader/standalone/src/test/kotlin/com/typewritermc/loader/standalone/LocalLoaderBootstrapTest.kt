package com.typewritermc.loader.standalone

import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.HostIdentityStore
import com.typewritermc.loader.LoaderBootstrap
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import java.nio.file.Files

val LocalLoaderBootstrapTest by testSuite {
    test("the distribution discovers a local standalone bootstrap") {
        LoaderBootstrap.discover().shouldBeInstanceOf<LocalLoaderBootstrap>()
    }

    test("local standalone mode persists its host identity") {
        runTest {
            val directory = Files.createTempDirectory("typewriter-local-host")
            val host = LocalLoaderBootstrap().start(HostEntrypoint.STANDALONE, directory, backgroundScope)

            HostIdentityStore(directory.resolve("state/host-id")).load() shouldBe "local-standalone"
            host.stop()
        }
    }
}
