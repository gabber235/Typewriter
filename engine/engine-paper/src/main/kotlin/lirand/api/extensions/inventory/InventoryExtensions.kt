package lirand.api.extensions.inventory

import com.typewritermc.engine.paper.utils.server
import com.typewritermc.engine.paper.utils.asMini
import org.bukkit.Material
import org.bukkit.event.inventory.InventoryType
import org.bukkit.inventory.Inventory
import org.bukkit.inventory.InventoryHolder
import org.bukkit.inventory.ItemStack

fun Inventory(
    type: InventoryType,
    owner: InventoryHolder? = null,
    title: String? = null
): Inventory {
    return if (title != null)
        server.createInventory(owner, type, title.asMini())
    else
        server.createInventory(owner, type)
}

fun Inventory(
    size: Int,
    owner: InventoryHolder? = null,
    title: String? = null
): Inventory {
    return if (title != null)
        server.createInventory(owner, size, title.asMini())
    else
        server.createInventory(owner, size)
}

operator fun Inventory.get(slot: Int): ItemStack? = getItem(slot)

operator fun Inventory.set(slot: Int, itemStack: ItemStack?) {
    setItem(slot, itemStack)
}