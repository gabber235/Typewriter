@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.field
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.capability.RealmCapabilityPermissionDeniedException
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.library.Book
import com.typewritermc.library.TAXONOMY_TAGS_RELATION_ID
import com.typewritermc.library.Tag
import com.typewritermc.library.TagDefinition
import com.typewritermc.operations.AnyResourceSubjects
import com.typewritermc.operations.LinkWithInput
import com.typewritermc.operations.LinkWithInputDefinition
import com.typewritermc.operations.LinkWithInputFields
import com.typewritermc.operations.OperationInput
import com.typewritermc.operations.ResourceOperationSpecImpl
import com.typewritermc.operations.collectOperation
import com.typewritermc.operations.fillOnDrop
import com.typewritermc.setup.SetupHandle
import com.typewritermc.types.endpointId
import com.typewritermc.types.fieldMap
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.payload
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.type
import com.typewritermc.types.use
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.operation.ResourceOperationId
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** The saved resource a setup handle names, as routes and saved records address it. */
internal val SetupHandle<*>.resource: ResourceId get() = id.toSkir()

/** The simple name of the operation object [ResourceOperationId] declares. */
internal val ResourceOperationId.simpleName get() = declaration.substringAfterLast('.')

/** A book and three tags; `tag` is a child of `parent`, `loose` has no relations. */
internal data class TagGraph(
    val book: SetupHandle<Book>,
    val tag: SetupHandle<Tag>,
    val parent: SetupHandle<Tag>,
    val loose: SetupHandle<Tag>,
)

/** Three pages of a source book with their chapters and priorities, and a destination book with its own pages. */
internal data class Shelves(
    val destination: SetupHandle<Book>,
    val moved: List<SetupHandle<*>>,
    val residents: List<SetupHandle<*>>,
)

/** Two graph pages and a page without a graph layout, each holding one entry. */
internal data class Canvas(
    val book: SetupHandle<Book>,
    val graph: SetupHandle<*>,
    val canvas: SetupHandle<*>,
    val timeline: SetupHandle<*>,
    val graphEntry: SetupHandle<*>,
    val residentEntry: SetupHandle<*>,
    val timelineEntry: SetupHandle<*>,
)

/** The message a fixture guard refuses the author with. */
internal const val LOCKED = "Tags are locked for this member."

/** The placement of a graph entry, read from its saved record. */
internal fun AuthoringRecord.graphPlacement(): GraphPlacement {
    val fields = ((fieldMap.getValue("placement") as DataValue.NamedWrapper).payload as DataValue.RecordWrapper).value.fieldMap

    fun int(name: String) = (fields.getValue(name) as DataValue.IntegerWrapper).value.toInt()
    return GraphPlacement(int("x"), int("y"), int("width"), int("height"))
}

/** Whether two placements overlap, leaving no gap of one cell between them. */
internal fun GraphPlacement.intersectsWithGap(other: GraphPlacement): Boolean =
    x.toLong() < other.x.toLong() + other.width + 1 && x.toLong() + width + 1 > other.x &&
        y.toLong() < other.y.toLong() + other.height + 1 && y.toLong() + height + 1 > other.y

/** A Tag operation that drops its subject onto tags, with an operation search on its drop field. */
internal fun tagOnly(origin: ProviderOrigin) =
    collectOperation<ResourceDraft, LinkWithInput>(
        origin,
        "fixture.TagOnly",
        ResourceTarget.type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.Typed(LinkWithInputDefinition.use),
        "Tag only",
    ) { spec ->
        with(ResourceOperationSpecImpl(spec)) {
            input { LinkWithInputFields.target { candidates { emptySequence() } } }
            prepare { }
        }
    }

/** A Tag operation whose drop field declares more candidates than one drag may receive. */
internal fun manyCandidates(origin: ProviderOrigin) =
    collectOperation<ResourceDraft, LinkWithInput>(
        origin,
        "fixture.ManyCandidates",
        ResourceTarget.type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.Typed(LinkWithInputDefinition.use),
        "Many candidates",
    ) { spec ->
        with(ResourceOperationSpecImpl(spec)) {
            input {
                LinkWithInputFields.target {
                    candidates { (0 until 250).asSequence().map { ResourceId(value = "candidate-$it").toResourceId() } }
                    fillOnDrop()
                }
            }
            prepare { }
        }
    }

/** A Tag operation that releases its subject from the taxonomy, leaving it without an owner. */
internal fun orphanTag(origin: ProviderOrigin) =
    collectOperation<ResourceDraft, Unit>(
        origin,
        "fixture.OrphanTag",
        ResourceTarget.type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.None,
        "Orphan tag",
    ) { spec ->
        with(ResourceOperationSpecImpl(spec)) {
            prepare {
                val owner = RelationId(value = TAXONOMY_TAGS_RELATION_ID).endpointId(EndpointSlot.SECOND)
                disconnect(
                    LinkOccurrenceId(endpoint = owner, location = ValueLocation.of(subjects.single(), ValuePath.root.field("taxonomy"))),
                )
            }
        }
    }

/** A Tag operation whose availability and drop candidates need a permission the caller lacks. */
internal fun guarded(origin: ProviderOrigin) =
    collectOperation<ResourceDraft, LinkWithInput>(
        origin,
        "fixture.Guarded",
        ResourceTarget.type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.Typed(LinkWithInputDefinition.use),
        "Guarded",
    ) { spec ->
        with(ResourceOperationSpecImpl(spec)) {
            availableWhen { throw RealmCapabilityPermissionDeniedException(LOCKED) }
            input {
                LinkWithInputFields.target {
                    candidates { throw RealmCapabilityPermissionDeniedException(LOCKED) }
                    fillOnDrop()
                }
            }
            prepare { }
        }
    }

/** A Tag operation whose availability always fails. */
internal fun brokenAvailability(origin: ProviderOrigin) =
    collectOperation<ResourceDraft, Unit>(
        origin,
        "fixture.BrokenAvailability",
        ResourceTarget.type(TagDefinition.id.namedTemplate()),
        AnyResourceSubjects,
        OperationInput.None,
        "Broken availability",
    ) { spec ->
        with(ResourceOperationSpecImpl(spec)) {
            availableWhen { error("Unselected callback failure") }
            prepare { error("Unavailable operation must never prepare") }
        }
    }
