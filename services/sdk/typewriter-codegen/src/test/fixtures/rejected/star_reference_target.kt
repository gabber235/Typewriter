package fixture

// The generated endpoint exists only from the second KSP round, and KSP stops after a round with errors, so this
// case cannot share a compilation with first round diagnostics.

import com.typewritermc.types.Many
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000541")
data class LinkTarget(val title: String = "") : Resource

@ReferenceContract("fixture.links")
interface LinksContract {
    interface Source : Many<LinkTarget>
    interface Target : Many<LinkTarget>
}

@TypewriterType(id = "a0000000000000000000000000000544")
data class StarTarget(val link: Ref<Links.Source, *>) // error: StarTarget.link.target: A resource reference target cannot use a star projection.
