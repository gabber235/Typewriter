package fixture

import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.capability.RealmCommandCapabilityProvider

abstract class MismatchedCommandProvider : RealmCommandCapabilityProvider {
    override val descriptor: RealmCapabilityDescriptor.Computation
        get() = error("A computation descriptor cannot advertise a command provider")
}
