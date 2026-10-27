package com.typewritermc.loader.rollout.testing

import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.artifact.toApi
import com.typewritermc.loader.rollout.serviceIds
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import skirout.service.v1.rollout.RolloutCommandKind

suspend fun RolloutFixture.rollsOutTheRealmAndPanelOnly() {
    val committed = requireNotNull(state.committed())
    val reference = host.commands.first().projectionFor(host.id)
    committed.projections shouldBe mapOf(host.id to reference.blob.toApi())
    host.commandKinds shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
    host.commands.forEach { it.command.serviceIds shouldBe setOf(host.id.value) }
    projections.fetch(reference).runtimes.map { it.placement } shouldContainExactly
        listOf(RuntimePlacement.PANEL_ENGINE, RuntimePlacement.REALM)
}
