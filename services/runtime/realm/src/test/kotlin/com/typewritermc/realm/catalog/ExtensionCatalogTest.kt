package com.typewritermc.realm.catalog

import com.typewritermc.discovery.CollectedDynamics
import com.typewritermc.realm.checking.RerunChecks
import com.typewritermc.realm.testing.TestCheckProviders
import com.typewritermc.realm.testing.checksOf
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldNotBeEmpty
import io.kotest.matchers.shouldBe

val ExtensionCatalogTest by testSuite {
    test("collecting extensions that fails to retain a provider releases every retain it took") {
        val providers = TestCheckProviders(checksOf(30, RerunChecks).checks() + checksOf(31, RerunChecks).checks(), failOnRetain = 2)
        val extensions = CollectedExtensions { collectExtensions(emptyList(), emptyList(), CollectedDynamics.NONE, providers) }

        shouldThrow<IllegalStateException> { extensions.value }.message shouldBe "provider retain failed"
        providers.openLeases.get() shouldBe 0

        extensions.value.plans.shouldNotBeEmpty()
        providers.openLeases.get() shouldBe 2
        extensions.close()
        providers.openLeases.get() shouldBe 0
    }
}
