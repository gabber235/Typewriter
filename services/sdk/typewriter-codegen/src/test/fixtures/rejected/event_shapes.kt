package fixture

import com.typewritermc.events.Event
import com.typewritermc.identity.Protagonist
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000951")
data class Duel(
    val attacker: Protagonist,
    val defender: Protagonist, // error: An event names one field per identity kind until typed roles arrive.
) : Event
