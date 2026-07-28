package com.typewritermc.services.libs.registrar.koin

import com.typewritermc.services.libs.http.core.HttpTransport
import com.typewritermc.services.libs.http.jdk.JdkHttpTransport
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.RegistrarRuntimeFactory
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.registrar.testing.FakeCredentialStorage
import com.typewritermc.services.libs.registrar.testing.RegistrarActionLedger
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.matchers.types.shouldBeSameInstanceAs
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import java.net.URI

val RegistrarKoinModuleTest by testSuite {
    test("resolves singleton graph without starting registrar lifecycle") {
        val telemetry = OpenTelemetry.noop()
        val ledger = RegistrarActionLedger()
        val scope = CoroutineScope(SupervisorJob())
        val application = koinApplication {
            modules(
                module {
                    single<OpenTelemetry> { telemetry }
                    single<ServiceTelemetry> { telemetry.serviceTelemetry("registrar-test") }
                    single<CredentialStorage> { FakeCredentialStorage(ledger = ledger) }
                },
                registrarModule(configuration(), scope),
            )
        }
        try {
            application.koin.get<ServiceRegistrar>() shouldBeSameInstanceAs
                application.koin.get<ServiceRegistrar>()
            application.koin.get<RegistrarRuntimeFactory>().shouldBeInstanceOf<RegistrarRuntimeFactory>()
            application.koin.get<HttpTransport>().shouldBeInstanceOf<JdkHttpTransport>()
            ledger.actions.shouldBeEmpty()
        } finally {
            (application.koin.get<HttpTransport>() as AutoCloseable).close()
            scope.cancel()
            application.close()
        }
    }
}

private fun configuration() = RegistrarConfiguration(
    identityIssueUri = URI("https://api.example.test/service/identity/issue"),
    sentinelCredentialsUri = URI("https://api.example.test/auth/sentinel"),
    oauthTokenUri = URI("https://auth.example.test/application/o/token/"),
    oauthClientId = "typewriter-services",
    oauthScopes = setOf("openid"),
    natsServerUri = URI("nats://nats.example.test:4222"),
    roles = listOf(ServiceRole.Realm("1.0.0")),
)
