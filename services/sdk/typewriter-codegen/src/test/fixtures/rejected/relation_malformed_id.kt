package fixture

import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "not-a-uuid")
data class MalformedResource(val title: String = "") : Resource // error: Typewriter type ids must be UUIDs.

@ReferenceContract("fixture.malformed")
interface MalformedContract { // error: Reference contracts require exactly two One or Many endpoint declarations.
    interface Source : One<MalformedResource> // error: Relation endpoint resources require valid Typewriter type ids.

    interface Target : Many<MalformedResource> // error: Relation endpoint resources require valid Typewriter type ids.
}
