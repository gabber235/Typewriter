package com.typewritermc.loader.deployment

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.deployment.testing.PANEL
import com.typewritermc.loader.deployment.testing.PAPER
import com.typewritermc.loader.deployment.testing.Refusal
import com.typewritermc.loader.deployment.testing.capability
import com.typewritermc.loader.deployment.testing.engine
import com.typewritermc.loader.deployment.testing.realm
import com.typewritermc.loader.deployment.testing.requirement
import com.typewritermc.loader.deployment.testing.resolve
import com.typewritermc.loader.deployment.testing.selection
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf

val DeploymentResolutionTest by testSuite {
    test("resolution picks the newest version of every artifact that the selected hosts support") {
        val result =
            resolve(
                realm("1.0.0"),
                realm("1.2.0"),
                realm("1.3.0", hostApi = "^2"),
                engine(PAPER, "1.0.0"),
                engine(PAPER, "1.4.0"),
                engine(PAPER, "2.0.0"),
                engine(PANEL, "1.1.0"),
            )

        val content = result.shouldBeInstanceOf<ResolutionResult.Resolved>().content
        content.realm.coordinate.version shouldBe ArtifactVersion("1.2.0")
        content.primaryEngine.coordinate.version shouldBe ArtifactVersion("1.4.0")
        content.panelEngine.coordinate.version shouldBe ArtifactVersion("1.1.0")
    }

    listOf(
        Refusal(
            "no Realm artifact was imported",
            listOf(engine(PAPER, "1.0.0"), engine(PANEL, "1.0.0")),
            "Accepted candidates must contain exactly one Realm artifact identity.",
        ),
        Refusal(
            "two Realm artifact identities were imported",
            listOf(realm("1.0.0"), realm("1.0.0", id = "typewritermc:other-realm"), engine(PAPER, "1.0.0"), engine(PANEL, "1.0.0")),
            "Accepted candidates must contain exactly one Realm artifact identity.",
        ),
        Refusal(
            "no Realm artifact supports the Realm host API",
            listOf(realm("1.0.0", hostApi = "^2"), engine(PAPER, "1.0.0"), engine(PANEL, "1.0.0")),
            "No Realm artifact supports the Realm host API.",
        ),
        Refusal(
            "no primary engine supports the primary host API",
            listOf(realm("1.0.0"), engine(PAPER, "1.0.0", hostApi = "^2"), engine(PANEL, "1.0.0")),
            "No compatible primary engine satisfies $PAPER ^1.",
        ),
        Refusal(
            "no panel engine satisfies the Realm's panel requirement",
            listOf(realm("1.0.0"), engine(PAPER, "1.0.0"), engine(PANEL, "2.0.0")),
            "No compatible panel engine satisfies $PANEL ^1.",
        ),
    ).forEach { (name, candidates, problem) ->
        test("resolution is refused when $name") {
            resolve(*candidates.toTypedArray()).shouldBeInstanceOf<ResolutionResult.Rejected>().problems shouldContain problem
        }
    }

    test("resolution is refused when one artifact would deploy in two versions") {
        // The panel and the primary engine are the same artifact, but their requirements select different versions.
        val result =
            resolveDeployment(
                CandidateIndex(listOf(realm("1.0.0"), engine(PAPER, "1.0.0"), engine(PAPER, "2.0.0"))),
                selection,
                PrimaryEngineTarget(ArtifactId(PAPER), VersionConstraint("^1")),
                RealmLoaderIntent(ArtifactRequirement(ArtifactId(PAPER), VersionConstraint("^2"))),
            )

        result shouldBe ResolutionResult.Rejected(listOf("Deployment artifact $PAPER resolved to multiple versions."))
    }

    test("an engine whose capability requirement differs from its resolved capability graph is refused at import") {
        shouldThrow<IllegalArgumentException> {
            engine(PAPER, "1.0.0", direct = listOf(requirement(ITEMS, "^2")), resolved = listOf(capability(ITEMS, "1.5.0")))
        }.message shouldBe "Engine capability requirement $ITEMS does not match its resolved graph."
        shouldThrow<IllegalArgumentException> {
            engine(PAPER, "1.0.0", direct = listOf(requirement(ITEMS, "^1")), resolved = emptyList())
        }.message shouldBe "Engine capability requirement $ITEMS does not match its resolved graph."
    }

    test("an engine whose capability graph lists one capability twice is refused at import") {
        shouldThrow<IllegalArgumentException> {
            engine(PAPER, "1.0.0", resolved = listOf(capability(ITEMS, "1.5.0"), capability(ITEMS, "1.6.0")))
        }.message shouldBe "Engine capability graph contains duplicate artifact identities."
    }
}

private const val ITEMS = "typewritermc:items"
