@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.discovery

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.DisplayFormulas
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.RealmSectionDefinition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.use
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.elements.CueDefinition
import com.typewritermc.elements.ElementDefinition
import com.typewritermc.expression.field
import com.typewritermc.expression.input
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CapabilityExtensionSourcePart
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ProducerId
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.PageDefinition
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.library.fields
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.RuntimePresentationQueries
import com.typewritermc.presentation.of
import com.typewritermc.presentation.resource
import com.typewritermc.testkit.elementsOf
import com.typewritermc.testkit.fieldDeclaration
import com.typewritermc.testkit.generatedProviders
import com.typewritermc.testkit.origin
import com.typewritermc.testkit.recordType
import com.typewritermc.types.Color
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.Icon
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.of
import com.typewritermc.types.catalog.reasons
import com.typewritermc.types.fields
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.text
import com.typewritermc.types.toWire
import com.typewritermc.types.type
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.diagnostic.DeclarationOrigin
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValuePath
import java.lang.reflect.InvocationTargetException
import java.lang.reflect.Modifier
import java.nio.file.Files
import java.nio.file.Path
import java.util.Collections
import java.util.jar.JarEntry
import java.util.jar.JarOutputStream
import kotlin.reflect.KClass

internal fun NamedTypeTemplate.toUse() =
    definition.namedUse(
        arguments.map {
            when (it) {
                is TypeTemplate.ScalarWrapper -> {
                    it.value.use
                }

                else -> {
                    error("Test template is not complete.")
                }
            }
        },
    )

internal fun catalog(
    definitions: Map<TypeDefinitionId, TypeDefinition>,
    unavailable: TypeDefinitionId? = null,
) = DefaultCheckedCatalog(
    CatalogGeneration(value = "recommendations"),
    StandardTypes.definitions + definitions.values,
    quarantine = listOfNotNull(unavailable?.let { DeclarationDiagnostic.of(it, "fixture_unavailable") }),
)

internal interface FixtureRuntimeServiceContract

internal class FixtureRuntimeService : FixtureRuntimeServiceContract

internal class OwnerConsumer(
    val service: FixtureRuntimeServiceContract,
)

internal class CycleOwnerA(
    val next: CycleOwnerB,
)

internal class CycleOwnerB(
    val next: CycleOwnerA,
)

internal class FailingOwner {
    init {
        error("construction failed")
    }
}

class ShadowRegistrar : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor(RuntimeRegistrarId("shadow.runtime"), setOf(DiscoveryDomains.Execution))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar =
        instantiator.instantiate(ExecutionFixtureRegistrar::class.java) as RuntimeRegistrar
}

class DuplicateRegistrarProvider : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor(RuntimeRegistrarId("shadow.runtime"), setOf(DiscoveryDomains.Execution))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar =
        instantiator.instantiate(ExecutionFixtureRegistrar::class.java) as RuntimeRegistrar
}

class RealmFixtureRegistrarProvider : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor(RuntimeRegistrarId("realm.runtime"), setOf(DiscoveryDomains.Realm))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar =
        instantiator.instantiate(RealmFixtureRegistrar::class.java) as RuntimeRegistrar
}

class ExecutionFixtureRegistrar : RuntimeRegistrar {
    init {
        constructions += 1
    }

    context(scope: RuntimeScope)
    override suspend fun register() = Unit

    companion object {
        var constructions = 0
    }
}

class RealmFixtureRegistrar : RuntimeRegistrar {
    init {
        constructions += 1
    }

    context(scope: RuntimeScope)
    override suspend fun register() = Unit

    companion object {
        var constructions = 0
    }
}

internal fun providerArtifact(
    path: Path,
    sourcePart: String,
    corruptClass: Boolean = false,
    referencedClass: ByteArray? = null,
    providerClass: KClass<*> = ShadowRegistrar::class,
): Path {
    val providerName = providerClass.java.name
    val classPath = providerName.replace('.', '/') + ".class"
    val classBytes = requireNotNull(providerClass.java.getResourceAsStream("/$classPath")).use { it.readBytes() }
    if (corruptClass) classBytes[classBytes.lastIndex] = (classBytes.last() + 1).toByte()
    JarOutputStream(Files.newOutputStream(path)).use { archive ->
        archive.putNextEntry(JarEntry(GENERATED_PROVIDER_INDEX_PATH))
        archive.write("registrar\t$providerName\t$sourcePart\n".encodeToByteArray())
        archive.closeEntry()
        archive.putNextEntry(JarEntry(classPath))
        archive.write(classBytes)
        archive.closeEntry()
        referencedClass?.let { bytes ->
            archive.putNextEntry(JarEntry("fixture/Referenced.class"))
            archive.write(bytes)
            archive.closeEntry()
        }
    }
    return path
}

