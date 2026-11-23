package fixture

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.Entry
import com.typewritermc.events.Candidate
import com.typewritermc.events.Event
import com.typewritermc.events.Handler
import com.typewritermc.events.SubscribedEvent
import com.typewritermc.events.Triggered
import com.typewritermc.events.Verdict
import com.typewritermc.events.pass
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Var
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterType

class Poked : Event

@Handler suspend fun Poked.slowly(): Verdict = pass() // error: A verdict handler decides inline and never suspends.

@Handler fun String.notAnEvent() {} // error: A handler's receiver must be an event or a Triggered step.

@Handler fun Poked.answer(): Int = 1 // error: A handler returns a Verdict to decide or Unit to run after the outcome.

@Handler
fun Poked.count(
    times: Int, // error: A handler parameter must be a Candidate, Origin, Outcome, identity, subscription or trait interface.
) {
}

data class Ticked<S : Any>(
    override val subscription: S,
) : SubscribedEvent<S>

class Loose

@Handler fun Ticked<Loose>.loose() {} // error: A subscribed event's subscription must be a Kotlin object or an entry type.

@Handler fun <S : Any> Ticked<S>.anySubscription() {} // error: A subscribed event's subscription must be a Kotlin object or an entry type.

@TypewriterType(id = "a0000000000000000000000000000951")
class NoteEntry(
    override val page: Ref<PageElements.Element, Page>,
    override val name: String,
    override val placement: GraphPlacement,
    val message: Var<String, DefinitionScope>,
) : Entry

@Handler
fun Triggered<NoteEntry>.note(
    message: String, // error: A handler reads entry values through accessors: read `message` in the body instead of a parameter.
) {
}

@Handler
fun Poked.check(
    note: Candidate<NoteEntry>,
    message: String, // error: A handler reads entry values through accessors: read `note.message` in the body instead of a parameter.
) {
}

@TypewriterType(id = "a0000000000000000000000000000952")
class Reply(
    val text: String,
    val context: String,
    val recordPath: Int, // error: A record field cannot be named `recordPath`: `RecordScope.recordPath` hides its accessor; rename the field.
)

@TypewriterType(id = "a0000000000000000000000000000953")
class ClashEntry(
    override val page: Ref<PageElements.Element, Page>,
    override val name: String,
    override val placement: GraphPlacement,
    val context: String, // error: A record field cannot be named `context`: `EntryScope.context` hides its accessor; rename the field.
    val reader: Int, // error: A record field cannot be named `reader`: `EntryScope.reader` hides its accessor; rename the field.
    val priority: Int, // error: A record field cannot be named `priority`: `Candidate.priority` hides its accessor; rename the field.
    val event: String, // error: A record field cannot be named `event`: `Triggered.event` hides its accessor; rename the field.
) : Entry
