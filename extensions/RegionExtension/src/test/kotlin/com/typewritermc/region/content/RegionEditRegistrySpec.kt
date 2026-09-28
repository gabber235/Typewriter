package com.typewritermc.region.content

import com.typewritermc.core.entries.Ref
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.data.RegionReferenceData
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import java.util.*

class RegionEditRegistrySpec : FunSpec({
    val alice = UUID.fromString("00000000-0000-0000-0000-000000000001")
    val bob = UUID.fromString("00000000-0000-0000-0000-000000000002")

    test("the first editor claims the lock and gets the session") {
        val registry = RegionEditRegistry()
        val session = registry.tryStartEditing(alice, "Alice", "region")
        session.shouldNotBeNull()
        session.editorId shouldBe alice
        session.editorName shouldBe "Alice"
        registry.isEditing(alice, "region").shouldBeTrue()
    }

    test("a second player cannot claim a locked entry") {
        val registry = RegionEditRegistry()
        registry.tryStartEditing(alice, "Alice", "region").shouldNotBeNull()
        registry.tryStartEditing(bob, "Bob", "region").shouldBeNull()
        registry.sessionOf("region")?.editorName shouldBe "Alice"
    }

    test("the holder reclaims its own session instead of a new one") {
        val registry = RegionEditRegistry()
        val first = registry.tryStartEditing(alice, "Alice", "region")
        val again = registry.tryStartEditing(alice, "Alice", "region")
        again shouldBe first
    }

    test("different entries lock independently") {
        val registry = RegionEditRegistry()
        registry.tryStartEditing(alice, "Alice", "hub").shouldNotBeNull()
        registry.tryStartEditing(bob, "Bob", "arena").shouldNotBeNull()
    }

    test("stopping releases the lock for the next editor") {
        val registry = RegionEditRegistry()
        registry.tryStartEditing(alice, "Alice", "region")
        registry.stopEditing(alice, "region")
        registry.sessionOf("region").shouldBeNull()
        registry.tryStartEditing(bob, "Bob", "region").shouldNotBeNull()
    }

    test("a non holder cannot release the lock") {
        val registry = RegionEditRegistry()
        registry.tryStartEditing(alice, "Alice", "region")
        registry.stopEditing(bob, "region")
        registry.isEditing(alice, "region").shouldBeTrue()
    }

    test("the editor and registered spectators have a live view, others do not") {
        val registry = RegionEditRegistry()
        val session = registry.tryStartEditing(alice, "Alice", "region").shouldNotBeNull()
        registry.hasLiveView(alice, "region").shouldBeTrue()
        registry.hasLiveView(bob, "region").shouldBeFalse()
        session.spectators.add(bob)
        registry.hasLiveView(bob, "region").shouldBeTrue()
    }

    test("suppression follows the live view through references and owner entries") {
        val registry = RegionEditRegistry()
        val session = registry.tryStartEditing(alice, "Alice", "definition").shouldNotBeNull()
        val reference = RegionReferenceData(Ref("definition", RegionDefinitionEntry::class))

        registry.isSuppressed(alice, null, reference).shouldBeTrue()
        registry.isSuppressed(bob, null, reference).shouldBeFalse()
        session.spectators.add(bob)
        registry.isSuppressed(bob, null, reference).shouldBeTrue()
        registry.isSuppressed(bob, "definition", RegionReferenceData()).shouldBeTrue()
    }
})