internal interface AbstractQueryResource : Resource

internal fun nativeIdentityAssembly(ambiguous: Boolean): CatalogAssembly {
    val origin = origin("native identity", "test:native_identity")
    val id = TypeDefinitionId.qualified("query.test", "Abstract")
    val definition =
        TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN))
    val descriptor =
        PresentationDescriptor.of(
            PresentationId(namespace = "test", name = "native_identity"),
            origin.owner,
            PresentationTarget.NamedWrapper(id.namedTemplate()),
            setOf(PresentationRole.INSPECTOR),
            0,
        )
    val provider =
        object : PresentationProvider {
            override fun build(binding: PresentationBuildBinding) =
                DefaultPresentationRuntime().build(binding) { scope ->
                    with(scope) {
                        val observed = resource<AbstractQueryResource>(literal(ResourceId("observed")))
                        text(observed.id.text.orElse(literal("")))
                    }
                }
        }
    return CatalogContributions(
        declarations =
            listOf(
                OwnedTypeDeclaration(origin, definition, nativeClass = AbstractQueryResource::class),
                OwnedTypeDeclaration(origin, ResourceIdDefinition.declaration, nativeClass = ResourceId::class),
            ) +
                if (ambiguous) {
                    listOf(
                        OwnedTypeDeclaration(
                            origin,
                            definition.copy(id = TypeDefinitionId.qualified("query.test", "Conflicting")),
                            nativeClass = AbstractQueryResource::class,
                        ),
                    )
                } else {
                    emptyList()
                },
        presentations = listOf(OwnedPresentation(origin, descriptor, provider)),
    ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "native identity")))
}

internal fun assemble(vararg extra: TypeDefinition): CatalogAssembly {
    val origin = origin("type_display", "test:type_display")
    val generated = generatedProviders<GeneratedTypeProvider>(GeneratedProviderKind.Type).distinctBy { it.definition.id }
    return CatalogContributions(
        declarations =
            generated.map { OwnedTypeDeclaration(origin, it.definition, it.display) } +
                extra.map { OwnedTypeDeclaration(origin, it) },
    ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "placement field publication")))
}

internal fun CatalogAssembly.placementField(type: TypeDefinitionId): ValuePath? = placementFields[type]

internal val section = TypeDefinitionId.qualified("structure", "Section")

internal val sectionsRelation = ownership("realm.sections", RealmRootDefinition.id, RealmSectionDefinition.id)

/** The realm root, the section contract, and one concrete section owned through the sections relation. */
internal fun structure(): List<OwnedTypeDeclaration> =
    listOf(
        resource(RealmRootDefinition.id),
        resource(RealmSectionDefinition.id, form = RecordForm.OPEN),
        resource(section, parents = listOf(RealmSectionDefinition.id)),
    )

internal fun assemble(
    declarations: List<OwnedTypeDeclaration>,
    relations: List<RelationContract> = listOf(sectionsRelation),
): CatalogAssembly =
    CatalogContributions(declarations = declarations, relations = relations)
        .assemble(CatalogAssemblyContext(CatalogGeneration(value = "realm structure")))

@JvmName("assembleDefinitions")
internal fun assemble(definitions: List<TypeDefinition>): CatalogAssembly = assemble(definitions.map { OwnedTypeDeclaration(origin, it) })

internal fun resource(
    id: TypeDefinitionId,
    form: RecordForm = RecordForm.CONCRETE,
    parents: List<TypeDefinitionId> = emptyList(),
) = OwnedTypeDeclaration(
    origin,
    recordType(
        id,
        form = form,
        parents =
            parents.map {
                it.namedTemplate()
            },
    ),
    searchKey = id.toString().filter(Char::isLetter).lowercase(),
)

internal fun ownership(
    relation: String,
    owner: TypeDefinitionId,
    member: TypeDefinitionId,
) = RelationContract.of(
    id = RelationId(value = relation),
    first =
        EndpointDefinition(
            id = EndpointId(value = "$relation:first"),
            slot = EndpointSlot.FIRST,
            resource = owner.namedTemplate(),
            cardinality = EndpointCardinality.ONE,
            onDelete = RelationDeletePolicy.CASCADE,
        ),
    second =
        EndpointDefinition(
            id = EndpointId(value = "$relation:second"),
            slot = EndpointSlot.SECOND,
            resource = member.namedTemplate(),
            cardinality = EndpointCardinality.MANY,
            onDelete = RelationDeletePolicy.CLEAR,
        ),
    families = setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID)),
)

