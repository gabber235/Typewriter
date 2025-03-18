package com.typewritermc.engine.paper.utils.item

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.utils.plainText
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import kotlin.io.encoding.Base64
import kotlin.io.encoding.ExperimentalEncodingApi

@OptIn(ExperimentalEncodingApi::class)
@AlgebraicTypeInfo("serialized_item", Colors.ORANGE, "mingcute:file-code-fill")
class SerializedItem(
    private val material: Material = Material.AIR,
    private val name: String = material.name,

    @Default("1")
    private val amount: Var<Int> = ConstVar(1),

    private val bytes: String = "", // Base64 encoded bytes
) : Item {
    constructor(itemStack: ItemStack) : this(
        itemStack.type,
        itemStack.itemMeta?.displayName()?.plainText() ?: itemStack.type.name,
        ConstVar(itemStack.amount),
        if (itemStack.type != Material.AIR) Base64.encode(itemStack.serializeAsBytes()) else "",
    )

    @delegate:Transient
    private val itemStack: ItemStack by lazy(LazyThreadSafetyMode.NONE) {
        val bytes = Base64.decode(bytes)
        if (bytes.isEmpty()) return@lazy ItemStack(Material.AIR)
        ItemStack.deserializeBytes(bytes)
    }

    override fun build(player: Player?, context: InteractionContext?): ItemStack = itemStack.clone().apply {
        amount = this@SerializedItem.amount.get(player, context) ?: 1
    }

    override fun isSameAs(player: Player?, item: ItemStack?, context: InteractionContext?): Boolean =
        this.itemStack.isSimilar(item)

    override fun exactMatch(player: Player?, item: ItemStack?, context: InteractionContext?): Boolean =
        this.itemStack.isSimilar(item) && this.itemStack.amount == item?.amount
}

fun ItemStack.toItem(): SerializedItem = SerializedItem(this)