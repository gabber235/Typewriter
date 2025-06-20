package com.typewritermc.engine.paper.interaction

import com.typewritermc.core.interaction.*
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.getAll
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.tryCatch
import com.typewritermc.engine.paper.entry.entries.Event
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.AVERAGE_SCHEDULING_DELAY_MS
import com.typewritermc.engine.paper.utils.TICK_MS
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.java.KoinJavaComponent
import java.time.Duration
import kotlin.reflect.KClass
import kotlin.reflect.full.isSubclassOf
import kotlin.reflect.safeCast


class PlayerSession(val player: Player) : KoinComponent {
    private var sessionTickingJob: Job? = null

    internal var scope: InteractionScope? = null
    val interaction: Interaction? get() = scope?.interaction

    private var trackers: List<SessionTracker> = emptyList()
    private var triggerHandlers: List<TriggerHandler> = emptyList()

    private var scheduledEvents = emptyList<Event>()
    private val eventMutex = Mutex()

    private var lastTickTime = System.currentTimeMillis()

    internal fun setup() {
        triggerHandlers = getKoin().getAll<TriggerHandler>().sortedByDescending { it.priority }
        trackers = getKoin().getAll<SessionTracker>(player)
        trackers.forEach {
            try {
                it.setup()
            } catch (e: Throwable) {
                logger.severe("Failed to setup player session for '${player.name}'.")
                e.printStackTrace()
            }
        }
        sessionTickingJob = startSessionTicking()
    }

    private fun startSessionTicking(): Job = Dispatchers.UntickedAsync.launch {
        // Wait for the plugin to be enabled
        delay(100)
        while (plugin.isEnabled && isActive) {
            // TODO use kotlin.time.measureTime for these time measurements
            val startTime = System.currentTimeMillis()
            eventMutex.withLock {
                runSchedule()
            }
            val now = System.currentTimeMillis()
            val deltaTime = now - lastTickTime
            lastTickTime = now
            tick(Duration.ofMillis(deltaTime))
            val endTime = System.currentTimeMillis()
            // Wait for the remainder or the tick
            val wait = TICK_MS - (endTime - startTime) - AVERAGE_SCHEDULING_DELAY_MS
            if (wait > 0) delay(wait)
            else if (wait < -100) logger.warning("The session ticker for ${player.name} is running behind! Took ${endTime - startTime}ms (if this only happens occasionally, it's fine)")
        }
    }

    /**
     * Adds an event to the schedule. If there is already an event scheduled, it will be merged with
     */
    suspend fun addToSchedule(event: Event) = eventMutex.withLock {
        scheduledEvents += event
    }

    /**
     * Forces an event to be executed.
     * This will bypass the schedule and execute the event immediately.
     * This will also clear the schedule.
     */
    suspend fun forceEvent(event: Event) {
        eventMutex.withLock {
            scheduledEvents += event
            runSchedule()
        }
    }

    suspend fun tick(deltaTime: Duration) {
        scope?.tick(deltaTime)
        trackers.forEach {
            tryCatch { it.tick() }
        }
    }

    private suspend fun runSchedule() {
        if (scheduledEvents.isEmpty()) return
        val events = scheduledEvents.map(Event::distinct)
        this.scheduledEvents = emptyList()
        onEvent(events)
    }

