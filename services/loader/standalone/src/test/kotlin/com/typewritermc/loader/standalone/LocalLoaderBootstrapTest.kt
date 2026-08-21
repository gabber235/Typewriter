package com.typewritermc.loader.standalone

import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.HostIdentityStore
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import java.nio.file.Files

val LocalLoaderBootstrapTest by testSuite {
    test("the distribution discovers a local standalone bootstrap") {
        localLoaderApplication().use { application -> application.bootstrap.shouldBeInstanceOf<LocalLoaderBootstrap>() }
    }

    test("local standalone mode persists its host identity") {
        runTest {
            val directory = Files.createTempDirectory("typewriter-local-host")
            val application = localLoaderApplicationWithoutService()
            val host = application.bootstrap.start(HostEntrypoint.STANDALONE, directory, backgroundScope)

            HostIdentityStore(directory.resolve("state/host-id")).load() shouldBe "local-standalone"
            host.stop()
            application.close()
        }
    }
}
