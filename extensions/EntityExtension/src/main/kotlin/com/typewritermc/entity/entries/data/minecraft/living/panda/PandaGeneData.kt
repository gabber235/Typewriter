package com.typewritermc.entity.entries.data.minecraft.living.panda

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.PandaMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("panda_gene_data", "The panda's genes (main and hidden)", Colors.RED, "mdi:dna")
@Tags("panda_gene_data", "panda_data")
class PandaGeneData(
    override val id: String = "",
    override val name: String = "",
    val mainGene: PandaMeta.Gene = PandaMeta.Gene.NORMAL,
    val hiddenGene: PandaMeta.Gene = PandaMeta.Gene.NORMAL,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<PandaGeneProperty> {
    override fun type(): KClass<PandaGeneProperty> = PandaGeneProperty::class
    override fun build(player: Player): PandaGeneProperty = PandaGeneProperty(mainGene, hiddenGene)
}

data class PandaGeneProperty(
    val mainGene: PandaMeta.Gene,
    val hiddenGene: PandaMeta.Gene,
) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<PandaGeneProperty>(PandaGeneProperty::class)
}

fun applyPandaGeneData(entity: WrapperEntity, property: PandaGeneProperty) {
    entity.metas {
        meta<PandaMeta> {
            mainGene = property.mainGene
            hiddenGene = property.hiddenGene
        }
        error("Could not apply PandaGeneData to ${entity.entityType} entity.")
    }
}