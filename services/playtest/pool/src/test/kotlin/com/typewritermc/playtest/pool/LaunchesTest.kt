package com.typewritermc.playtest.pool

import com.typewritermc.playtest.launch.HeapShare
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import java.nio.file.Files

val LaunchesTest by testSuite {
    test("every game JVM the pool starts caps its heap at its kind's share of the machine: the shared Paper, an own Paper and a client") {
        val dir = Files.createTempDirectory("launches")
        val settings = poolSettings(dir, clients = 4)
        Files.writeString(
            settings.launched.clientLaunch,
            """{"jvmArgs": [], "classpath": ["client.jar"], "main": "net.minecraft.client.main.Main", "args": []}""",
        )
        val server = PaperServer(listOf(dir.resolve("server.jar")), "io.papermc.paper.PaperBootstrap")
        val folder = PaperFolder("paper", dir.resolve("paper"), 25565, dir.resolve("paper.log"), slot = 0)

        Launches.sharedPaper(PartLaunch(settings, 4000), folder, server, "output=none") shouldContain HeapShare.PAPER.flag()
        Launches.ownPaper(PartLaunch(settings, 4000), folder, server, "output=none", listOf()) shouldContain HeapShare.OWN_PAPER.flag()
        Launches.client(PartLaunch(settings, 4000), "gv-1", InputPath.SDL, dir.resolve("client-gv-1")) shouldContain HeapShare.CLIENT.flag()
    }
}
