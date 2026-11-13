@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.boundCollectionPath
import com.typewritermc.authoring.of
import com.typewritermc.authoring.with
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.BookFields
import com.typewritermc.library.BookPages
import com.typewritermc.library.BookTags
import com.typewritermc.library.LibraryBooks
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.LibraryFields
import com.typewritermc.library.PageDefinition
import com.typewritermc.library.Tag
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.TagFields
import com.typewritermc.library.TagParents
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.library.TaxonomyFields
import com.typewritermc.library.TaxonomyTags
import com.typewritermc.realm.authoring.valueAt
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.codes
import com.typewritermc.realm.testing.itemIds
import com.typewritermc.realm.testing.link
import com.typewritermc.realm.testing.linkTargets
import com.typewritermc.realm.testing.links
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.typesOf
import com.typewritermc.testing.routes.FixtureTimelinePage
import com.typewritermc.testing.routes.FixtureTimelinePageDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.items
import com.typewritermc.types.namedUse
import com.typewritermc.types.toResourceId
import com.typewritermc.types.unwrapNamed
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.bind
import io.kotest.property.arbitrary.boolean
import io.kotest.property.arbitrary.choose
import io.kotest.property.arbitrary.constant
import io.kotest.property.arbitrary.enum
import io.kotest.property.arbitrary.int
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.map
import io.kotest.property.checkAll
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/**
 * Generated authoring sessions over the core types: books in the library, pages in books, tags in the taxonomy, tags on
 * books and tag parents. Each step is committed the way an author's edit arrives, and checked against a small model
 * that keeps its own rules for which steps the Realm must refuse.
 */
val RealmInvariantsTest by testSuite {
    /** Fixed seed and count, so every run replays the same sessions; change them only on purpose. */
    val sessionConfig = PropTestConfig(seed = 7_204_613_998L, iterations = 100)

    /** Long enough sessions that tags gain parents and books gain pages before they are unlinked or deleted again. */
    val stepCounts = 10..40

    test("no sequence of author edits leaves a broken realm or disagrees with the model") {
        checkAll(sessionConfig, Arb.list(step, stepCounts)) { steps ->
            RealmFixture.core(catalog = routeFixtureCatalog).use { realm ->
                val structure = realm.resources.keys
                val model = RealmModel(library = realm.singleOf(LibraryDefinition.id), taxonomy = realm.singleOf(TaxonomyDefinition.id))
                steps.forEachIndexed { index, step ->
                    val action = model.resolve(step) ?: return@forEachIndexed
                    withClue("step ${index + 1} of $steps resolved to $action") {
                        val before = realm.resources
                        val refusal = model.refusal(action)
                        val response = realm.write(action)
                        if (refusal == null) {
                            response.shouldBeCommitted()
                            model.apply(action)
                        } else {
                            response.shouldBeInstanceOf<CommitPreparedEditResponse.RejectedErrorWrapper>().value.codes shouldContainAll
                                listOf(refusal)
                            realm.resources shouldBe before
                        }
                        realm.resources.shouldHoldInvariants()
                        realm.resources.shouldMatch(model, structure)
                    }
                }
            }
        }
    }
}
