package com.typewritermc.visibility

import com.typewritermc.engine.paper.utils.PlayerHides
import com.typewritermc.visibility.packet.VisibilityPacketBridge
import com.typewritermc.visibility.packet.VisibilityTeamManager
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import net.kyori.adventure.text.Component
import org.bukkit.event.player.PlayerQuitEvent
import org.bukkit.plugin.Plugin
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import java.util.logging.Logger

class VisibilityPlayerListenerSpec : FunSpec({
    lateinit var server: ServerMock
    lateinit var bridge: VisibilityPacketBridge
    lateinit var hideRegistry: VisibilityHideRegistry
    lateinit var listener: VisibilityPlayerListener

    beforeTest {
        server = MockBukkit.mock()
        val plugin = mockk<Plugin>(relaxed = true)
        every { plugin.isEnabled } returns true
        bridge = VisibilityPacketBridge()
        hideRegistry = VisibilityHideRegistry()
        startKoin {
            modules(module {
                single<Plugin> { plugin }
                single { Logger.getLogger("VisibilityPlayerListenerSpec") }
                single { PlayerHides() }
                single { bridge }
                single { VisibilityTeamManager() }
                single { hideRegistry }
            })
        }
        listener = VisibilityPlayerListener()
    }

    afterTest {
        stopKoin()
        MockBukkit.unmock()
    }

    fun quit(name: String) = PlayerQuitEvent(
        server.getPlayer(name)!!,
        Component.empty(),
        PlayerQuitEvent.QuitReason.DISCONNECTED,
    )

    test("a viewer that quits loses their packet hooks") {
        val viewer = server.addPlayer("Viewer")
        val hook = object : com.typewritermc.visibility.packet.EntityPacketHook {}
        bridge.addEntityHook(viewer.uniqueId, 42, hook)

        listener.onQuit(quit("Viewer"))

        bridge.hasHooksFor(viewer.uniqueId) shouldBe false
    }

})
