package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.expression.literal
import com.typewritermc.library.coreTagCollectionProjection
import com.typewritermc.presentation.projectedCollectionSource
import com.typewritermc.types.One
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000094")
data class LookupTarget(
    val name: String,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000095")
data class LookupHost(
    val selected: Ref<LookupRelation.Source, LookupTarget>,
) : Resource

@ReferenceContract("a0000000000000000000000000000096")
interface LookupRelationContract {
    interface Source : One<LookupHost>

    interface Target : One<LookupTarget>
}

object LookupResources {
    @TypewriterResourceDefinition("fixture.lookup_target", LookupTarget::class)
    val TARGET = ResourceDefinitionId("fixture.lookup_target")

    @TypewriterResourceDefinition("fixture.lookup_host", LookupHost::class)
    val HOST = ResourceDefinitionId("fixture.lookup_host")
}

object LookupHostInspector : LookupHostPresentation {
    override val roles: Set<PresentationRole> = setOf(PresentationRole.INSPECTOR)

    override fun LookupHostPresentationScope.present() {
        val targets = coreTagCollectionProjection().projectedCollectionSource()

        collectionLookup(targets, selected.input) {
            found { text(literal("found")) }
            missing { text(literal("missing")) }
        }
    }
}
