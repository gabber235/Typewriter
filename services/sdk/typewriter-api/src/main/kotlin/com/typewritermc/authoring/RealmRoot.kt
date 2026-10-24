package com.typewritermc.authoring

import com.typewritermc.types.DeletionPolicy
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Owning
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType
import skirout.editor.v1.catalog.PresentationRole

/**
 * The realm root: the only resource without an owner.
 *
 * Every realm holds exactly one root, created by the realm on start, and every other resource reaches it through its
 * owner chain. The root owns one instance of every concrete [RealmSection] type; [sections] is read only for
 * presentations and authors, because the realm alone creates sections and never removes them.
 */
@TypewriterType(id = "7a2c4c007a8f40e4a7b2c5e452b9e00b")
@TypewriterDisplay(
    name = "Realm",
    description = "Top level areas of the realm",
    icon = "material-symbols:public",
    color = "#455A64",
)
data class RealmRoot(
    val sections: List<Ref<RealmSections.Root, RealmSection>> = emptyList(),
) : Resource

/**
 * A top level area of the realm, such as the library or the tags, owned by the root.
 *
 * The realm creates one instance of every concrete section type on start, so an extension adds a top level area by
 * declaring a concrete, non generic section type with the link field of its members. Section types must not declare
 * type parameters, because the realm could not choose their arguments.
 */
@TypewriterRecordContract
interface RealmSection : Resource

/** Ownership of the realm sections by the realm root. Deleting the root deletes every section. */
@ReferenceContract(REALM_SECTIONS_RELATION_ID)
interface RealmSectionsContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Root : One<RealmRoot>

    interface Section : Many<RealmSection>
}

const val REALM_SECTIONS_RELATION_ID = "da73861f6cae48bd8df1c834be4bff65"

/** The shell sidebar: every section of the realm, each opening its own workspace. Sections are never unlinked. */
object RealmNavigator : RealmRootPresentation {
    override val roles = setOf(PresentationRole.NAVIGATOR)

    override fun RealmRootPresentationScope.present() {
        sections {
            readOnly(true)
            list()
        }
    }
}
