package com.typewritermc.services.libs.registrar.koin

import com.typewritermc.services.libs.http.core.HttpMethod
import com.typewritermc.services.libs.http.core.HttpOperation
import com.typewritermc.services.libs.http.core.HttpRequest
import com.typewritermc.services.libs.http.core.HttpTransport
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.ServiceRegistrar
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.registrar.testing.FakeCredentialStorage
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import com.typewritermc.services.libs.utils.CoroutineDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import org.koin.dsl.koinApplication
import org.koin.dsl.module
import java.net.URI
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

val RegistrarKoinModuleTest by testSuite {
    test("closing the application closes the registrar HTTP transport") {
        val telemetry = OpenTelemetry.noop()
        val scope = CoroutineScope(SupervisorJob())
        val application =
            koinApplication {
                modules(
                    module {
                        single<OpenTelemetry> { telemetry }
                        single<ServiceTelemetry> { telemetry.serviceTelemetry("registrar-test") }
                        single<CredentialStorage> { FakeCredentialStorage() }
                    },
                    registrarModule(
                        RegistrarConfiguration(
                            identityIssueUri = URI("https://api.example.test/service/identity/issue"),
                            sentinelCredentialsUri = URI("https://api.example.test/auth/sentinel"),
                            oauthTokenUri = URI("https://auth.example.test/application/o/token/"),
                            oauthClientId = "typewriter-services",
                            oauthScopes = setOf("openid"),
                            natsServerUri = URI("nats://nats.example.test:4222"),
                            role = ServiceRole.Custom("realm", "1.0.0"),
                        ),
                        scope,
                        RetryPolicy.fixed(1.seconds),
                        CoroutineDelayScheduler,
                        TestTimeSource(),
                    ),
                )
            }
        val transport = application.koin.get<HttpTransport>()
        application.koin.get<ServiceRegistrar>()
        scope.cancel()
        application.close()
        val request =
            HttpRequest(
                HttpOperation("registrar.closed"),
                ErrorSlug.of("registrar-http-failed"),
                HttpMethod.GET,
                URI("https://api.example.test"),
            )
        shouldThrow<IllegalStateException> { transport.execute(request) }
    }
}
