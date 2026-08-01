package com.typewritermc.basic.entries.audience

import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.inAudience
import com.typewritermc.engine.paper.plugin
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.inventory.meta.BundleMeta
import org.bukkit.persistence.PersistentDataType
import java.util.*

private val questItemKey = NamespacedKey(plugin, "quest_item")
private val questItemOwnerKey = NamespacedKey(plugin, "quest_item_owner")

/**
 * Marks the item as the quest item of [entry], given to [owner].
 *
 * Use this on every stack handed to a player. The tag is the only thing that makes an item a quest item. Its
 * contents cannot stand in for it, as a `Var<Item>` may change them and the player may split or restack them.
 *
 * The entry id is stored as a value instead of as part of the key, because entry ids are mixed case and a
 * [NamespacedKey] path may not be.
 */
fun ItemStack.tagAsQuestItem(entry: Ref<QuestItemAudienceEntry>, owner: Player) {
    editPersistentDataContainer {
        it[questItemKey, PersistentDataType.STRING] = entry.id
        it[questItemOwnerKey, PersistentDataType.STRING] = owner.uniqueId.toString()
    }
}

/** The entry the item belongs to, or null when it is not a quest item. */
val ItemStack?.questItemEntry: Ref<QuestItemAudienceEntry>?
    get() {
        if (this == null || isEmpty) return null
        val id = persistentDataContainer.get(questItemKey, PersistentDataType.STRING) ?: return null
        return Ref(id, QuestItemAudienceEntry::class)
    }

/** The player the item was given to, or null when it is not a quest item. */
val ItemStack?.questItemOwner: UUID?
    get() {
        if (this == null || isEmpty) return null
        val raw = persistentDataContainer.get(questItemOwnerKey, PersistentDataType.STRING) ?: return null
        return runCatching { UUID.fromString(raw) }.getOrNull()
    }

/** Whether the item is the quest item of any entry. */
val ItemStack?.isQuestItem: Boolean
    get() = questItemEntry != null

/** Whether the item is the quest item of [entry], whoever it was given to. */
fun ItemStack?.isQuestItemOf(entry: Ref<QuestItemAudienceEntry>): Boolean = questItemEntry == entry

/**
 * The quest item of [entry] this stack is, or the one it carries as a bundle, or null for neither.
 *
 * Nothing is allowed to put a quest item into a bundle, but a bundle can turn up with one already in it. A
 * bundle carrying one has to be stopped everywhere the item itself is, or it walks the item into a container
 * for the player.
 */
fun ItemStack?.carriedQuestItemOf(entry: Ref<QuestItemAudienceEntry>): ItemStack? {
    if (isQuestItemOf(entry)) return this
    val bundle = this?.itemMeta as? BundleMeta ?: return null
    return bundle.items.firstOrNull { it.isQuestItemOf(entry) }
}

/**
 * Whether the item is the quest item of [entry], or a bundle with one inside it.
 *
 * Use this to ask whether something may leave the player's inventory, and [isQuestItemOf] to ask what an
 * inventory holds, so that counting the item back up never counts a bundle as the item.
 */
fun ItemStack?.carriesQuestItemOf(entry: Ref<QuestItemAudienceEntry>): Boolean =
    carriedQuestItemOf(entry) != null

/**
 * Takes the stacks [matches] answers for out of the bundle, and answers with whether it took any.
 *
 * Anything that is not a bundle is left alone, as is the rest of what the bundle holds. A bundle a quest item
 * turned up in is most likely one the player keeps their own things in as well.
 */
fun ItemStack.removeBundled(matches: (ItemStack) -> Boolean): Boolean {
    val meta = itemMeta as? BundleMeta ?: return false
    val kept = meta.items.filterNot(matches)
    if (kept.size == meta.items.size) return false
    meta.setItems(kept)
    itemMeta = meta
    return true
}

/**
 * Whether the item is tagged for something that no longer applies to [player]: another player, an entry that
 * no longer exists, or an audience they are not in.
 *
 * Use this when cleaning up an inventory. A crash, a deleted entry, or an audience the player left while they
 * were offline all leave a tagged item behind that no display takes back, so this asks about every entry
 * rather than one.
 */
fun ItemStack?.isStaleQuestItem(player: Player): Boolean {
    val entry = questItemEntry ?: return false
    if (questItemOwner != player.uniqueId) return true
    if (entry.get() == null) return true
    return !player.inAudience(entry)
}
