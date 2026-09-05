package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor

private fun spec(
    name: String,
    vararg members: String,
    color: NamedTextColor = NamedTextColor.WHITE,
    option: WrapperPlayServerTeams.OptionData = WrapperPlayServerTeams.OptionData.NONE,
) = TeamSpec(
    name = name,
    color = color,
    nameTagVisibility = WrapperPlayServerTeams.NameTagVisibility.ALWAYS,
    option = option,
    prefix = Component.empty(),
    suffix = Component.empty(),
    collisionRule = WrapperPlayServerTeams.CollisionRule.ALWAYS,
    members = members.toList(),
)

private fun layout(vararg specs: TeamSpec) = specs.associateBy { it.name }

class TeamLayoutDiffSpec : FunSpec({

    test("an unchanged layout sends nothing") {
        val teams = layout(spec("twv_p_1", "Target"))

        diffTeamLayout(teams, teams) shouldBe emptyList()
    }

    test("the first team is created with its members") {
        val packets = diffTeamLayout(emptyMap(), layout(spec(GHOST_TEAM_NAME, "Target", "Viewer")))

        packets shouldContainExactly listOf(TeamPacket.Create(spec(GHOST_TEAM_NAME, "Target", "Viewer")))
    }

    test("a team that gains a member only adds that member") {
        val packets = diffTeamLayout(
            layout(spec(GHOST_TEAM_NAME, "First", "Viewer")),
            layout(spec(GHOST_TEAM_NAME, "First", "Second", "Viewer")),
        )

        packets shouldContainExactly listOf(TeamPacket.AddMembers(GHOST_TEAM_NAME, listOf("Second")))
    }

    test("a team that loses a member is recreated instead of having them taken out") {
        val packets = diffTeamLayout(
            layout(spec(GHOST_TEAM_NAME, "First", "Second", "Viewer")),
            layout(spec(GHOST_TEAM_NAME, "First", "Viewer")),
        )

        packets shouldContainExactly listOf(
            TeamPacket.Remove(GHOST_TEAM_NAME),
            TeamPacket.Create(spec(GHOST_TEAM_NAME, "First", "Viewer")),
            TeamPacket.RestoreRealTeam("Second"),
        )
    }

    test("a team that disappears takes its members back to their real teams") {
        val packets = diffTeamLayout(layout(spec("twv_p_1", "Target")), emptyMap())

        packets shouldContainExactly listOf(
            TeamPacket.Remove("twv_p_1"),
            TeamPacket.RestoreRealTeam("Target"),
        )
    }

    test("a team whose looks changed is updated without touching its members") {
        val packets = diffTeamLayout(
            layout(spec("twv_p_1", "Target", color = NamedTextColor.RED)),
            layout(spec("twv_p_1", "Target", color = NamedTextColor.BLUE)),
        )

        packets shouldContainExactly listOf(
            TeamPacket.Update(spec("twv_p_1", "Target", color = NamedTextColor.BLUE)),
        )
    }

    test("a member moving from a pair team to the ghost team is never left without a team") {
        val packets = diffTeamLayout(
            layout(spec("twv_p_1", "Target")),
            layout(spec(GHOST_TEAM_NAME, "Target", "Viewer", option = WrapperPlayServerTeams.OptionData.FRIENDLY_CAN_SEE_INVISIBLE)),
        )

        packets shouldContainExactly listOf(
            TeamPacket.Remove("twv_p_1"),
            TeamPacket.Create(spec(GHOST_TEAM_NAME, "Target", "Viewer", option = WrapperPlayServerTeams.OptionData.FRIENDLY_CAN_SEE_INVISIBLE)),
        )
    }

    test("the viewer goes back to their own team when the ghost team is gone") {
        val packets = diffTeamLayout(
            layout(spec(GHOST_TEAM_NAME, "Target", "Viewer")),
            layout(spec("twv_p_1", "Target")),
        )

        packets shouldContainExactly listOf(
            TeamPacket.Remove(GHOST_TEAM_NAME),
            TeamPacket.Create(spec("twv_p_1", "Target")),
            TeamPacket.RestoreRealTeam("Viewer"),
        )
    }
})
