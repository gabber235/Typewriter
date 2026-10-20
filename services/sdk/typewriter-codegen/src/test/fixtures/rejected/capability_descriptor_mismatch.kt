package fixture

import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.capability.RealmCommandCapabilityProvider

abstract class MismatchedCommandProvider : RealmCommandCapabilityProvider {
    override val descriptor: RealmCapabilityDescriptor.Computation // error: is not a subtype of overridden property 'val descriptor: RealmCapabilityDescriptor.Command'
        get() = error("A computation descriptor cannot advertise a command provider")
}
