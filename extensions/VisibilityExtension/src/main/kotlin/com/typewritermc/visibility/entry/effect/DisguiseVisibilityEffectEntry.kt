package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.toProperty
import com.typewritermc.engine.paper.entry.entity.withPriority
import com.typewritermc.engine.paper.entry.entries.EntityDefinitionEntry
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.visibility.VisibilityHideRegistry
import com.typewritermc.visibility.effector.TickableVisibilityEffector
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.targetPlayer
import com.typewritermc.visibility.packet.viewerPlayer
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.Dispatchers
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

@Entry(
    "disguise_visibility_effect",
    "Shows the target as a different entity to the viewer",
    Colors.BLUE_VIOLET,
    "fa6-solid:masks-theater"
)
/**
 * The `Disguise Visibility Effect` replaces the target with an entity from an entity definition,
 * but only for the viewer. The real player is hidden and the definition entity mirrors their
 * movement.
 *
 * Any entity definition works, from a zombie to an npc with a different skin.
 *
 * ## How could this be used?
 * Turn a werewolf player into a wolf for everyone without the detection ability, or let an
 * infiltrator appear as a guard npc to the guards' faction.
 */
class DisguiseVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The entity definition the viewer sees instead of the target.")
    val definition: Ref<out EntityDefinitionEntry> = emptyRef(),
) : VisibilityEffectEntry {
    override fun createEffector(rule: VisibilityRule): VisibilityEffector =
        DisguiseVisibilityEffector(rule, definition)
}

private class DisguiseVisibilityEffector(
    private val rule: VisibilityRule,
    private val definitionRef: Ref<out EntityDefinitionEntry>,
) : TickableVisibilityEffector, KoinComponent {
    private val hideRegistry: VisibilityHideRegistry by inject()

    // The disguise is spawned and disposed on the server thread while [tick] drives it from the
    // engine's tick coroutine, and a tick already in flight can outlive the disposal.
    private val entityLock = ReentrantLock()
    private var entity: FakeEntity? = null
    private var disposed = false

    override suspend fun initialize() {
        Dispatchers.Sync.switchContext {
            if (rule.isSelf) return@switchContext
            val viewer = rule.viewerPlayer ?: return@switchContext
            val target = rule.targetPlayer ?: return@switchContext
            val definition = definitionRef.get() ?: throw IllegalStateException(
                "Could not find entity definition '${definitionRef.id}' for disguise effect on entry '${rule.entryId}'"
            )

            val disguise = definition.create(viewer)
            val properties = definition.data.withPriority()
                .sortedBy { it.second }
                .map { it.first.build(viewer) }
            disguise.consumeProperties(properties)

            entityLock.withLock {
                if (disposed) return@withLock
                hideRegistry.hide(viewer, target)
                // The field is set before the spawn: a spawn that throws partway has already placed
                // entities on the client, and only dispose can remove those.
                entity = disguise
                disguise.spawn(target.location.toProperty())
            }
        }
    }

    override suspend fun tick() {
        val target = rule.targetPlayer ?: return
        val position = target.location.toProperty()
        entityLock.withLock {
            val disguise = entity ?: return@withLock
            disguise.consumeProperties(position)
            disguise.tick()
        }
    }

    override suspend fun dispose() {
        Dispatchers.Sync.switchContext {
            entityLock.withLock {
                disposed = true
                entity?.dispose()
                entity = null
            }

            if (rule.isSelf) return@switchContext
            hideRegistry.show(rule.viewer, rule.target)
        }
    }
}
