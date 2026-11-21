package fixture

import com.typewritermc.events.Event
import com.typewritermc.events.Handler
import com.typewritermc.events.Verdict
import com.typewritermc.events.pass

class Poked : Event

@Handler suspend fun Poked.slowly(): Verdict = pass() // error: A verdict handler decides inline and never suspends.

@Handler fun String.notAnEvent() {} // error: A handler's receiver must be an event.

@Handler fun Poked.answer(): Int = 1 // error: A handler returns a Verdict to decide or Unit to run after the outcome.

@Handler
fun Poked.count(
    times: Int, // error: A handler parameter must be a Candidate, Origin, Outcome, identity, configuration, triggered entry field or trait interface.
) {
}