internal fun DeclarationStatus.codes(): Set<String> =
    (this as? DeclarationStatus.UnavailableWrapper)?.reasons.orEmpty().mapTo(linkedSetOf()) {
        it.code
    }

internal val origin = origin("realm structure", "test:realm_structure")

/** A page type `id<T>` with a text title and contents of the free parameter T. */
internal fun genericType(id: TypeDefinitionId): Pair<TypeDefinitionId, Pair<TypeDefinition, TypeDisplay?>> {
    val parameter = ParameterKey(owner = id, index = 0)
    val field = {
        name: String,
        type: TypeTemplate,
        ->
        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = name), type = type)
    }
    return id to
        Pair(
            TypeDefinition.partial(
                id = id,
                parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                parents = listOf(PageDefinition.id.namedTemplate()),
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                field("title", ScalarKind.TEXT.template),
                                field("contents", TypeTemplate.ParameterWrapper(parameter)),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            ),
            null,
        )
}

internal fun fixtureType(
    id: TypeDefinitionId,
    parent: TypeDefinitionId? = null,
    display: TypeDisplay? = null,
) = id to
    Pair(
        TypeDefinition.partial(
            id = id,
            representation =
                RepresentationTemplate.createRecord(
                    fields = emptyList(),
                    form = RecordForm.CONCRETE,
                ),
            parents =
                listOfNotNull(parent).map {
                    it.namedTemplate()
                },
        ),
        display,
    )

internal fun endpoint(
    id: String,
    slot: EndpointSlot,
    resource: TypeDefinitionId,
) = EndpointDefinition(
    id = EndpointId(value = id),
    slot = slot,
    resource = resource.namedTemplate(),
    cardinality = EndpointCardinality.MANY,
    onDelete = RelationDeletePolicy.CLEAR,
)

internal fun book(title: String) =
    AuthoringRecord.of(
        TypeSelection.CompleteWrapper(BookDefinition.use),
        mapOf(
            "title" to DataValue.StringValueWrapper(title),
            "icon" to DataValue.UNFILLED,
            "color" to DataValue.UNFILLED,
            "tags" to DataValue.UNFILLED,
            "pages" to DataValue.UNFILLED,
        ),
    )

internal class FixtureDisplay(
    override val target: ResourceTarget,
    private val build: () -> DisplayFormulas,
) : GeneratedResourceDisplayProvider {
    override fun formulas(): DisplayFormulas = build()
}

internal fun displayProvider(
    target: ResourceTarget,
    build: () -> DisplayFormulas,
) = OwnedResourceDisplay(origin("type_display", "test:type_display"), FixtureDisplay(target, build))

internal fun assemble(
    declarations: List<Pair<TypeDefinitionId, Pair<TypeDefinition, TypeDisplay?>>> = emptyList(),
    displays: List<OwnedResourceDisplay> = emptyList(),
    searchKeys: Map<TypeDefinitionId, String> = emptyMap(),
    relations: List<RelationContract> = emptyList(),
    includeGenerated: Boolean = true,
): CatalogAssembly {
    val origin = origin("type_display", "test:type_display")
    val generated = generatedProviders<GeneratedTypeProvider>(GeneratedProviderKind.Type).distinctBy { it.definition.id }
    val generatedDisplays =
        generatedProviders<GeneratedResourceDisplayProvider>(GeneratedProviderKind.ResourceDisplay)
            .filter { includeGenerated || it.target == ResourceTarget.ANY_RESOURCE }
            .map { OwnedResourceDisplay(origin, it) }
    return CatalogContributions(
        declarations =
            generated.map { OwnedTypeDeclaration(origin, it.definition, it.display, searchKey = it.searchKey) } +
                declarations.map { (id, declared) ->
                    OwnedTypeDeclaration(origin, declared.first, declared.second, searchKey = searchKeys[id])
                },
        relations = generatedProviders<GeneratedRelationProvider>(GeneratedProviderKind.Relation).map { it.contract } + relations,
        displays = generatedDisplays + displays,
    ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "resource displays")))
}

internal fun CatalogAssembly.diagnosticCodes(type: TypeDefinitionId): List<String> =
    editorCatalog.diagnostics.filter { it.affected == type }.map { it.code }

internal fun CatalogAssembly.label(record: AuthoringRecord): String? =
    with(com.typewritermc.expression.FixtureReads) {
        displays.label(record, checked)
    }

internal fun artifact(
    id: String,
    kind: ArtifactKind,
) = ResolvedArtifact(ArtifactId(id), ArtifactVersion("1.0.0"), kind)

internal fun requirement(artifact: ResolvedArtifact) = ArtifactRequirement(artifact.id, VersionConstraint("^1"))
