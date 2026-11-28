package com.typewritermc.playtest.plugin

/**
 * The work ledger's watch on time the test moves: [advance] moves it and runs every alarm then due, in the order they
 * come due, each at its own moment.
 */
class ManualWatch : WorkLedger.Watch {
    private var now = 0L
    private val alarms = mutableListOf<Pair<Long, Runnable>>()

    /** When each alarm still set comes due, in nanoseconds since the watch started. */
    val pending: List<Long> get() = alarms.map { it.first }

    override fun nanoTime(): Long = now

    override fun after(
        nanos: Long,
        task: Runnable,
    ) {
        alarms += (now + nanos) to task
    }

    /** Moves time [nanos] on, running each alarm that comes due on the way. */
    fun advance(nanos: Long) {
        val until = now + nanos
        while (true) {
            val next = alarms.filter { it.first <= until }.minByOrNull { it.first } ?: break
            alarms.remove(next)
            now = next.first
            next.second.run()
        }
        now = until
    }
}
