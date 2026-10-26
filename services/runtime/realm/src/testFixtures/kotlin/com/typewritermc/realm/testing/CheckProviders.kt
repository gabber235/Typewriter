package com.typewritermc.realm.testing

import com.typewritermc.checking.RealmCheckProvider
import com.typewritermc.discovery.OwnedCheck
import com.typewritermc.discovery.OwnedConfiguration
import com.typewritermc.discovery.OwnedNativeBinding
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedProviderRegistry
import com.typewritermc.discovery.ProviderLease
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.realm.authoring.TEST_TYPE
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId
import java.util.concurrent.atomic.AtomicInteger

/** Providers that register [provider]'s checks as the rule origin [ordinal] of [owner]. */
fun checksOf(
    ordinal: Int,
    provider: RealmCheckProvider,
    owner: TypeDefinitionId = TEST_TYPE,
) = TestCheckProviders(listOf(OwnedCheck(CHECK_PROVIDER_ORIGIN, RuleOrigin(owner = owner, ordinal = ordinal), provider)))

/**
 * A provider registry with only [ownedChecks]. It counts the provider leases still open, and the retain numbered
 * [failOnRetain] fails, as a provider that cannot load does.
 */
class TestCheckProviders(
    private val ownedChecks: List<OwnedCheck>,
    private val failOnRetain: Int? = null,
) : OwnedProviderRegistry {
    val openLeases = AtomicInteger()
    private val retainCalls = AtomicInteger()

    override fun retain(origin: ProviderOrigin): ProviderLease {
        check(retainCalls.incrementAndGet() != failOnRetain) { "provider retain failed" }
        openLeases.incrementAndGet()
        return object : ProviderLease {
            private var open = true

            override fun close() {
                if (open) {
                    open = false
                    openLeases.decrementAndGet()
                }
            }
        }
    }

    override fun configurations(): List<OwnedConfiguration> = emptyList()

    override fun presentations(): List<OwnedPresentation> = emptyList()

    override fun nativeBindings(): List<OwnedNativeBinding> = emptyList()

    override fun checks(): List<OwnedCheck> = ownedChecks
}

/** The provider origin every check of [checksOf] is registered under. */
val CHECK_PROVIDER_ORIGIN =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                source =
                    contributionKey(
                        source = ContributionSourceId("test:checks"),
                        sourcePart = "checks",
                        producer = ProducerId("tests"),
                        name = ContributionName("realm"),
                    ),
                localIdentity = "checks",
            ),
        artifact = ArtifactId("test:checks"),
        sourcePart = "checks",
    )
