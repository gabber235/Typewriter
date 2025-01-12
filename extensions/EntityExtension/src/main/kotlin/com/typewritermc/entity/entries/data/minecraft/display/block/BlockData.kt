package com.typewritermc.entity.entries.data.minecraft.display.block

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContentEditor
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.components.bossBar
import com.typewritermc.engine.paper.content.components.exit
import com.typewritermc.engine.paper.content.entryId
import com.typewritermc.engine.paper.content.fieldPath
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.entry.fieldValue
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.extensions.packetevents.metas
import com.typewritermc.engine.paper.plugin
import com.typewritermc.entity.entries.data.minecraft.display.DisplayEntityData
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import me.tofaa.entitylib.meta.display.BlockDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerInteractEvent
import java.util.*
import kotlin.reflect.KClass

@Entry("block_data", "Block of a BlockDisplay.", Colors.RED, "mage:box-3d-fill")
@Tags("block_data")
class BlockData(
    override val id: String = "",
    override val name: String = "",
    @ContentEditor(BlockIdContentMode::class)
    val blockId: Int = 0,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : DisplayEntityData<BlockProperty> {
    override fun type(): KClass<BlockProperty> = BlockProperty::class

    override fun build(player: Player): BlockProperty = BlockProperty(blockId)
}

data class BlockProperty(val blockId: Int) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<BlockProperty>(BlockProperty::class)
}

fun applyBlockData(entity: WrapperEntity, property: BlockProperty) {
    entity.metas {
        meta<BlockDisplayMeta> { blockId = property.blockId }
        error("Could not apply BlockData to ${entity.entityType} entity.")
    }
}

class BlockIdContentMode(context: ContentContext, player: Player) : ContentMode(context, player), Listener {
    override suspend fun setup(): Result<Unit> {
        context.entryId ?: return failure("No entry id found in context")
        context.fieldPath ?: return failure("No field path found in context")

        bossBar {
            title = "Click on a block to set the block state id"
        }
        exit()

        return ok(Unit)
    }

    override suspend fun initialize() {
        super.initialize()
        plugin.registerEvents(this)
    }

    @EventHandler
    fun onInteractBlockEvent(event: PlayerInteractEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        if (event.hand != org.bukkit.inventory.EquipmentSlot.HAND) return
        event.isCancelled = true
        val block = event.clickedBlock ?: return
        val blockStateId = SpigotConversionUtil.fromBukkitBlockData(block.blockData).globalId
        val entryId = context.entryId ?: return
        val ref = Ref(entryId, com.typewritermc.core.entries.Entry::class)
        val fieldPath = context.fieldPath ?: return
        ref.fieldValue(fieldPath, blockStateId)
        InteractionEndTrigger.triggerFor(player, context())
    }

    override suspend fun dispose() {
        unregister()
        super.dispose()
    }
}