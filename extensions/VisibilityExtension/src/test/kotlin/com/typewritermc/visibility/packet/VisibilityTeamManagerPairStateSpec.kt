package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import com.typewritermc.engine.paper.utils.PlayerHides
import com.typewritermc.visibility.VisibilityHideRegistry
import com.typewritermc.visibility.VisibleReplacement
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import net.kyori.adventure.text.format.NamedTextColor
import org.bukkit.plugin.Plugin
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import java.util.logging.Logger

class VisibilityTeamManagerPairStateSpec : FunSpec({
    lateinit var server: ServerMock
    lateinit var hideRegistry: VisibilityHideRegistry
    lateinit var teamManager: VisibilityTeamManager

    beforeTest {
        server = MockBukkit.mock()
        val plugin = mockk<Plugin>(relaxed = true)
        every { plugin.isEnabled } returns true
        hideRegistry = VisibilityHideRegistry()
        teamManager = VisibilityTeamManager()
        startKoin {
            modules(module {
                single<Plugin> { plugin }
                single { Logger.getLogger("VisibilityTeamManagerPairStateSpec") }
                single { PlayerHides() }
                single { hideRegistry }
            })
        }
    }

    afterTest {
        stopKoin()
        MockBukkit.unmock()
    }

    test("a disguised pair is dropped once its last contribution is withdrawn") {
        val viewer = server.addPlayer("Viewer")
        val target = server.addPlayer("Target")
        hideRegistry.hide(viewer, target, VisibleReplacement(42, "fake-member"))
        teamManager.contribute(viewer, target, TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED))
        teamManager.tracksPair(viewer.uniqueId, 42) shouldBe true

        teamManager.withdraw(viewer.uniqueId, 42, TeamContributionKind.GLOW)

        teamManager.tracksPair(viewer.uniqueId, 42) shouldBe false
    }

    test("a renamed pair keeps its team after its last contribution is withdrawn") {
        val viewer = server.addPlayer("Viewer")
        val target = server.addPlayer("Target")
        teamManager.overrideTargetName(viewer, target, "Disguised")
        teamManager.contribute(viewer, target, TeamContribution(TeamContributionKind.GLOW, color = NamedTextColor.RED))

        teamManager.withdraw(viewer.uniqueId, target.entityId, TeamContributionKind.GLOW)

        teamManager.tracksPair(viewer.uniqueId, target.entityId) shouldBe true
    }

    test("restoring a renamed pair that nothing else contributes to drops it") {
        val viewer = server.addPlayer("Viewer")
        val target = server.addPlayer("Target")
        teamManager.overrideTargetName(viewer, target, "Disguised")

        teamManager.restoreTargetName(viewer.uniqueId, target.entityId)

        teamManager.tracksPair(viewer.uniqueId, target.entityId) shouldBe false
    }

    test("a player's own disguise keys their team by the fake and is dropped with its contribution") {
        val player = server.addPlayer("Player")
        hideRegistry.hide(player, player, VisibleReplacement(42, "fake-member"))
        teamManager.contribute(
            player,
            player,
            TeamContribution(
                TeamContributionKind.DISGUISE,
                collisionRule = WrapperPlayServerTeams.CollisionRule.NEVER,
            ),
        )
        teamManager.tracksPair(player.uniqueId, 42) shouldBe true
        teamManager.tracksPair(player.uniqueId, player.entityId) shouldBe false

        teamManager.withdraw(player.uniqueId, 42, TeamContributionKind.DISGUISE)

        teamManager.tracksPair(player.uniqueId, 42) shouldBe false
    }

    test("a contribution hands back the key that releases it, the fake's id for a disguised pair") {
        val viewer = server.addPlayer("Viewer")
        val target = server.addPlayer("Target")
        val plain = server.addPlayer("Plain")
        hideRegistry.hide(viewer, target, VisibleReplacement(42, "fake-member"))

        val disguisedKey = teamManager.contribute(
            viewer,
            target,
            TeamContribution(TeamContributionKind.NAMETAG_HIDDEN, hidesNametag = true),
        )
        val plainKey = teamManager.contribute(
            viewer,
            plain,
            TeamContribution(TeamContributionKind.NAMETAG_HIDDEN, hidesNametag = true),
        )

        disguisedKey shouldBe 42
        plainKey shouldBe plain.entityId

        teamManager.withdraw(viewer.uniqueId, disguisedKey, TeamContributionKind.NAMETAG_HIDDEN)
        teamManager.withdraw(viewer.uniqueId, plainKey, TeamContributionKind.NAMETAG_HIDDEN)

        teamManager.tracksPair(viewer.uniqueId, 42) shouldBe false
        teamManager.tracksPair(viewer.uniqueId, plain.entityId) shouldBe false
    }
})
