package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000511")
data class RegisteredResource(val title: String = "") : Resource

@TypewriterType(id = "a0000000000000000000000000000512")
data class UnregisteredResource(val title: String = "") : Resource

object Definitions {
    @TypewriterResourceDefinition("fixture.registered", RegisteredResource::class)
    val REGISTERED = ResourceDefinitionId("fixture.registered")
}

@ReferenceContract("")
interface BlankContract { // error: Reference contracts require a stable id.
    interface Source : One<RegisteredResource>

    interface Target : Many<RegisteredResource>
}

@ReferenceContract("fixture.plain")
interface PlainEndpointContract { // error: Reference contracts require exactly two One or Many endpoint declarations.
    interface Source : One<String> // error: Relation endpoints must name a registered resource declaration.

    interface Target : Many<RegisteredResource>
}

@ReferenceContract("fixture.unregistered")
interface UnregisteredContract { // error: Reference contracts require exactly two One or Many endpoint declarations.
    interface Source : One<UnregisteredResource> // error: Concrete relation endpoints must belong to a registered resource root.

    interface Target : Many<RegisteredResource>
}

@ReferenceContract("fixture.single")
interface SingleEndpointContract { // error: Reference contracts require exactly two One or Many endpoint declarations.
    interface Source : One<RegisteredResource>
}
