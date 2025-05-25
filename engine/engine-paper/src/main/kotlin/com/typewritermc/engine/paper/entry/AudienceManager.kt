package com.typewritermc.engine.paper.entry

import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.utils.Reloadable
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.formatCompact
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.AVERAGE_SCHEDULING_DELAY_MS
import com.typewritermc.engine.paper.utils.TICK_MS
import com.typewritermc.engine.paper.utils.server
import kotlinx.coroutines.*
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import org.koin.java.KoinJavaComponent.get
import kotlin.reflect.KClass
import kotlin.reflect.full.hasAnnotation
import kotlin.reflect.full.safeCast
import kotlin.time.Duration.Companion.seconds
import kotlin.time.measureTime

class AudienceManager : Listener, Reloadable, KoinComponent {
    private val isEnabled by inject<Boolean>(named("isEnabled"))
    private var displays = emptyMap<Ref<out AudienceEntry>, AudienceDisplay>()
    private var parents = emptyMap<Ref<out AudienceEntry>, List<Ref<out AudienceFilterEntry>>>()
    private var roots = emptyList<Ref<out AudienceEntry>>()

    private var coroutineScope: CoroutineScope? = null

    fun initialize() {
        server.pluginManager.registerEvents(this, plugin)
    }

    override suspend fun load() {
        unload()

        val entries = Query.find<AudienceEntry>()

        val parents = mutableMapOf<Ref<out AudienceEntry>, List<Ref<out AudienceFilterEntry>>>()
        entries.filterIsInstance<AudienceFilterEntry>().forEach { entry ->
            entry.children.forEach { child ->
                val list = parents.getOrPut(child) { mutableListOf() }
                (list as MutableList).add(entry.ref())
            }
        }
        this.parents = parents

        roots = entries
            .filter { parents[it.ref()].isNullOrEmpty() }
            .filter {
                !it::class.hasAnnotation<ChildOnly>()
            }
            .map { it.ref() }
            .toList()

        displays = entries.associate { it.ref() to it.display() }

        coroutineScope = CoroutineScope(SupervisorJob() + Dispatchers.UntickedAsync)

        for ((ref, display) in displays) {
            if (display !is TickableDisplay) continue
            coroutineScope?.launch {
                loopDisplay(ref, display)
            }
        }

        server.onlinePlayers.forEach { player ->
            addPlayerForRoots(player)
        }
    }

    private suspend fun <TD> loopDisplay(ref: Ref<out AudienceEntry>, display: TD)
            where TD : AudienceDisplay, TD : TickableDisplay {
        while (isEnabled && coroutineScope?.isActive == true) {
            if (!display.isActive) {
                delay(TICK_MS - AVERAGE_SCHEDULING_DELAY_MS)
                continue
            }
            val time = measureTime {
                try {
                    withTimeout(30.seconds) {
                        display.tick()
                    }
                } catch (t: Throwable) {
                    logger.warning("Exception thrown while ticking $display")
                    t.printStackTrace()
                }
            }

            val wait = TICK_MS - time.inWholeMilliseconds - AVERAGE_SCHEDULING_DELAY_MS
            if (wait > 0) delay(wait)
            else if (wait < -100) {
                logger.warning(
                    "Audience entry $ref took to long to tick ${time.formatCompact()} (if this happens only occasionally, it's fine)"
                )
            }
        }
    }

    fun addPlayerFor(player: Player, ref: Ref<out AudienceEntry>) {
        val display = displays[ref] ?: return
        try {
            display.addPlayer(player)
        } catch (t: Throwable) {
            logger.severe("Exception thrown while adding player '${player.name}' to $display")
            t.printStackTrace()
        }
    }

    fun addPlayerForRoots(player: Player) {
        roots.forEach { addPlayerFor(player, it) }
    }

    fun removePlayerFor(player: Player, ref: Ref<out AudienceEntry>) {
        val display = displays[ref] ?: return
        try {
            display.removePlayer(player)
        } catch (t: Throwable) {
            logger.severe("Exception thrown while removing player '${player.name}' from $display")
            t.printStackTrace()
        }
    }

    fun removePlayerForRoots(player: Player) {
        roots.forEach { removePlayerFor(player, it) }
    }

    fun addPlayerToChildren(player: Player, ref: Ref<out AudienceFilterEntry>) {
        val entry = ref.get() ?: return
        entry.children.forEach { addPlayerFor(player, it) }
    }

    fun removePlayerFromChildren(player: Player, ref: Ref<out AudienceFilterEntry>) {
        val entry = ref.get() ?: return
        entry.children
            .filter { entryRef -> getParents(entryRef).none { this[it]?.contains(player) ?: false } }
            .forEach { removePlayerFor(player, it) }
    }

    fun <D : Any> findDisplays(klass: KClass<D>): Sequence<D> {
        return displays.values.asSequence().filterIsInstance(klass.java)
    }

    operator fun get(ref: Ref<out AudienceEntry>): AudienceDisplay? = displays[ref]

    fun getParents(ref: Ref<out AudienceEntry>): List<Ref<out AudienceFilterEntry>> = parents[ref] ?: emptyList()

    override suspend fun unload() {
        coroutineScope?.cancel()
        coroutineScope = null
        val displays = displays
        this.displays = emptyMap()
        displays.values.forEach { it.dispose() }
    }

    @EventHandler
    private fun onPlayerJoin(event: PlayerJoinEvent) {
        addPlayerForRoots(event.player)
    }

    @EventHandler
    private fun onPlayerQuit(event: PlayerQuitEvent) {
        removePlayerForRoots(event.player)
    }

    suspend fun shutdown() {
        unload()
        HandlerList.unregisterAll(this)
    }
}

fun Player.inAudience(entry: AudienceEntry): Boolean = inAudience(entry.ref())

fun Player.inAudience(ref: Ref<out AudienceEntry>): Boolean {
    val manager = get<AudienceManager>(AudienceManager::class.java)
    return manager[ref]?.let { return it.contains(this) } ?: false
}

fun Player.audienceState(entry: AudienceEntry): AudienceDisplayState = audienceState(entry.ref())
fun Player.audienceState(ref: Ref<out AudienceEntry>): AudienceDisplayState {
    val manager = get<AudienceManager>(AudienceManager::class.java)
    return manager[ref]?.displayState(this) ?: AudienceDisplayState.NOT_CONSIDERED
}

val Ref<out AudienceEntry>.isActive: Boolean
    get() {
        val manager = get<AudienceManager>(AudienceManager::class.java)
        return manager[this]?.isActive ?: false
    }

fun <D : Any> Ref<out AudienceEntry>.findDisplay(klass: KClass<D>): D? {
    val manager = get<AudienceManager>(AudienceManager::class.java)
    return klass.safeCast(manager[this])
}

inline fun <reified D : Any> Ref<out AudienceEntry>.findDisplay(): D? {
    return findDisplay(D::class)
}


fun <E : AudienceEntry> List<Ref<out AudienceEntry>>.descendants(klass: KClass<E>): List<Ref<E>> {
    return flatMap {
        val child = it.get() ?: return@flatMap emptyList<Ref<E>>()
        if (klass.isInstance(child)) {
            listOf(it as Ref<E>)
        } else if (child is AudienceFilterEntry) {
            child.children.descendants(klass)
        } else {
            emptyList()
        }
    }
}

fun <E : AudienceEntry> Ref<out AudienceFilterEntry>.descendants(klass: KClass<E>): List<Ref<E>> {
    val entry = get() ?: return emptyList()
    return entry.children.descendants(klass)
}