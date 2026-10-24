# Service development

`services/` is one Gradle multiproject build. `build-logic` and `imprint` are the only included builds because Gradle needs both while configuring normal projects.

Services compile and run on Java 21. Paper API compilation targets Minecraft 1.21.4, the minimum supported server version.
The development server uses Paper 26.3 build 200 with its own Java 25 launcher. Its newer runtime does not raise the
minimum Java or Paper API version for the plugin.

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

The task publishes into `artifacts/inbox/manual`. It atomically replaces matching generated JARs without removing
other inbox contents. Obsolete generated JARs must be removed manually.

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

Imprint assembles one canonical manifest for each artifact. KSP processors contribute static metadata and generated module providers. Realm discovery loads only Realm bindings. Execution discovery loads only execution bindings. Each deployment retains its own classloader and admitted discovery packages.

`DeploymentRuntimeOwners` resolves generated providers, capability owners, and registrars from one deployment scoped set of explicitly supplied runtime services. Realm and engines use the same construction policy. Owner instances are shared within that deployment and are never borrowed from a global registry. `RuntimeScope` owns activated effects, while `RuntimeCleanupOwner` disposes registered resources in reverse order and preserves cleanup failures.

Generated registrars contribute runtime setup only to their declared domains. Compiled artifact producers own source specific compilation, while the engine content gateway admits compiled artifacts into the engine resource graph. Element declarations provide authored data and editor semantics. They do not own execution setup or compiled content assembly.

The conformance extension proves declared type identities, generated prototypes, element descriptors, source part eligibility, generated registrars, and engine targeting.

## Runtime status

Loader host assignment, deployment selection, artifact staging, and runtime discovery are connected:

- [LoaderApplication](runtime/loader/core/src/main/kotlin/com/typewritermc/loader/LoaderApplication.kt) uses `BackendArtifactHostAssignmentSource` to register the host and watch backend execution assignments. Standalone development can instead select a local assignment with `TYPEWRITER_LOCAL_REALM_ID`.
- [ArtifactHost](runtime/loader/core/src/main/kotlin/com/typewritermc/loader/rollout/ArtifactHost.kt) connects assignments to rollout participants. The Realm host resolves accepted artifact candidates and coordinates staging, activation, health checks, and recovery through `CoordinatedRollout`.
- [HostRolloutParticipant](runtime/loader/core/src/main/kotlin/com/typewritermc/loader/rollout/HostRolloutParticipant.kt) materializes projected artifacts, validates their canonical manifests, and stages the manifest selected `HostedRuntimeEntrypoint` through `HostedRuntimeLoader`. Commit activates the staged runtime.
- [DefaultRealmRuntimeFactory](runtime/realm/src/main/kotlin/com/typewritermc/realm/DefaultRealmRuntimeFactory.kt) and [EngineDeploymentEntrypoint](runtime/engine/core/src/main/kotlin/com/typewritermc/engine/runtime/EngineDeploymentEntrypoint.kt) construct discovery packages and load Realm or execution bindings for their deployments.

These connections describe implemented startup wiring. Successful startup still depends on service readiness, host assignment, compatible artifacts, and runtime activation; verify those conditions in the target environment before claiming a working deployment.

Loader host assignment is distinct from a general Realm assignment API for third party services. That API is not implemented in `service-sdk`. Do not simulate it there; it requires a complete protocol, backend, authorization, SDK, and test slice.
