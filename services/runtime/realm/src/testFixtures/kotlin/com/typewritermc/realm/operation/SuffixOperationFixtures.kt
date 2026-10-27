@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.operation

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.library.tag
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.operations.capability
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.types.toResourceIds
import skirout.editor.v1.type_catalog.DataValue
import skirout.kernel.v1.resource_id.ResourceId

internal const val DECLARATION = "fixture.InlineOperations"

/** The suffix operation run through the runtime for [tag], against the saved state plus [named] as a working name. */
internal class SuffixRun(
    private val realm: RealmFixture,
    private val tag: ResourceId,
) {
    val runtime = ResourceOperationRuntime(realm.views)
    val invocation = OperationInvocation("suffix", listOf(tag).toResourceIds())
    val observation = realm.views.read { it.observationId }
    val capability =
        realm.views.read { root ->
            root.catalog.operations.operations
                .single { it.definition.id.declaration == DECLARATION }
                .definition.id.capability
        }

    /** The saved tag with its name replaced by [name], as the panel's working overlay sends it. */
    fun named(name: DataValue) = mapOf(tag to realm.resources.getValue(tag).with("name", name))

    fun resolve(name: DataValue) = runtime.resolve(invocation, realm.generation, observation, named(name), emptySet())

    suspend fun prepare(name: String): OperationPreparationResult =
        runtime.prepare(
            invocation,
            realm.generation,
            capability,
            observation,
            named(DataValue.StringValueWrapper(name)),
            emptySet(),
            null,
            PreparationChoices(),
        )

    fun availability(name: DataValue) = resolve(name).operations.single { it.definition.id.declaration == DECLARATION }.availability
}