    /** Handles an event. */
    private suspend fun onEvent(events: List<Event>) {
        var interactionLifecycle = InteractionLifecycle.NONE
        var boundLifecycle = InteractionLifecycle.NONE
        val nextInteractions = mutableListOf<Interaction>()
        val nextBounds = mutableListOf<InteractionBound>()
        val todo = ArrayDeque(events.map(Event::filterAllowedTriggers))

        // To prevent infinite loops, we limit the number of recursive calls.
        var loops = 0
        while (todo.isNotEmpty() && loops < 10000) {
            loops++
            val triggering = todo.removeFirst()

            if (triggering.triggers.isEmpty()) continue

            val addingEvents = mutableListOf<Event>()

            triggerHandlers.forEach { handler ->
                fun TriggerContinuation.apply() {
                    when (this) {
                        TriggerContinuation.Nothing -> {}
                        is TriggerContinuation.Append -> addingEvents.addAll(this.events)
                        is TriggerContinuation.StartInteraction -> nextInteractions.add(this.interaction)
                        is TriggerContinuation.KeepInteraction -> interactionLifecycle = InteractionLifecycle.KEEP
                        TriggerContinuation.EndInteraction -> {
                            if (interactionLifecycle == InteractionLifecycle.KEEP) return
                            interactionLifecycle = InteractionLifecycle.END
                        }

                        is TriggerContinuation.StartInteractionBound -> nextBounds.add(this.bound)
                        is TriggerContinuation.EndInteractionBound -> boundLifecycle = InteractionLifecycle.END
                        is TriggerContinuation.Multi -> this.continuations.forEach { it.apply() }
                    }
                }

                try {
                    handler.trigger(triggering, interaction).apply()
                } catch (t: Throwable) {
                    logger.severe("Exception thrown while triggering handler $handler.")
                    t.printStackTrace()
                }
            }

            // We want to do the filtering before the next event
            //  but after all the handlers to make sure the criteria match as expected
            todo.addAll(addingEvents.map(Event::filterAllowedTriggers))
        }

        if (nextInteractions.isEmpty() && interactionLifecycle == InteractionLifecycle.END) {
            scope?.teardown()
            scope = null
            return
        }

        val nextBound = nextBounds.maxByOrNull { it.priority } ?: InteractionBound.Empty
        val scope = scope
        if (scope != null && (scope.bound.priority <= nextBound.priority || boundLifecycle == InteractionLifecycle.END)) {
            scope.swapBound(nextBound)
        }

        if (nextInteractions.isEmpty() && interactionLifecycle == InteractionLifecycle.KEEP) {
            return
        }

        val nextInteraction = nextInteractions.maxByOrNull { it.priority } ?: return
        // Only more or equal important interactions can override.
        if (nextInteraction.priority < (interaction?.priority
                ?: Int.MIN_VALUE) && interactionLifecycle != InteractionLifecycle.END
        ) {
            return
        }

        if (scope == null) {
            this.scope = InteractionScope(nextInteraction, nextBound)
            try {
                this.scope?.initialize()
            } catch (exception: Exception) {
                logger.severe("Something when wrong while trying to start ${nextInteraction}, skipping...")
                exception.printStackTrace()
                this.scope?.teardown()
                this.scope = null
            }
        } else {
            try {
                this.scope?.swapInteraction(nextInteraction)
            } catch (exception: Exception) {
                logger.severe("Exception thrown while trying to start ${nextInteraction}, skipping....")
                exception.printStackTrace()
                this.scope?.teardown()
                this.scope = null
            }
        }
    }

    fun <T : SessionTracker> tracker(klass: KClass<T>): T? {
        return klass.safeCast(trackers.firstOrNull { it::class.isSubclassOf(klass) })
    }

    suspend fun teardown() {
        try {
            sessionTickingJob?.cancel()
            scope?.teardown(force = true)
            trackers.forEach { it.teardown() }
        } catch (t: Throwable) {
            logger.severe("Exception thrown while tearing down session for player '${player.name}'.")
            t.printStackTrace()
        }
    }
}

internal val Player.interactionScope: InteractionScope?
    get() = with(KoinJavaComponent.get<PlayerSessionManager>(PlayerSessionManager::class.java)) {
        session?.scope
    }


val Player.interactionContext: InteractionContext?
    get() = with(KoinJavaComponent.get<PlayerSessionManager>(PlayerSessionManager::class.java)) {
        session?.interaction?.context
    }


private enum class InteractionLifecycle {
    NONE, KEEP, END
}