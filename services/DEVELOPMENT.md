# Service development

`services/` is one Gradle multiproject build. `build-logic` and `imprint` are the only included builds because Gradle needs both while configuring normal projects.

## Project ownership

- `protocol` owns generated Kotlin Skir contracts.

- `typewriter-api` owns the shared programming model used by Realm, engines, capabilities, and extensions.

- `typewriter-codegen` owns every Typewriter KSP processor. Every Imprint artifact receives it automatically.

- `service-sdk` owns the supported service identity, organization binding, authentication, messaging, status, and shutdown lifecycle.

- `messaging`, `file-transfer`, and `telemetry` own the supported platform implementations and their deterministic test utilities.

- Loader projects remain separate because their API, core, standalone, Paper, and distribution classpaths differ.

- Engine projects remain separate when they represent an API, runtime artifact, capability artifact, or distinct classpath.

Realm remains one deployable project.

## Verification

Run complete service verification from `services/`:

```shell
./gradlew check ktlintCheck
```

Build canonical development artifacts:

```shell
./gradlew assembleDevelopmentArtifacts
```

Verify the Loader distribution:

```shell
./gradlew :loader-distribution:verifyDistribution
```

Regenerate contracts from the repository root:

```shell
bunx --no-install skir format --ci
bunx --no-install skir gen
```

Never add another nested Gradle root for a normal service project. `services/settings.gradle.kts` rejects it.

## Discovery development

Imprint assembles one canonical manifest for each artifact. KSP processors contribute static metadata and generated module providers. Realm discovery loads only Realm bindings. Execution discovery loads only execution bindings. Each deployment owns an isolated Koin application and classloader.

The conformance extension proves declared type identities, generated prototypes, element descriptors, source part eligibility, generated registrars, generated facets, and engine targeting.

## Runtime status

Loader host assignment, deployment selection, artifact staging, and runtime discovery are connected:

- [LoaderApplication](runtime/loader/core/src/main/kotlin/com/typewritermc/loader/LoaderApplication.kt) uses `BackendArtifactHostAssignmentSource` to register the host and watch backend execution assignments. Standalone development can instead select a local assignment with `TYPEWRITER_LOCAL_REALM_ID`.
- [ArtifactHost](runtime/loader/core/src/main/kotlin/com/typewritermc/loader/rollout/ArtifactHost.kt) connects assignments to rollout participants. The Realm host resolves accepted artifact candidates and coordinates staging, activation, health checks, and recovery through `CoordinatedRollout`.
- [HostRolloutParticipant](runtime/loader/core/src/main/kotlin/com/typewritermc/loader/rollout/HostRolloutParticipant.kt) stages projected artifacts through `HostedRuntimeLoader`, which requires exactly one `HostedRuntimeProvider` per hosted runtime classpath. Commit activates the staged runtime.
- [DefaultRealmRuntimeFactory](runtime/realm/src/main/kotlin/com/typewritermc/realm/DefaultRealmRuntimeFactory.kt) and [EngineDeploymentEntrypoint](runtime/engine/core/src/main/kotlin/com/typewritermc/engine/runtime/EngineDeploymentEntrypoint.kt) construct discovery packages and load Realm or execution bindings for their deployments.

These connections describe implemented startup wiring. Successful startup still depends on service readiness, host assignment, compatible artifacts, and runtime activation; verify those conditions in the target environment before claiming a working deployment.

Loader host assignment is distinct from a general Realm assignment API for third party services. That API is not implemented in `service-sdk`. Do not simulate it there; it requires a complete protocol, backend, authorization, SDK, and test slice.
