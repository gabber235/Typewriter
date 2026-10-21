package fixture

import com.typewritermc.capability.RealmCommandCapabilityProvider
import skirout.editor.v1.capability.ComputationCapabilityDefinition

abstract class MismatchedCommandProvider : RealmCommandCapabilityProvider {
    override val descriptor: ComputationCapabilityDefinition // error: is not a subtype of overridden property 'val descriptor: CommandCapabilityDefinition'
        get() = error("A computation descriptor cannot advertise a command provider")
}
